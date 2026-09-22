# run_smokes.ps1 -- XIOM stdlib smoke-corpus runner (Windows / PowerShell).
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Contract (docs/REPO_MIGRATION_RUNBOOK.md section 6.1):
#   -Compiler <path>   compiler binary (default: $env:XIOM_COMPILER, then `xiom` on PATH)
#   -Filter <text>     run only files whose name contains <text>
#   -Workers <n>       parallel workers (default 8)
#   -Json <path>       write a machine-readable result summary
# The child compiler always runs with XIOM_STDLIB=<repo root> so the corpus
# tests THIS checkout, never an installed copy. Exit code is nonzero when any
# file fails to compile or exits nonzero; every file's codes are printed.
#
# Extra (local triage): -Corpus <dir> (default tests/smoke), -WorkDir <dir>,
# -RetryFailed (solo re-run of failures before reporting), -Quiet.
#
# Single file on purpose: launcher and worker modes live here. The launcher
# starts N child processes of this same script with -WorkerRun.

[CmdletBinding()]
param(
  [string]$Compiler = "",
  [string]$Filter = "",
  [int]$Workers = 8,
  [string]$Json = "",
  [string]$Corpus = "",
  [string]$WorkDir = "",
  [switch]$RetryFailed,
  [switch]$Quiet,
  [switch]$KeepPassing,
  [switch]$WorkerRun,
  [string]$SliceFile = "",
  [int]$WorkerId = 0
)

$ErrorActionPreference = "Continue"
$scriptPath = $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $PSScriptRoot
$isWindowsHost = ($env:OS -eq "Windows_NT")
$nulDevice = if ($isWindowsHost) { "NUL" } else { "/dev/null" }
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

function Write-ResultsLine([string]$csv, [string]$name, [int]$compileRc, [int]$compileOk, [int]$runRc, [double]$secs) {
  $line = "{0},{1},{2},{3},{4}" -f $name, $compileRc, $compileOk, $runRc, [math]::Round($secs, 1)
  Add-Content -LiteralPath $csv -Value $line
}

function Invoke-Worker {
  $files = Get-Content -LiteralPath $SliceFile | Where-Object { $_ -ne "" }
  $results = Join-Path $WorkDir ("results.w{0}.csv" -f $WorkerId)
  $errors = Join-Path $WorkDir ("errors.w{0}.log" -f $WorkerId)
  $logs = Join-Path $WorkDir "logs"
  New-Item -ItemType Directory -Path $logs -Force | Out-Null
  $env:XIOM_STDLIB = $repoRoot
  Set-Location -LiteralPath $repoRoot
  # FIX 2026-09-19: Windows PowerShell 5.1 rejects -RedirectStandardInput 'NUL'
  # (it resolves the device name relative to the CWD -> FileNotFoundException);
  # Start-Process then returns $null, $p.ExitCode is $null and [int]$null is 0,
  # so EVERY smoke was recorded run=0 PASS. Use a real empty file, and treat a
  # null process as a loud failure instead of a green.
  $emptyIn = Join-Path $WorkDir "empty.stdin"
  if (-not (Test-Path -LiteralPath $emptyIn)) { New-Item -ItemType File -Path $emptyIn -Force | Out-Null }
  foreach ($file in $files) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($file)
    $bin = Join-Path $WorkDir ("bin/" + $name + $binSuffix)
    $start = Get-Date
    $compileOut = & $Compiler --force -o $bin $file 2>&1 | ForEach-Object { "$_" } | Out-String
    $compileRc = $LASTEXITCODE
    $compileOk = 0
    if ($compileRc -eq 0 -and (Test-Path -LiteralPath $bin)) { $compileOk = 1 }
    Set-Content -LiteralPath (Join-Path $logs ($name + ".compile.log")) -Value $compileOut
    if ($compileOk -eq 0) {
      Add-Content -LiteralPath $errors -Value ("### " + $name + " COMPILE-FAIL rc=" + $compileRc)
      $compileOut -split "`n" | Where-Object { $_ -match "error|failed|panic" } | Select-Object -First 3 |
        ForEach-Object { Add-Content -LiteralPath $errors -Value $_.Trim() }
    }
    $runRc = -999
    if ($compileOk -eq 1) {
      $runOut = Join-Path $logs ($name + ".run.out")
      $runErr = Join-Path $logs ($name + ".run.err")
      # .NET process capture instead of Start-Process -PassThru: on Linux,
      # Start-Process returns $null for very short-lived programs (bisect_mask
      # exited in ~1ms and was recorded as -997 even though direct execution
      # returns 0). StandardInput closes immediately = empty stdin (EOF).
      try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $bin
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.Close()
        $outTask = $proc.StandardOutput.ReadToEndAsync()
        $errTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        Set-Content -LiteralPath $runOut -Value $outTask.Result
        Set-Content -LiteralPath $runErr -Value $errTask.Result
        $runRc = $proc.ExitCode
      } catch {
        Set-Content -LiteralPath $runErr -Value ("run_smokes: process start failed: " + $_.Exception.Message)
        $runRc = -997
      }
    }
    $dur = ((Get-Date) - $start).TotalSeconds
    Write-ResultsLine -csv $results -name $name -compileRc $compileRc -compileOk $compileOk -runRc $runRc -secs $dur
    if (-not $Quiet -or $compileOk -eq 0 -or $runRc -ne 0) {
      Write-Output ("[w{0}] {1} compile={2} run={3} ({4}s)" -f $WorkerId, $name, $compileRc, $runRc, [math]::Round($dur, 1))
    }
    if (-not $KeepPassing) { Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue }
  }
}

