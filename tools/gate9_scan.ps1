# gate9_scan.ps1 -- one-command gate-9 evidence scan.
#
# Gate 9 (zero open findings) is checked against the compiler archive under
# test. The scan runs:
#   * every repro in tools/known_failures (the bus-migrated findings), and
#   * the four gate-9 probes that live in tools/probes (three) and
#     tools/probes/evidence (one),
# so the report covers the historical 10-probe gate-9 set plus the full
# known-failures corpus.
#
# Expected negative: p_vec_shape_arg_mismatch_av must FAIL to compile with
# T001 at the call site (it asserts the type error). Any other compile/run
# failure is unexpected and makes the scan exit 1.
#
# Usage:
#   tools/gate9_scan.ps1 -Compiler <archive>\bin\xiom.exe
#   tools/gate9_scan.ps1 -Compiler ... -WorkDir <dir> -Json <dir>\gate9.json
#
# Exit codes: 0 = no unexpected failures; 1 = at least one unexpected
# failure; 2 = bad invocation.
#
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Compiler,
    [string]$WorkDir = "",
    [string]$Json = "",
    [int]$Workers = 4,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot "run_smokes.ps1"

if (-not (Test-Path -LiteralPath $Compiler)) {
    Write-Error "compiler not found: $Compiler"
    exit 2
}
$Compiler = (Resolve-Path -LiteralPath $Compiler).Path

if (-not (Test-Path -LiteralPath $runner)) {
    Write-Error "run_smokes.ps1 not found next to this script"
    exit 2
}

if (-not $WorkDir) {
    $WorkDir = Join-Path $env:TEMP ("gate9_" + [guid]::NewGuid().ToString("N").Substring(0, 8))
}
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
$WorkDir = (Resolve-Path -LiteralPath $WorkDir).Path

if (-not $Json) { $Json = Join-Path $WorkDir "gate9.json" }

# A compile failure is the intended outcome for this name when the log shows
# the expected diagnostic.
$ExpectedNegative = @{ "p_vec_shape_arg_mismatch_av" = "T001" }

# The 6 gate-9 names that also live in tools/known_failures.
$Gate9Known = @(
    "p_iter_enumerate_tuple",
    "p_map_set_mutating_combo",
    "p_nested_generic_ptr_read",
    "p_result_payload_index_concat",
    "p_sync_mutex_builtin_shadow",
    "p_trailing_match_after_push"
)
# The 4 gate-9 probes outside tools/known_failures.
$Gate9Extras = @(
    "tools\probes\p_alias_module_type_path.xi",
    "tools\probes\p_simd_vec4f_lanes.xi",
    "tools\probes\p_wave198_long_tail.xi",
    "tools\probes\evidence\p_inline_i32_misread.xi"
)

$results = New-Object System.Collections.Generic.List[object]

# Invoke-Native runs an executable, captures all output to a log, and returns
# its exit code without letting native stderr trip ErrorActionPreference.
function Invoke-Native([string]$Exe, [string[]]$Argv, [string]$Log) {
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Exe @Argv 2>&1 | Out-File -LiteralPath $Log -Encoding utf8
        return $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $prev
    }
}

function Add-Result([string]$Set, [string]$Name, [string]$Status, [int]$CompileRc, [int]$RunExit, [string]$Detail) {
    $results.Add([pscustomobject]@{
            set        = $Set
            name       = $Name
            status     = $Status
            compile_rc = $CompileRc
            run_exit   = $RunExit
            detail     = $Detail
        })
}

# ---- known_failures corpus through the shared runner ----------------------
$kfDir = Join-Path $repo "tools\known_failures"
$kfWork = Join-Path $WorkDir "known_failures"
$kfJson = Join-Path $WorkDir "known_failures.json"

& $runner -Compiler $Compiler -Corpus $kfDir -Workers $Workers -WorkDir $kfWork -Json $kfJson -RetryFailed -Quiet | Out-Null
$kf = Get-Content -LiteralPath $kfJson -Raw | ConvertFrom-Json
$failures = @{}
foreach ($f in $kf.failures) { $failures[$f.name] = $f }

