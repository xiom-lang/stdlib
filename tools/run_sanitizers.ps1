# run_sanitizers.ps1 -- focused sanitizer corpus for roadmap A1.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Compiles and runs a focused set of memory-sensitive smokes/probes with the
# compiler's sanitizers. The default set is intentionally small so the nightly
# job stays affordable; broaden it as the suite stabilises.
#
# Usage (CI: Ubuntu; local Windows supports -CompileOnly because the MSVC ASan
# runtime may be absent):
#   pwsh tools/run_sanitizers.ps1 -Compiler .compiler-src/target/debug/xiom
#   pwsh tools/run_sanitizers.ps1 -Compiler out\xiom.exe -CompileOnly -Sanitizers address
[CmdletBinding()]
param(
  [string]$Compiler = "",
  [ValidateSet("address", "undefined", "leak")]
  [string[]]$Sanitizers = @("address", "undefined"),
  [string[]]$Files = @(
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
  ),
  [string]$WorkDir = "",
  [string]$Json = "",
  [switch]$CompileOnly
)

$ErrorActionPreference = "Continue"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($Compiler -eq "") {
  $Compiler = if ($env:XIOM_COMPILER) { $env:XIOM_COMPILER } else { "xiom" }
}
if ($WorkDir -eq "") { $WorkDir = Join-Path $repoRoot "out/sanitizers" }
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
$isWin = ($env:OS -eq "Windows_NT")
$env:XIOM_STDLIB = $repoRoot
$env:ASAN_OPTIONS = "detect_leaks=1:halt_on_error=1"
$env:UBSAN_OPTIONS = "halt_on_error=1:print_stacktrace=1"

$results = New-Object System.Collections.Generic.List[object]
$failed = 0
$compiled = 0

foreach ($san in $Sanitizers) {
  $dir = Join-Path $WorkDir $san
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  foreach ($rel in $Files) {
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
      $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = $compileRc; run = $null })
      continue
    }
    $compiled++

    if ($CompileOnly) {
      $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = 0; run = $null })
      continue
    }

    $runOut = & $exe 2>&1
    $runRc = $LASTEXITCODE
    if ($runRc -ne 0) {
      $failed++
      Write-Output ("RUN-FAIL {0} [{1}] rc={2}" -f $rel, $san, $runRc)
      ($runOut | Select-Object -Last 8) | ForEach-Object { Write-Output ("  " + $_) }
    }
    $results.Add([pscustomobject]@{ file = $rel; sanitizer = $san; compile = 0; run = $runRc })
  }
}

$summary = [pscustomobject]@{
  generated = (Get-Date).ToUniversalTime().ToString("o")
  compiler = $Compiler
  sanitizers = $Sanitizers
  compile_only = [bool]$CompileOnly
  files = $Files.Count
  compiled = $compiled
  failed = $failed
  results = $results
}
if ($Json -ne "") {
  $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Json -Encoding utf8
}

Write-Output ("sanitizers: {0}  files={1} compiled={2} failed={3}" -f ($Sanitizers -join ","), $Files.Count, $compiled, $failed)
if ($failed -ne 0) { exit 1 }
exit 0
