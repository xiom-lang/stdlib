# check_contract_policy.ps1 -- B1 agreement check.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Proves that the three contract-policy artifacts agree:
#   - tools/coverage_scan.ps1 (authoritative counts)
#   - tools/contract_exemptions.json (EX-0 budget + per-function EX-1..EX-5)
#   - docs/MODULE_OWNERSHIP.md (per-module sign-off map)
#
# Fails (exit 1) when a public function is uncovered with no exemption, when
# an exemption is stale, or when the ownership map drifts from the scanner.
# Module-level records are EX-0 only; per-function records are EX-1..EX-5 and
# are checked against the named source file/function.
#
# Repo-relative by default. Runs on PowerShell 5.1 and pwsh 7+.
param(
  [string]$Exemptions = "",
  [string]$OwnershipMap = "",
  [switch]$NoMap
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($Exemptions -eq "") { $Exemptions = Join-Path $repoRoot "tools/contract_exemptions.json" }
if ($OwnershipMap -eq "") { $OwnershipMap = Join-Path $repoRoot "docs/MODULE_OWNERSHIP.md" }

$errs = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path -LiteralPath $Exemptions)) {
  Write-Output ("CONTRACT POLICY: FAIL - exemption registry missing: " + $Exemptions)
  exit 1
}

# Run the authoritative scanner in this scope; it sets $byDir, $totPub and
# $totPubCovered and prints a report we do not need here.
. (Join-Path $PSScriptRoot "coverage_scan.ps1") | Out-Null

$scanDirs = @{}
foreach ($r in @($byDir)) { $scanDirs[[string]$r.Dir] = $r }

try {
  $exDoc = Get-Content -LiteralPath $Exemptions -Raw | ConvertFrom-Json
} catch {
  Write-Output ("CONTRACT POLICY: FAIL - cannot parse " + $Exemptions + ": " + $_.Exception.Message)
  exit 1
}
if ([int]$exDoc.version -ne 1) { $errs.Add("registry: unsupported version '$($exDoc.version)'") }

$exByDir = @{}
$moduleLevelSeen = @{}
$functionSeen = @{}
foreach ($m in @($exDoc.modules)) {
  $name = [string]$m.module
  if ([string]::IsNullOrWhiteSpace($name)) { $errs.Add("registry: entry with empty module"); continue }
  $fnList = @()
  if (-not [string]::IsNullOrWhiteSpace([string]$m.function)) { $fnList += [string]$m.function }
  if ($null -ne $m.functions) {
    foreach ($x in @($m.functions)) {
      if (-not [string]::IsNullOrWhiteSpace([string]$x)) { $fnList += [string]$x }
    }
  }
  if ($fnList.Count -gt 0) {
    $category = [string]$m.category
    if ($category -notin @("EX-1", "EX-2", "EX-3", "EX-4", "EX-5")) {
      $errs.Add("registry ${name}: per-function category must be EX-1..EX-5")
    }
    $relPath = [string]$m.path
    if ([string]::IsNullOrWhiteSpace($relPath)) {
      $errs.Add("registry ${name}: missing path")
    } else {
      $srcPath = Join-Path $repoRoot $relPath
      if (-not (Test-Path -LiteralPath $srcPath)) {
        $errs.Add("registry ${name}: path not found: $relPath")
      } else {
        $srcText = Get-Content -LiteralPath $srcPath -Raw
        foreach ($fn in $fnList) {
          $fnPattern = 'fn\s+' + [regex]::Escape($fn) + '(\[[^\]]*\])?\s*\('
          if ($fn.Contains('.')) {
            $parts = $fn -split '\.', 2
            $fnPattern = 'fn\s+' + [regex]::Escape($parts[0]) + '(\[[^\]]*\])?\.' + [regex]::Escape($parts[1]) + '(\[[^\]]*\])?\s*\('
          }
          if ($srcText -notmatch $fnPattern) {
            $errs.Add("registry ${name}.${fn}: function not found in $relPath")
          }
          $key = $name + "|" + $fn
          if ($functionSeen.ContainsKey($key)) {
            $errs.Add("registry ${name}.${fn}: duplicate per-function entry")
          } else {
            $functionSeen[$key] = $true
          }
          if ($exByDir.ContainsKey($name)) { $exByDir[$name] += 1 } else { $exByDir[$name] = 1 }
        }
      }
    }
  } else {
    if ([string]$m.category -ne "EX-0") {
      $errs.Add("registry ${name}: module-level records must be EX-0")
    }
    if ($moduleLevelSeen.ContainsKey($name)) {
      $errs.Add("registry ${name}: duplicate module-level EX-0 record")
    } else {
      $moduleLevelSeen[$name] = $true
    }
    $count = 0
    try { $count = [int]$m.count } catch { $errs.Add("registry ${name}: count is not an integer"); continue }
    if ($count -lt 0) { $errs.Add("registry ${name}: negative count"); continue }
    if ($exByDir.ContainsKey($name)) { $exByDir[$name] += $count } else { $exByDir[$name] = $count }
  }
  if ([string]::IsNullOrWhiteSpace([string]$m.owner)) { $errs.Add("registry ${name}: missing owner") }
  if ([string]::IsNullOrWhiteSpace([string]$m.rationale)) { $errs.Add("registry ${name}: missing rationale") }
}