function Read-Results {
  # Later files (retry w99) override earlier rows for the same smoke.
  $map = [ordered]@{}
  Get-ChildItem -LiteralPath $WorkDir -Filter "results.w*.csv" -ErrorAction SilentlyContinue |
    Sort-Object Name | ForEach-Object {
    foreach ($line in (Get-Content -LiteralPath $_.FullName)) {
      if ($line -eq "") { continue }
      $parts = $line -split ","
      if ($parts.Count -lt 5) { continue }
      $map[$parts[0]] = [pscustomobject]@{
        Name = $parts[0]; CompileRc = [int]$parts[1]; CompileOk = [int]$parts[2]
        RunRc = [int]$parts[3]; Secs = [double]$parts[4]
      }
    }
  }
  return @($map.Values)
}

function Start-WorkerProcess([int]$id, [string]$slicePath, [switch]$silent) {
  $childLog = Join-Path $WorkDir ("worker{0}.out.log" -f $id)
  $childErr = Join-Path $WorkDir ("worker{0}.err.log" -f $id)
  $hostExe = (Get-Process -Id $PID).Path
  # Windows PowerShell needs -ExecutionPolicy; PowerShell 7 on Linux/macOS
  # rejects that flag, and -WindowStyle is likewise Windows-only. Passing
  # them unconditionally made every worker exit immediately on Linux, which
  # the fail-closed result-count check below now refuses to report as green.
  $argList = @("-NoProfile")
  if ($null -eq $IsWindows -or $IsWindows) { $argList += @("-ExecutionPolicy", "Bypass") }
  $argList += @(
    "-File", ('"{0}"' -f $scriptPath),
    "-WorkerRun", "-WorkerId", "$id",
    "-Compiler", ('"{0}"' -f $Compiler),
    "-WorkDir", ('"{0}"' -f $WorkDir),
    "-SliceFile", ('"{0}"' -f $slicePath)
  )
  if ($silent) { $argList += "-Quiet" }
  if ($KeepPassing) { $argList += "-KeepPassing" }
  $sp = @{
    FilePath = $hostExe
    ArgumentList = $argList
    PassThru = $true
    RedirectStandardOutput = $childLog
    RedirectStandardError = $childErr
  }
  if ($null -eq $IsWindows -or $IsWindows) { $sp["WindowStyle"] = "Hidden" }
  return Start-Process @sp
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
try { $Compiler = Resolve-CompilerPath $Compiler }
catch { Write-Output ("ERROR: " + $_.Exception.Message); exit 2 }

if ($WorkerRun) {
  Invoke-Worker
  exit 0
}

if ($Corpus -eq "") { $Corpus = Join-Path $repoRoot "tests/smoke" }
if (-not (Test-Path -LiteralPath $Corpus)) { Write-Output ("ERROR: corpus not found: " + $Corpus); exit 2 }
if ($WorkDir -eq "") {
  $WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ("xiom-smokes-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
}
New-Item -ItemType Directory -Path (Join-Path $WorkDir "bin") -Force | Out-Null
Get-ChildItem -LiteralPath $WorkDir -Filter "results.w*.csv" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $WorkDir -Filter "errors.w*.log" -ErrorAction SilentlyContinue | Remove-Item -Force

$files = Get-ChildItem -LiteralPath $Corpus -Filter *.xi | Sort-Object Name
if ($Filter -ne "") { $files = $files | Where-Object { $_.Name -like ("*" + $Filter + "*") } }
if ($files.Count -eq 0) { Write-Output "ERROR: no corpus files matched"; exit 2 }

Write-Output ("run_smokes: repo=" + $repoRoot)
Write-Output ("run_smokes: compiler=" + $Compiler)
Write-Output ("run_smokes: corpus=" + $Corpus + "  files=" + $files.Count + "  workers=" + $Workers)
Write-Output ("run_smokes: workdir=" + $WorkDir)

$chunk = [math]::Ceiling($files.Count / [double]$Workers)
$procs = @()
for ($w = 0; $w -lt $Workers; $w++) {
  $slice = $files | Select-Object -Skip ($w * $chunk) -First $chunk
  if (-not $slice) { continue }
  $slicePath = Join-Path $WorkDir ("slice.w{0}.txt" -f $w)
  $slice | ForEach-Object { $_.FullName } | Set-Content -LiteralPath $slicePath
  $procs += Start-WorkerProcess -id $w -slicePath $slicePath
}
Write-Output ("run_smokes: launched " + $procs.Count + " workers")
$procs | ForEach-Object { $_.WaitForExit() }

$rows = @(Read-Results)
if ($RetryFailed) {
  $failed = @($rows | Where-Object { $_.CompileOk -eq 0 -or $_.RunRc -ne 0 })
  if ($failed.Count -gt 0) {
    Write-Output ("run_smokes: retrying " + $failed.Count + " failed file(s) solo")
    $retrySlice = Join-Path $WorkDir "slice.retry.txt"
    $failed | ForEach-Object { Join-Path $Corpus ($_.Name + ".xi") } | Set-Content -LiteralPath $retrySlice
    $p = Start-WorkerProcess -id 99 -slicePath $retrySlice -silent
    $p.WaitForExit()
    $rows = @(Read-Results)
  }
}

$total = @($rows).Count
# Fail closed: every corpus file must produce exactly one result row. A
# worker-startup failure used to yield total=0 with exit code 0, which made
# a silently no-op gate look green (observed on ubuntu-latest release gates
# on 2026-09-22).
if ($total -ne @($files).Count) {
  Write-Output ("ERROR: expected " + @($files).Count + " result rows, got " + $total + " (workers failed to start?)")
  exit 2
}
$pass = @($rows | Where-Object { $_.CompileOk -eq 1 -and $_.RunRc -eq 0 }).Count
$compileFail = @($rows | Where-Object { $_.CompileOk -eq 0 }).Count
$runFail = @($rows | Where-Object { $_.CompileOk -eq 1 -and $_.RunRc -ne 0 }).Count
$failures = @($rows | Where-Object { $_.CompileOk -eq 0 -or $_.RunRc -ne 0 } | Sort-Object Name)

Write-Output ""
Write-Output "PER-FILE RESULTS:"
foreach ($r in ($rows | Sort-Object Name)) {
  $status = "PASS"
  if ($r.CompileOk -eq 0 -or $r.RunRc -ne 0) { $status = "FAIL" }
  if (-not $Quiet -or $status -eq "FAIL") {
    Write-Output ("  {0} {1} compile={2} run={3}" -f $status, $r.Name, $r.CompileRc, $r.RunRc)
  }
}
$sw.Stop()
Write-Output ""
Write-Output ("SUMMARY: total={0} pass={1} compilefail={2} runfail={3} seconds={4}" -f `
  $total, $pass, $compileFail, $runFail, [math]::Round($sw.Elapsed.TotalSeconds, 1))
Write-Output ("WORKDIR: " + $WorkDir)

if ($Json -ne "") {
  $summary = [pscustomobject]@{
    generated = (Get-Date -Format o)
    compiler = $Compiler
    corpus = $Corpus
    workers = $Workers
    total = $total
    pass = $pass
    compilefail = $compileFail
    runfail = $runFail
    seconds = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    failures = @($failures | ForEach-Object {
      [pscustomobject]@{ name = $_.Name; compile_rc = $_.CompileRc; run_exit = $_.RunRc }
    })
  }
  $summary | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $Json
  Write-Output ("JSON: " + $Json)
}

if ($failures.Count -gt 0) { exit 1 }
exit 0