$kfLogs = Join-Path $kfWork "logs"
foreach ($file in Get-ChildItem -LiteralPath $kfDir -Filter *.xi) {
    $name = $file.BaseName
    if ($failures.ContainsKey($name)) {
        $status = "fail"
        $detail = "compile_rc=$($failures[$name].compile_rc) run_exit=$($failures[$name].run_exit)"
        if ($ExpectedNegative.ContainsKey($name)) {
            $log = Join-Path $kfLogs "$name.compile.log"
            if ((Test-Path -LiteralPath $log) -and (Select-String -LiteralPath $log -Pattern $ExpectedNegative[$name] -Quiet)) {
                $status = "expected-negative"
                $detail = "intended $($ExpectedNegative[$name])"
            }
        }
        Add-Result "known_failures" $name $status ([int]$failures[$name].compile_rc) ([int]$failures[$name].run_exit) $detail
    }
    else {
        Add-Result "known_failures" $name "pass" 0 0 ""
    }
}

# ---- the four extra gate-9 probes ----------------------------------------
$binDir = Join-Path $WorkDir "bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null
$env:XIOM_STDLIB = $repo
foreach ($rel in $Gate9Extras) {
    $src = Join-Path $repo $rel
    $name = [IO.Path]::GetFileNameWithoutExtension($src)
    if (-not (Test-Path -LiteralPath $src)) {
        Add-Result "gate9_extra" $name "fail" -1 -1 "missing $rel"
        continue
    }
    $exe = Join-Path $binDir ($name + ".exe")
    $clog = Join-Path $WorkDir "$name.compile.log"
    $rlog = Join-Path $WorkDir "$name.run.log"
    $crc = Invoke-Native $Compiler @("--force", "-o", $exe, $src) $clog
    if ($crc -ne 0) {
        Add-Result "gate9_extra" $name "fail" $crc -1 "compile failed (see $clog)"
        continue
    }
    $rrc = Invoke-Native $exe @() $rlog
    if ($rrc -eq 0) {
        Add-Result "gate9_extra" $name "pass" 0 0 ""
    }
    else {
        Add-Result "gate9_extra" $name "fail" 0 $rrc "run failed (see $rlog)"
    }
}

# ---- gate-9 set view + verdict -------------------------------------------
$gate9Names = @($Gate9Known) + @($Gate9Extras | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
$gate9 = @($results | Where-Object { $gate9Names -contains $_.name })
$unexpected = @($results | Where-Object { $_.status -eq "fail" })
$gate9Pass = @($gate9 | Where-Object { $_.status -eq "pass" }).Count
$expectedNeg = @($results | Where-Object { $_.status -eq "expected-negative" }).Count

$report = [pscustomobject]@{
    generated            = (Get-Date).ToString("o")
    compiler             = $Compiler
    repo                 = $repo
    gate9_total          = $gate9.Count
    gate9_pass           = $gate9Pass
    expected_negative    = $expectedNeg
    unexpected_failures  = $unexpected.Count
    verdict              = if ($unexpected.Count -eq 0) { "OK" } else { "FAIL" }
    gate9                = $gate9
    results              = $results
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Json -Encoding utf8

if (-not $Quiet) {
    Write-Output "gate9_scan: compiler=$Compiler"
    Write-Output "gate9_scan: repo=$repo"
    Write-Output "gate9_scan: workdir=$WorkDir"
    Write-Output ""
    $results | Sort-Object set, name | Format-Table set, name, status, compile_rc, run_exit, detail -AutoSize | Out-String | Write-Output
}
Write-Output ("GATE9 SET: {0}/{1} green (plus {2} expected negative)" -f $gate9Pass, $gate9.Count, $expectedNeg)
Write-Output ("KNOWN-FAILURES: {0} pass, {1} expected negative, {2} unexpected" -f (@($results | Where-Object { $_.set -eq 'known_failures' -and $_.status -eq 'pass' }).Count), $expectedNeg, $unexpected.Count)
Write-Output ("VERDICT: {0}" -f $report.verdict)
Write-Output ("JSON: {0}" -f $Json)
if ($unexpected.Count -gt 0) { exit 1 }
exit 0