$exTotal = 0
foreach ($v in $exByDir.Values) { $exTotal += $v }
$uncoveredTotal = [int]$totPub - [int]$totPubCovered
if ($exTotal -ne $uncoveredTotal) {
  $errs.Add("registry total $exTotal does not match uncovered public functions $uncoveredTotal")
}
if ($null -ne $exDoc.total -and [int]$exDoc.total -ne $exTotal) {
  $errs.Add("registry declared total $($exDoc.total) does not match entry sum $exTotal")
}

foreach ($name in $exByDir.Keys) {
  if (-not $scanDirs.ContainsKey($name)) { $errs.Add("registry: module '$name' not found by the scanner") }
}
foreach ($r in @($byDir)) {
  $mod = [string]$r.Dir
  $uncovered = [int]$r.PubFns - [int]$r.PubCovered
  $claimed = 0
  if ($exByDir.ContainsKey($mod)) { $claimed = $exByDir[$mod] }
  if ($uncovered -ne $claimed) {
    $errs.Add("${mod}: $uncovered uncovered public fn(s) but registry records $claimed")
  }
}

if (-not $NoMap) {
  if (-not (Test-Path -LiteralPath $OwnershipMap)) {
    $errs.Add("ownership map missing: $OwnershipMap")
  } else {
    $mapRows = @{}
    $lineNo = 0
    foreach ($line in Get-Content -LiteralPath $OwnershipMap) {
      $lineNo++
      if ($line -cnotmatch '^\|\s*([a-z][a-z0-9_]*)\s*\|') { continue }
      $cells = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
      if ($cells.Count -ne 8) {
        $errs.Add("map line ${lineNo}: expected 8 columns, got $($cells.Count)")
        continue
      }
      $mod = $cells[0]
      if ($mapRows.ContainsKey($mod)) { $errs.Add("map line ${lineNo}: duplicate module '$mod'"); continue }
      $mapRows[$mod] = $cells
    }

    foreach ($r in @($byDir)) {
      $mod = [string]$r.Dir
      if (-not $mapRows.ContainsKey($mod)) { $errs.Add("map: missing module '$mod'"); continue }
      $c = $mapRows[$mod]
      try { $pub = [int]$c[2] } catch { $errs.Add("map ${mod}: pub fns '$($c[2])' is not an integer"); continue }
      try { $cov = [int]$c[3] } catch { $errs.Add("map ${mod}: covered '$($c[3])' is not an integer"); continue }
      try { $ex = [int]$c[4] } catch { $errs.Add("map ${mod}: exempt '$($c[4])' is not an integer"); continue }
      $uncovered = [int]$r.PubFns - [int]$r.PubCovered
      if ($pub -ne [int]$r.PubFns) { $errs.Add("map ${mod}: pub fns $pub != scanner $($r.PubFns)") }
      if ($cov -ne [int]$r.PubCovered) { $errs.Add("map ${mod}: covered $cov != scanner $($r.PubCovered)") }
      if ($ex -ne $uncovered) { $errs.Add("map ${mod}: exempt $ex != uncovered $uncovered") }
      try {
        $covVal = [double]($c[5] -replace '%', '')
        if ([math]::Abs($covVal - [double]$r.PubPct) -gt 0.05) {
          $errs.Add("map ${mod}: coverage $($c[5]) != scanner $($r.PubPct)%")
        }
      } catch {
        $errs.Add("map ${mod}: coverage '$($c[5])' is not a percentage")
      }
      $expectedStatus = "signed-off"
      if ($uncovered -gt 0) { $expectedStatus = "tail-approved" }
      if ($c[6] -ne $expectedStatus) {
        $errs.Add("map ${mod}: status '$($c[6])' should be '$expectedStatus'")
      }
      if ([string]::IsNullOrWhiteSpace($c[7])) { $errs.Add("map ${mod}: missing sign-off date") }
    }

    foreach ($k in $mapRows.Keys) {
      if (-not $scanDirs.ContainsKey($k)) { $errs.Add("map: unknown module '$k'") }
    }
  }
}

$moduleCount = @($byDir).Count
Write-Output ("contract policy: modules=" + $moduleCount + " pubFns=" + $totPub + " covered=" + $totPubCovered + " uncovered=" + $uncoveredTotal + " exemptions=" + $exTotal)
if ($errs.Count -gt 0) {
  Write-Output "CONTRACT POLICY: FAIL"
  foreach ($e in $errs) { Write-Output ("  " + $e) }
  exit 1
}
Write-Output "CONTRACT POLICY: OK"
exit 0
