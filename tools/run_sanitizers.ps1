# run_sanitizers.ps1 -- focused sanitizer corpus for roadmap A1.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Two modes:
#   default      memory errors only (ASan/UBSan with detect_leaks=0); fails on
#                any nonzero run.
#   -Leaks       ASan leak audit (detect_leaks=1) against
#                tools/sanitizer_leak_baseline.json. A file passes when its
#                leak stays within budget*1.1 + 64 bytes; growth fails. The
#                baseline is a known-leak budget (compiler drop residual), not
#                a suppression; shrink it as the compiler improves.
#
# The default file set is intentionally small so the nightly job stays
# affordable; broaden it as the suite stabilises.
#
# Usage (CI: Ubuntu; local Windows supports -CompileOnly because the MSVC ASan
# runtime may be absent):
#   pwsh tools/run_sanitizers.ps1 -Compiler .compiler-src/target/debug/xiom
#   pwsh tools/run_sanitizers.ps1 -Compiler .compiler-src/target/debug/xiom -Leaks
#   pwsh tools/run_sanitizers.ps1 -Compiler out\xiom.exe -CompileOnly -Sanitizers address
[CmdletBinding()]
param(
  [string]$Compiler = "",
  [ValidateSet("address", "undefined", "leak")]
  [string[]]$Sanitizers = @("address", "undefined"),
  [string[]]$Files = @(),
  [string[]]$MemoryFiles = @(),
  [string[]]$LeakFiles = @(),
  [string]$WorkDir = "",
  [string]$Json = "",
  [string]$LeakBaseline = "",
  [switch]$Leaks,
  [switch]$CompileOnly
)

# Default sets. The memory lane includes the A3 fuzz targets; the leak lane
# keeps the original baselined files until a nightly ASan run records a leak
# budget for the fuzz targets (do not give them a silent 0-byte budget).
$defaultFiles = @(
  "tests/smoke/smoke_alloc.xi",
  "tests/smoke/smoke_alloc_edge.xi",
  "tests/smoke/smoke_collections_map_edge.xi",
  "tests/smoke/smoke_collections_vec_insert_remove.xi",
  "tests/smoke/smoke_stress_fuzz_parsers.xi",
  "tests/smoke/smoke_stress_serialize_json_nested.xi",
  "tests/smoke/smoke_stress_serialize_json_parse_nested.xi",
  "tests/smoke/smoke_string_builder.xi",
  "tests/smoke/smoke_string_unicode.xi",
  "tools/probes/p_json_1704_obj.xi",
  "tools/probes/p_json_ref_api.xi",
  "tools/probes/p_json_parse_depth_cap.xi"
)
$fuzzFiles = @(
  "tests/smoke/smoke_fuzz_bignum.xi",
  "tests/smoke/smoke_fuzz_ffi.xi",
  "tests/smoke/smoke_fuzz_encodings.xi"
)
if ($Files.Count -eq 0) { $Files = $defaultFiles }
if ($MemoryFiles.Count -eq 0) { $MemoryFiles = @($Files) + $fuzzFiles }
if ($LeakFiles.Count -eq 0) { $LeakFiles = $Files }

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($Compiler -eq "") {
  $Compiler = if ($env:XIOM_COMPILER) { $env:XIOM_COMPILER } else { "xiom" }
}
if ($WorkDir -eq "") { $WorkDir = Join-Path $repoRoot "out/sanitizers" }
if ($LeakBaseline -eq "") { $LeakBaseline = Join-Path $repoRoot "tools/sanitizer_leak_baseline.json" }
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
$isWin = ($env:OS -eq "Windows_NT")
$env:XIOM_STDLIB = $repoRoot
$env:UBSAN_OPTIONS = "halt_on_error=1:print_stacktrace=1"

$baseline = @{}
if ($Leaks) {
  if (-not (Test-Path -LiteralPath $LeakBaseline)) {
    Write-Output "missing leak baseline: $LeakBaseline"
    exit 2
  }
  $obj = Get-Content -LiteralPath $LeakBaseline -Raw | ConvertFrom-Json
  foreach ($prop in $obj.PSObject.Properties) {
    if (-not $prop.Name.StartsWith("_")) { $baseline[$prop.Name] = [int64]$prop.Value }
  }
}

