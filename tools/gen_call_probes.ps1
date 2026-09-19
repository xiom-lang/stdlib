# gen_call_probes.ps1 -- generated call probes for never-referenced scalar-arg pub fns.
# Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# The zero-arg tranche is locked by tools/probes/p_never_called_zeroarg.xi and
# the single-param tranche by tools/known_failures/p_sweep_single_param.xi.
# This generator covers the MULTI-param subset for scalar parameter types:
# it scans xiom/ for pub fns with MinParams..MaxParams params whose types are
# all scalar, keeps the ones never referenced in tests/ or xiom/ outside
# their declaration, emits ONE probe per declaring module (so failures
# localize by module group), type-checks it, then compiles it (no run:
# generated arguments may violate active contracts).
#
# Output: probes + a report under -OutDir (default: system temp). Nothing is
# written inside the repo unless -OutDir points there.
param(
  [string]$Compiler = "",
  [string]$Root = "",
  [int]$MinParams = 2,
  [int]$MaxParams = 4,
  [string]$OutDir = "",
  [switch]$KeepPassing,
  [switch]$EmitOnly,
  [int]$OnlyCalls = 0,
  [int]$Limit = 0,
  [int]$Timeout = 300
)
# NOTE: do NOT set $ErrorActionPreference = "Stop" here: PowerShell 5.1 turns
# a native compiler's stderr lines into ErrorRecords, which Stop would treat
# as terminating. Exit codes are checked explicitly instead.
$ErrorActionPreference = "Continue"
$repoRoot = if ($Root) { (Resolve-Path -LiteralPath $Root).Path } else { (Resolve-Path (Join-Path (Split-Path -Parent $PSScriptRoot) ".")).Path }
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot "xiom"))) { Write-Output "ERROR: xiom/ not found under $repoRoot"; exit 2 }
if ($env:XIOM_COMPILER -and (Test-Path -LiteralPath $env:XIOM_COMPILER)) { $Compiler = $env:XIOM_COMPILER }
if (-not $Compiler) {
  $cmd = Get-Command xiom -ErrorAction SilentlyContinue
  if ($cmd) { $Compiler = $cmd.Source } else { Write-Output "ERROR: no compiler (pass -Compiler or set XIOM_COMPILER)"; exit 2 }
}
if (-not $OutDir) { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) ("xiom-genprobes-" + (Get-Date -Format "yyyyMMdd-HHmmss")) }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$env:XIOM_STDLIB = $repoRoot

$scalar = @{
  "Int" = "0"; "Int8" = "0 as Int8"; "Int16" = "0 as Int16"; "Int32" = "0 as Int32"; "Int64" = "0 as Int64";
  "UInt" = "0 as UInt"; "UInt8" = "0 as UInt8"; "UInt16" = "0 as UInt16"; "UInt32" = "0 as UInt32"; "UInt64" = "0 as UInt64";
  "Bool" = "false"; "Char" = "65 as Char"; "Float32" = "0.0 as Float32"; "Float64" = "0.0"; "Str" = '""'
}

$files = Get-ChildItem -LiteralPath (Join-Path $repoRoot "xiom") -Filter *.xi -Recurse | Sort-Object FullName
$corpus = New-Object System.Text.StringBuilder
foreach ($f in $files) { [void]$corpus.AppendLine([System.IO.File]::ReadAllText($f.FullName)) }
foreach ($f in (Get-ChildItem -LiteralPath (Join-Path $repoRoot "tests") -Filter *.xi -Recurse | Sort-Object FullName)) { [void]$corpus.AppendLine([System.IO.File]::ReadAllText($f.FullName)) }
$corpusText = $corpus.ToString()

