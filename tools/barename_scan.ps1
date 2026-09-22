# barename_scan.ps1 -- per-module bare-name / catalog-body finding scanner.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# The strict-flip detector: compiles a trivial `use xiom.X;` probe for every
# module in tools/modlist_all.txt and harvests every 'catalog body' finding
# (plus any probe that fails to compile at all). Zero hits is the expected
# state before a compiler round is declared clean.
# Blind spot (known): a trivial probe never checks a module's ON-DEMAND
# bodies, so the full strict smoke run remains the detector of record for
# that class (tools/run_smokes.ps1).
#
# Exit code is 1 when any hit is found, 0 otherwise (CI gate).
param(
  [string]$Compiler = "",
  [string]$ModulesFile = "",
  [int]$Workers = 8,
  [string]$OutDir = "",
  [switch]$Quiet,
  [switch]$WorkerRun,
  [string]$SliceFile = "",
  [int]$WorkerId = 0
)

$ErrorActionPreference = "Continue"
$scriptPath = $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $PSScriptRoot
$isWindowsHost = ($env:OS -eq "Windows_NT")
$binSuffix = if ($isWindowsHost) { ".exe" } else { "" }

function Resolve-CompilerPath([string]$value) {
  if ($value -ne "") {
    if (Test-Path -LiteralPath $value) { return (Resolve-Path -LiteralPath $value).Path }
    $cmd = Get-Command $value -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "compiler not found: $value"
  }
  if ($env:XIOM_COMPILER -and (Test-Path -LiteralPath $env:XIOM_COMPILER)) {
    return (Resolve-Path -LiteralPath $env:XIOM_COMPILER).Path
  }
  $cmd = Get-Command xiom -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  throw "no compiler given: pass -Compiler, set XIOM_COMPILER, or put xiom on PATH"
}

