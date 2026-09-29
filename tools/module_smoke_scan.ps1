# module_smoke_scan.ps1 -- static module/function smoke-coverage scan.
#
# Readiness criterion (owner, 2026-09-29): every stdlib module must be
# exercised by at least one smoke file, and every public function should be
# referenced by at least one smoke call. This tool approximates that
# statically: a module is covered when a smoke imports it (`use <module>;`)
# or calls one of its public functions with the leaf qualifier
# (`<leaf>.<fn>(`, which also matches parent-module aliases such as
# `math.algebra.gcd(`); a function is covered when `<leaf>.<fn>(` appears.
#
# Exit codes: 0 = ratchet OK (or baseline dump), 2 = coverage regressed
# relative to the baselines's aggregates.
param(
  [string]$Root = ".",
  [switch]$DumpBaseline,
  [string]$BaselineFile = "tools/module_smoke_floors.json",
  [switch]$Details,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Get-ModuleMap([string]$root) {
  $map = @{}
  Get-ChildItem -Path (Join-Path $root "xiom") -Recurse -Filter *.xi -File | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    if ($text -match "(?m)^module\s+([A-Za-z0-9_.]+)") {
      $name = $Matches[1]
      $fns = [regex]::Matches($text, "(?m)^pub fn (\w+)") | ForEach-Object { $_.Groups[1].Value }
      $map[$name] = @{ Path = $_.FullName; Leaf = ($name -split '\.')[-1]; Fns = @($fns | Sort-Object -Unique) }
    }
  }
  return $map
}

$moduleMap = Get-ModuleMap $Root
$smokeFiles = Get-ChildItem -Path (Join-Path $Root "tests/smoke") -Filter *.xi -File
$smokeText = ($smokeFiles | ForEach-Object { [System.IO.File]::ReadAllText($_.FullName) }) -join "`n"

$missingModules = New-Object System.Collections.Generic.List[string]
$missingFns = New-Object System.Collections.Generic.List[string]
$totalFns = 0
$coveredFns = 0

foreach ($name in ($moduleMap.Keys | Sort-Object)) {
  $m = $moduleMap[$name]
  $covered = $smokeText -match ("use\s+" + [regex]::Escape($name) + "\s*;")
  $fnCoveredHere = 0
  if (-not $covered) {
    foreach ($fn in $m.Fns) {
      if ($smokeText.Contains("$($m.Leaf).$fn(")) { $covered = $true; break }
    }
  }
  foreach ($fn in $m.Fns) {
    $totalFns++
    if ($smokeText.Contains("$($m.Leaf).$fn(")) { $coveredFns++; $fnCoveredHere++ }
    else { [void]$missingFns.Add("$name.$fn") }
  }
  if (-not $covered) { [void]$missingModules.Add($name) }
}

$totalModules = $moduleMap.Count
$coveredModules = $totalModules - $missingModules.Count

$baseline = [ordered]@{
  generated = (Get-Date).ToUniversalTime().ToString("o")
  totalModules = $totalModules
  coveredModules = $coveredModules
  totalPublicFns = $totalFns
  coveredPublicFns = $coveredFns
  missingModules = @($missingModules | Sort-Object)
}

if ($DumpBaseline) {
  $dir = Split-Path -Parent $BaselineFile
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $baseline | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BaselineFile -Encoding UTF8
  Write-Output "module_smoke_scan: baseline dumped to $BaselineFile"
  Write-Output "module_smoke_scan: modules $coveredModules/$totalModules covered; public fns $coveredFns/$totalFns referenced"
  if ($Details -and -not $Quiet) { $baseline.missingModules | ForEach-Object { Write-Output "  MISSING-MODULE $_" } }
  exit 0
}

if (-not (Test-Path $BaselineFile)) { Write-Output "module_smoke_scan: no baseline at $BaselineFile"; exit 2 }
$floor = Get-Content $BaselineFile -Raw | ConvertFrom-Json
$ok = $true
if ($coveredModules -lt [int]$floor.coveredModules) { Write-Output "module_smoke_scan: REGRESSED modules $coveredModules < $($floor.coveredModules)"; $ok = $false }
if ($coveredFns -lt [int]$floor.coveredPublicFns) { Write-Output "module_smoke_scan: REGRESSED fns $coveredFns < $($floor.coveredPublicFns)"; $ok = $false }
if (-not $Quiet -or -not $ok) {
  Write-Output "module_smoke_scan: modules $coveredModules/$totalModules ($([math]::Round(100.0*$coveredModules/$totalModules,1))%) covered; public fns $coveredFns/$totalFns ($([math]::Round(100.0*$coveredFns/$totalFns,1))%) referenced"
}
if ($ok) { Write-Output "MODULE-SMOKE RATCHET: OK" } else { Write-Output "MODULE-SMOKE RATCHET: FAILED" }
if ($ok) { exit 0 } else { exit 2 }
