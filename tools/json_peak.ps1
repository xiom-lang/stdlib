# json_peak.ps1 -- peak-RSS witness for the 1704 JSON drop-glue gate.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Manual gate-9 evidence, NOT part of the normal smoke/probe corpus. Build the
# probe first, then measure the trend:
#   xiom tools/probes/p_json_1704_obj.xi -o out/p_json_1704_obj.exe
#   ./tools/json_peak.ps1 -Exe out/p_json_1704_obj.exe -Iters 10000
#   ./tools/json_peak.ps1 -Exe out/p_json_1704_obj.exe -Iters 20000
# A peak that grows linearly with -Iters means the JSON aggregate path still
# retains memory (the 1704/m375 class); a plateau means only a high-water mark
# is kept. The hard cap kills the process at 256 MB by default so a regression
# cannot exhaust the workstation.
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [int]$Iters = 10000,
    [int]$MaxMB = 256,
    [int]$PollMs = 10,
    [string[]]$Modes = @("")
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Exe)) { Write-Error "not found: $Exe"; exit 2 }
if ($MaxMB -lt 64) { Write-Error "MaxMB must be >= 64"; exit 2 }
$cap = [int64]$MaxMB * 1MB
$env:PROBE_ITERS = "$Iters"

foreach ($mode in $Modes) {
    $appArgs = @()
    if ($mode -ne "") { $appArgs += $mode }
    if ($appArgs.Count -gt 0) {
        $p = Start-Process -FilePath $Exe -ArgumentList $appArgs -PassThru -NoNewWindow
    } else {
        $p = Start-Process -FilePath $Exe -PassThru -NoNewWindow
    }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $peak = 0
    $killed = $false
    while (-not $p.HasExited) {
        try {
            $p.Refresh()
            $ws = $p.WorkingSet64
            if ($ws -gt $peak) { $peak = $ws }
            if ($ws -gt $cap) {
                & taskkill /T /F /PID $p.Id 2>$null | Out-Null
                $killed = $true
                break
            }
        } catch {
            break
        }
        Start-Sleep -Milliseconds $PollMs
    }
    if (-not $killed) { $p.WaitForExit() }
    $sw.Stop()
    $rc = if ($killed) { 137 } elseif ($null -ne $p.ExitCode) { $p.ExitCode } else { 0 }
    $label = if ($mode -eq "") { "default" } else { $mode }
    Write-Output ("mode={0} iters={1} peak_mb={2:N1} rc={3} ms={4}" -f $label, $Iters, ($peak / 1MB), $rc, $sw.ElapsedMilliseconds)
}
