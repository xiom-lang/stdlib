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
#
# The poll calls K32GetProcessMemoryInfo directly (same instantaneous
# WorkingSet metric as before). Process.Refresh()/Get-Process cost ~30 ms per
# read in PowerShell, which left 1-3 samples on a 10k run and produced
# 0.0/partial peaks; the P/Invoke read is fast enough to sample continuously.
# `samples=` is printed so an under-sampled run is visible instead of silently
# low.
param(
    [Parameter(Mandatory = $true)][string]$Exe,
    [int]$Iters = 10000,
    [int]$MaxMB = 256,
    [int]$PollMs = 0,
    [int]$MinSamples = 50,
    [string[]]$Modes = @("")
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Exe)) { Write-Error "not found: $Exe"; exit 2 }
if ($MaxMB -lt 64) { Write-Error "MaxMB must be >= 64"; exit 2 }
$cap = [int64]$MaxMB * 1MB
$env:PROBE_ITERS = "$Iters"

if (-not ("XiomPeakSampler" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class XiomPeakSampler {
    [StructLayout(LayoutKind.Sequential)]
    public struct PMC {
        public uint cb;
        public uint PageFaultCount;
        public IntPtr PeakWorkingSetSize;
        public IntPtr WorkingSetSize;
        public IntPtr QuotaPeakPagedPoolUsage;
        public IntPtr QuotaPagedPoolUsage;
        public IntPtr QuotaPeakNonPagedPoolUsage;
        public IntPtr QuotaNonPagedPoolUsage;
        public IntPtr PagefileUsage;
        public IntPtr PeakPagefileUsage;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool K32GetProcessMemoryInfo(IntPtr hProcess, out PMC counters, uint cb);

    public static long Query(IntPtr h, bool peak) {
        PMC c;
        c.cb = (uint)Marshal.SizeOf(typeof(PMC));
        c.PageFaultCount = 0;
        c.PeakWorkingSetSize = IntPtr.Zero;
        c.WorkingSetSize = IntPtr.Zero;
        c.QuotaPeakPagedPoolUsage = IntPtr.Zero;
        c.QuotaPagedPoolUsage = IntPtr.Zero;
        c.QuotaPeakNonPagedPoolUsage = IntPtr.Zero;
        c.QuotaNonPagedPoolUsage = IntPtr.Zero;
        c.PagefileUsage = IntPtr.Zero;
        c.PeakPagefileUsage = IntPtr.Zero;
        if (!K32GetProcessMemoryInfo(h, out c, c.cb)) { return 0; }
        return (long)(peak ? c.PeakWorkingSetSize : c.WorkingSetSize);
    }
}
'@
}

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
    $samples = 0
    $killed = $false
    while (-not $p.HasExited) {
        try {
            $ws = [XiomPeakSampler]::Query($p.Handle, $false)
            if ($ws -gt 0) {
                $samples = $samples + 1
                if ($ws -gt $peak) { $peak = $ws }
                if ($ws -gt $cap) {
                    & taskkill /T /F /PID $p.Id 2>$null | Out-Null
                    $killed = $true
                    break
                }
            }
        } catch {
            # The handle can close between HasExited and the query; keep going.
            if ($p.HasExited) { break }
        }
        if ($PollMs -gt 0) { Start-Sleep -Milliseconds $PollMs }
    }
    if (-not $killed) { $p.WaitForExit() }
    $sw.Stop()
    $rc = if ($killed) { 137 } elseif ($null -ne $p.ExitCode) { $p.ExitCode } else { 0 }
    $label = if ($mode -eq "") { "default" } else { $mode }
    Write-Output ("mode={0} iters={1} peak_mb={2:N1} rc={3} ms={4} samples={5}" -f $label, $Iters, ($peak / 1MB), $rc, $sw.ElapsedMilliseconds, $samples)
    if ($samples -lt $MinSamples) {
        Write-Warning ("under-sampled: {0} samples (< {1}); raise -Iters for a stable peak" -f $samples, $MinSamples)
    }
}
