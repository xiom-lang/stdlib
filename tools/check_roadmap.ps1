# check_roadmap.ps1 -- validate docs/STDLIB_ROADMAP.md initiative tables.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Rules enforced:
#   - initiative IDs are unique and match RF-<n>, <A-G><n>, or X<n>
#   - Horizon is H1..H4
#   - Status is planned | in_progress | blocked | done | cancelled
#   - Exit criterion and Initiative are non-empty
#   - in_progress / blocked / done rows carry Evidence
#
# Exit code 1 on any violation (CI static job), 0 otherwise.
param(
  [string]$Roadmap = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($Roadmap -eq "") { $Roadmap = Join-Path $repoRoot "docs/STDLIB_ROADMAP.md" }
if (-not (Test-Path -LiteralPath $Roadmap)) {
  Write-Error "roadmap not found: $Roadmap"
  exit 2
}

$validStatus = @("planned", "in_progress", "blocked", "done", "cancelled")
$horizonPattern = '^H[1-4](-H[1-4])?$'
$idPattern = '^(RF-\d+|[A-G]\d+|X\d+)$'
$rowPattern = '^\|\s*(RF-\d+|[A-G]\d+|X\d+)\s*\|'

$errors = New-Object System.Collections.Generic.List[string]
$seen = @{}
$counts = @{ planned = 0; in_progress = 0; blocked = 0; done = 0; cancelled = 0 }
$rows = 0

foreach ($line in Get-Content -LiteralPath $Roadmap) {
  if ($line -notmatch $rowPattern) { continue }
  $rows++
  $parts = ($line.Trim().Trim('|') -split '\|')
  if ($parts.Count -lt 6) {
    $errors.Add("$($parts[0]): expected 6 columns, got $($parts.Count)")
    continue
  }
  $id = $parts[0].Trim()
  $initiative = $parts[1].Trim()
  $horizon = $parts[2].Trim()
  $status = $parts[3].Trim()
  $exit = $parts[4].Trim()
  $evidence = $parts[5].Trim()

  if ($id -notmatch $idPattern) { $errors.Add("${id}: bad id") }
  if ($seen.ContainsKey($id)) { $errors.Add("${id}: duplicate id") } else { $seen[$id] = $true }
  if ($initiative -eq "") { $errors.Add("${id}: empty initiative") }
  if ($exit -eq "") { $errors.Add("${id}: empty exit criterion") }
  if ($horizon -notmatch $horizonPattern) { $errors.Add("${id}: bad horizon '$horizon'") }
  if ($validStatus -notcontains $status) {
    $errors.Add("${id}: bad status '$status'")
  } else {
    $counts[$status]++
    if (($status -eq "in_progress" -or $status -eq "blocked" -or $status -eq "done") -and $evidence -eq "") {
      $errors.Add("${id}: '$status' requires evidence")
    }
  }
}

if ($rows -eq 0) { $errors.Add("no initiative rows found in $Roadmap") }

Write-Output ("roadmap: " + $Roadmap)
Write-Output ("rows={0} planned={1} in_progress={2} blocked={3} done={4} cancelled={5}" -f `
  $rows, $counts["planned"], $counts["in_progress"], $counts["blocked"], $counts["done"], $counts["cancelled"])

if ($errors.Count -gt 0) {
  Write-Output "ROADMAP: FAIL"
  foreach ($e in $errors) { Write-Output ("  " + $e) }
  exit 1
}
Write-Output "ROADMAP: OK"
exit 0