function Invoke-Worker {
  $mods = Get-Content -LiteralPath $SliceFile | Where-Object { $_ -ne "" }
  $hits = Join-Path $OutDir ("hits.w{0}.txt" -f $WorkerId)
  $dir = Join-Path $OutDir ("w{0}" -f $WorkerId)
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $env:XIOM_STDLIB = $repoRoot
  Set-Location -LiteralPath $repoRoot
  foreach ($mod in $mods) {
    $safe = $mod -replace '\.', '_'
    $probe = Join-Path $dir ("{0}.xi" -f $safe)
    $bin = Join-Path $dir ("{0}{1}" -f $safe, $binSuffix)
    Set-Content -LiteralPath $probe -Value ("module p_bare_{0}`nuse {1};`n`nfn main() -> Int {{ return 0; }}`n" -f $safe, $mod) -Encoding ASCII
    $out = & $Compiler --force -o $bin $probe 2>&1 | ForEach-Object { "$_" } | Out-String
    $rc = $LASTEXITCODE
    # Progress marker for the parent's fail-closed count (clean modules emit
    # no hits, so hits alone cannot prove the worker ran).
    Add-Content -LiteralPath (Join-Path $OutDir ("done.w{0}.txt" -f $WorkerId)) -Value $mod
    if ($rc -ne 0 -and ($out -notmatch "catalog body")) {
      Add-Content -LiteralPath $hits -Value ("{0}`tCOMPILE-FAIL rc={1}" -f $mod, $rc)
    }
    foreach ($line in ($out -split "`n")) {
      if ($line -match "catalog body") {
        Add-Content -LiteralPath $hits -Value ("{0}`t{1}" -f $mod, $line.Trim())
      }
    }
    Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue
    if (-not $Quiet) { Write-Output ("[w{0}] {1} rc={2}" -f $WorkerId, $mod, $rc) }
  }
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
try { $Compiler = Resolve-CompilerPath $Compiler }
catch { Write-Output ("ERROR: " + $_.Exception.Message); exit 2 }

if ($WorkerRun) {
  Invoke-Worker
  exit 0
}

if ($ModulesFile -eq "") { $ModulesFile = Join-Path $PSScriptRoot "modlist_all.txt" }
if (-not (Test-Path -LiteralPath $ModulesFile)) { Write-Output ("ERROR: modules file not found: " + $ModulesFile); exit 2 }
if ($OutDir -eq "") { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("xiom-barescan-" + (Get-Date -Format "yyyyMMdd-HHmmss")) }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
Get-ChildItem -LiteralPath $OutDir -Filter "hits.w*.txt" -ErrorAction SilentlyContinue | Remove-Item -Force

$mods = @(Get-Content -LiteralPath $ModulesFile | Where-Object { $_ -ne "" })
if ($mods.Count -eq 0) { Write-Output "ERROR: no modules listed"; exit 2 }

Write-Output ("barename_scan: repo=" + $repoRoot)
Write-Output ("barename_scan: compiler=" + $Compiler)
Write-Output ("barename_scan: modules=" + $mods.Count + "  workers=" + $Workers)
Write-Output ("barename_scan: outdir=" + $OutDir)

$chunk = [math]::Ceiling($mods.Count / [double]$Workers)
$procs = @()
for ($w = 0; $w -lt $Workers; $w++) {
  $slice = $mods | Select-Object -Skip ($w * $chunk) -First $chunk
  if (-not $slice) { continue }
  $slicePath = Join-Path $OutDir ("slice.w{0}.txt" -f $w)
  $slice | Set-Content -LiteralPath $slicePath
  $hostExe = (Get-Process -Id $PID).Path
  # pwsh on Linux rejects -ExecutionPolicy/-WindowStyle; passing them made
  # every worker exit instantly and the gate reported a silent pass.
  $argList = @("-NoProfile")
  if ($null -eq $IsWindows -or $IsWindows) { $argList += @("-ExecutionPolicy", "Bypass") }
  $argList += @(
    "-File", ('"{0}"' -f $scriptPath),
    "-WorkerRun", "-WorkerId", "$w", "-Quiet",
    "-Compiler", ('"{0}"' -f $Compiler),
    "-OutDir", ('"{0}"' -f $OutDir),
    "-SliceFile", ('"{0}"' -f $slicePath)
  )
  $sp = @{
    FilePath = $hostExe
    ArgumentList = $argList
    PassThru = $true
    RedirectStandardOutput = (Join-Path $OutDir ("worker{0}.out.log" -f $w))
    RedirectStandardError = (Join-Path $OutDir ("worker{0}.err.log" -f $w))
  }
  if ($null -eq $IsWindows -or $IsWindows) { $sp["WindowStyle"] = "Hidden" }
  $procs += Start-Process @sp
}
$procs | ForEach-Object { $_.WaitForExit() }

$hitLines = @()
Get-ChildItem -LiteralPath $OutDir -Filter "hits.w*.txt" -ErrorAction SilentlyContinue | ForEach-Object {
  foreach ($line in (Get-Content -LiteralPath $_.FullName)) {
    if ($line -ne "") { $hitLines += $line }
  }
}
$sw.Stop()
# Fail closed: every module in the manifest must have been scanned.
$doneCount = 0
Get-ChildItem -LiteralPath $OutDir -Filter "done.w*.txt" -ErrorAction SilentlyContinue | ForEach-Object {
  $doneCount += @(Get-Content -LiteralPath $_.FullName | Where-Object { $_ -ne "" }).Count
}
if ($doneCount -ne $mods.Count) {
  Write-Output ("ERROR: expected " + $mods.Count + " scanned modules, got " + $doneCount + " (workers failed to start?)")
  Write-Output ("OUTDIR: " + $OutDir)
  exit 2
}
Write-Output ""
if ($hitLines.Count -eq 0) {
  Write-Output ("BARENAME SCAN: 0 hits in " + $mods.Count + " modules (" + [math]::Round($sw.Elapsed.TotalSeconds, 1) + "s)")
  Write-Output ("OUTDIR: " + $OutDir)
  exit 0
}
Write-Output ("BARENAME SCAN: " + $hitLines.Count + " hit(s)")
foreach ($h in $hitLines) { Write-Output ("  " + $h) }
Write-Output ("OUTDIR: " + $OutDir)
exit 1