$decls = @()
foreach ($f in $files) {
  $src = [System.IO.File]::ReadAllText($f.FullName)
  $mod = "?"
  if ($src -match '(?m)^\s*module\s+([A-Za-z_][\w.]*)') { $mod = $Matches[1] }
  foreach ($m in [regex]::Matches($src, '(?m)^\s*pub\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)(\s*\[[^\]]*\])?\s*\(([^)]*)\)')) {
    $name = $m.Groups[1].Value
    if ($m.Groups[2].Value -ne "") { continue }  # generic fns need explicit type args
    $rawParams = $m.Groups[3].Value.Trim()
    if ($rawParams -eq "") { continue }
    $parts = $rawParams -split ','
    $types = @(); $ok = $true
    foreach ($p in $parts) {
      $t = $p.Trim()
      if ($t -match '^self\b') { $ok = $false; break }
      if ($t -notmatch '^[A-Za-z_][A-Za-z0-9_]*\s*:\s*(&?mut\s+)?([A-Za-z0-9_\[\]:., ]+)$') { $ok = $false; break }
      $ty = $Matches[2].Trim()
      if ($ty.StartsWith("&") -or $ty -match "^(Option|Result|Vec|Map|Set|fn|\[)") { $ok = $false; break }
      if (-not $scalar.ContainsKey($ty)) { $ok = $false; break }
      $types += $ty
    }
    if (-not $ok) { continue }
    if ($types.Count -lt $MinParams -or $types.Count -gt $MaxParams) { continue }
    # never-referenced filter: the name must not appear anywhere else.
    $hits = [regex]::Matches($corpusText, "\b" + [regex]::Escape($name) + "\b").Count
    # Declarations themselves count once per declaration; require exactly one decl hit.
    if ($hits -gt 1) { continue }
    $decls += [pscustomobject]@{ Module = $mod; Name = $name; Types = $types; File = $f.FullName }
  }
}

$byModule = $decls | Group-Object Module | Sort-Object Name
if ($OnlyCalls -gt 0) { $byModule = $byModule | Where-Object { $_.Count -eq $OnlyCalls } }
if ($Limit -gt 0) { $byModule = $byModule | Select-Object -First $Limit }
$report = @(); $fail = @(); $total = 0
foreach ($g in $byModule) {
  $safe = ($g.Name -replace '[^A-Za-z0-9_]', '_')
  $probe = Join-Path $OutDir ("gcp_" + $safe + ".xi")
  $lines = @("module gcp_$safe", "use $($g.Name);", "", "fn main() -> Int {")
  foreach ($d in $g.Group) {
    $args = ($d.Types | ForEach-Object { $scalar[$_] }) -join ", "
    $lines += "  $($g.Name).$($d.Name)($args);"
    $total++
  }
  $lines += "  return 0;"; $lines += "}"
  Set-Content -LiteralPath $probe -Value ($lines -join "`n") -Encoding ASCII
  if ($EmitOnly) { $report += "EMITTED $($g.Name) calls=$($g.Group.Count)"; continue }
  $checkOut = & $Compiler --check $probe 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { $report += "CHECKFAIL $($g.Name) calls=$($g.Group.Count)"; $fail += "$safe.check"; continue }
  $bin = Join-Path $OutDir ("gcp_" + $safe + ".exe")
  # -Timeout passes through to the compiler's own compile watchdog (default
  # 300s). Heavy import sets (xiom.net, xiom.num) legitimately exceed it in a
  # debug build; pass -Timeout 0 to disable the watchdog for those tranches.
  $compOut = & $Compiler --force --timeout $Timeout -o $bin $probe 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) {
    $report += "COMPILEFAIL $($g.Name) calls=$($g.Group.Count)"
    Set-Content -LiteralPath (Join-Path $OutDir ("gcp_" + $safe + ".err.txt")) -Value $compOut -Encoding ASCII
    $fail += "$safe.compile"
  } else {
    $report += "OK $($g.Name) calls=$($g.Group.Count)"
    if (-not $KeepPassing) { Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue }
  }
}
Write-Output ("GENPROBES: modules=$($byModule.Count) calls=$total failed=$($fail.Count) outdir=$OutDir")
$report | ForEach-Object { Write-Output $_ }
if ($fail.Count -gt 0) { Write-Output ("FAILED: " + ($fail -join " ")); exit 1 }
exit 0