$results = New-Object System.Collections.Generic.List[object]
$failed = 0
$compiled = 0

foreach ($san in $Sanitizers) {
  $dir = Join-Path $WorkDir $san
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $activeFiles = $Files
  if ($Leaks) { $activeFiles = $LeakFiles }
  elseif ($MemoryFiles.Count -gt 0) { $activeFiles = $MemoryFiles }
  foreach ($rel in $activeFiles) {
    $src = Join-Path $repoRoot $rel
    $name = [System.IO.Path]::GetFileNameWithoutExtension($rel)
    $exe = Join-Path $dir $name
    if ($isWin) { $exe = "$exe.exe" }

    $compileOut = & $Compiler --force "--sanitize=$san" $src -o $exe 2>&1
    $compileRc = $LASTEXITCODE
    if ($compileRc -ne 0) {
      $failed++
      Write-Output ("COMPILE-FAIL {0} [{1}] rc={2}" -f $rel, $san, $compileRc)
      ($compileOut | Select-Object -Last 5) | ForEach-Object { Write-Output ("  " + $_) }
      $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = $compileRc; run = $null; leak = $null })
      continue
    }
    $compiled++

    if ($CompileOnly) {
      $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = 0; run = $null; leak = $null })
      continue
    }

    $leakMode = ($Leaks -and $san -eq "address")
    if ($leakMode) {
      $env:ASAN_OPTIONS = "detect_leaks=1:halt_on_error=1"
    } else {
      $env:ASAN_OPTIONS = "detect_leaks=0:halt_on_error=1"
    }

    $runOut = & $exe 2>&1
    $runRc = $LASTEXITCODE
    $leak = $null

    if ($leakMode) {
      $txt = ($runOut | Out-String)
      if ($txt -match 'SUMMARY: AddressSanitizer: (\d+) byte\(s\) leaked') {
        $leak = [int64]$Matches[1]
      } else {
        $leak = 0
      }
      $budget = 0
      if ($baseline.ContainsKey($rel)) { $budget = [int64]$baseline[$rel] }
      $limit = [int64][math]::Ceiling($budget * 1.1) + 64
      if ($leak -gt $limit) {
        $failed++
        Write-Output ("LEAK-GROWTH {0} [{1}] leak={2} budget={3} limit={4}" -f $rel, $san, $leak, $budget, $limit)
        ($runOut | Select-Object -Last 8) | ForEach-Object { Write-Output ("  " + $_) }
      } elseif ($runRc -ne 0 -and $leak -eq 0) {
        $failed++
        Write-Output ("RUN-FAIL {0} [{1}] rc={2}" -f $rel, $san, $runRc)
        ($runOut | Select-Object -Last 8) | ForEach-Object { Write-Output ("  " + $_) }
      }
    } elseif ($runRc -ne 0) {
      $failed++
      Write-Output ("RUN-FAIL {0} [{1}] rc={2}" -f $rel, $san, $runRc)
      ($runOut | Select-Object -Last 8) | ForEach-Object { Write-Output ("  " + $_) }
    }

    $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = 0; run = $runRc; leak = $leak })
  }
}

$summaryFiles = $MemoryFiles
if ($Leaks) { $summaryFiles = $LeakFiles }
$summary = [pscustomobject]@{
  generated = (Get-Date).ToUniversalTime().ToString("o")
  compiler = $Compiler
  sanitizers = $Sanitizers
  compile_only = [bool]$CompileOnly
  leak_audit = [bool]$Leaks
  files = $summaryFiles.Count
  compiled = $compiled
  failed = $failed
  results = $results
}
if ($Json -ne "") {
  $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Json -Encoding utf8
}

Write-Output ("sanitizers: {0}  files={1} compiled={2} failed={3} leak_audit={4}" -f ($Sanitizers -join ","), $summaryFiles.Count, $compiled, $failed, [bool]$Leaks)
if ($failed -ne 0) { exit 1 }
exit 0
