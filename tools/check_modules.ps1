# check_modules.ps1 -- check-only compile of every manifest module.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# R2 CI gate: `xiom --check` on a generated `use xiom.X;` probe per module in
# tools/modlist_all.txt. A bare module file cannot be checked directly: with
# no `fn main` the compiler wraps it in implicit main (script mode), which
# rejects top-level extern blocks and contract clauses. The probe form is the
# same shape the bare-name scan uses and type-checks the module under its own
# imports (strict catalog findings included).
#
# Exit code is 1 when any module fails, 0 otherwise (CI gate).
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
  $results = Join-Path $OutDir ("results.w{0}.csv" -f $WorkerId)
  $errors = Join-Path $OutDir ("errors.w{0}.log" -f $WorkerId)
  $dir = Join-Path $OutDir ("w{0}" -f $WorkerId)
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  $env:XIOM_STDLIB = $repoRoot
  Set-Location -LiteralPath $repoRoot
  foreach ($mod in $mods) {
    $safe = $mod -replace '\.', '_'
    $probe = Join-Path $dir ("{0}.xi" -f $safe)
    Set-Content -LiteralPath $probe -Value ("module p_check_{0}`nuse {1};`n`nfn main() -> Int {{ return 0; }}`n" -f $safe, $mod) -Encoding ASCII
    $out = & $Compiler --check $probe 2>&1 | ForEach-Object { "$_" } | Out-String
    $rc = $LASTEXITCODE
    $ok = 0
    if ($rc -eq 0 -and ($out -notmatch "error\[")) { $ok = 1 }
    Add-Content -LiteralPath $results -Value ("{0},{1},{2}" -f $mod, $rc, $ok)
    if ($ok -eq 0) {
      Add-Content -LiteralPath $errors -Value ("### " + $mod + " CHECK-FAIL rc=" + $rc)
      $out -split "`n" | Where-Object { $_ -match "error|failed|panic" } | Select-Object -First 3 |
        ForEach-Object { Add-Content -LiteralPath $errors -Value $_.Trim() }
    }
    if (-not $Quiet -or $ok -eq 0) { Write-Output ("[w{0}] {1} check={2}" -f $WorkerId, $mod, $rc) }
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
if ($OutDir -eq "") { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("xiom-checkmods-" + (Get-Date -Format "yyyyMMdd-HHmmss")) }
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
Get-ChildItem -LiteralPath $OutDir -Filter "results.w*.csv" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem -LiteralPath $OutDir -Filter "errors.w*.log" -ErrorAction SilentlyContinue | Remove-Item -Force

$mods = @(Get-Content -LiteralPath $ModulesFile | Where-Object { $_ -ne "" })
if ($mods.Count -eq 0) { Write-Output "ERROR: no modules listed"; exit 2 }

Write-Output ("check_modules: repo=" + $repoRoot)
Write-Output ("check_modules: compiler=" + $Compiler)
Write-Output ("check_modules: modules=" + $mods.Count + "  workers=" + $Workers)
Write-Output ("check_modules: outdir=" + $OutDir)

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

$rows = @()
Get-ChildItem -LiteralPath $OutDir -Filter "results.w*.csv" -ErrorAction SilentlyContinue |
  Sort-Object Name | ForEach-Object {
  foreach ($line in (Get-Content -LiteralPath $_.FullName)) {
    if ($line -eq "") { continue }
    $parts = $line -split ","
    if ($parts.Count -lt 3) { continue }
    $rows += [pscustomobject]@{ Module = $parts[0]; Rc = [int]$parts[1]; Ok = [int]$parts[2] }
  }
}
$failures = @($rows | Where-Object { $_.Ok -eq 0 } | Sort-Object Module)
# Fail closed: every module must produce exactly one result row.
if ($rows.Count -ne $mods.Count) {
  Write-Output ("ERROR: expected " + $mods.Count + " module rows, got " + $rows.Count + " (workers failed to start?)")
  Write-Output ("OUTDIR: " + $OutDir)
  exit 2
}
$sw.Stop()
Write-Output ""
if ($failures.Count -eq 0) {
  Write-Output ("CHECK-MODULES: " + $rows.Count + "/" + $mods.Count + " modules type-check clean (" + [math]::Round($sw.Elapsed.TotalSeconds, 1) + "s)")
  Write-Output ("OUTDIR: " + $OutDir)
  exit 0
}
Write-Output ("CHECK-MODULES: " + $failures.Count + " failure(s)")
foreach ($f in $failures) { Write-Output ("  FAIL " + $f.Module + " rc=" + $f.Rc) }
Write-Output ("OUTDIR: " + $OutDir)
exit 1
