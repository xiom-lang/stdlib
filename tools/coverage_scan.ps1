# coverage_scan.ps1 -- contract-coverage scanner for xiom/ (readiness gate #7).
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
# Counts fn declarations and contract clauses (requires:/ensures:/invariant:).
# Metrics:
#   - clauses/fns            (the previously published global metric)
#   - pub fns with >=1 clause / pub fns   (the >=60% per-module gate metric)
# Ratchet mode: pass -RatchetFile <json> to fail (exit 1) when any recorded
# module metric regresses below the stored floor.
# Repo-relative by default: scans <repo root>/xiom, so the script works from
# any CWD and from CI checkouts. Runs on PowerShell 5.1 and pwsh 7+.
param(
  [string]$Root = "",
  [string]$RatchetFile = "",
  [string]$DumpFloors = "",
  [switch]$Detail
)
if ($Root -eq "") { $Root = Join-Path (Split-Path -Parent $PSScriptRoot) "xiom" }
if (-not (Test-Path -LiteralPath $Root)) { Write-Output ("ERROR: root not found: " + $Root); exit 2 }
$files = Get-ChildItem -Path $Root -Filter *.xi -Recurse | Sort-Object FullName
$rows = @()
$totFns = 0; $totPub = 0; $totClauses = 0; $totPubCovered = 0
foreach ($f in $files) {
  $lines = [System.IO.File]::ReadAllLines($f.FullName)
  $n = $lines.Count
  $fns = 0; $pubFns = 0; $clauses = 0; $pubCovered = 0
  $i = 0
  while ($i -lt $n) {
    $line = $lines[$i]
    # Skip extern "C" { ... } declaration blocks (brace counting).
    if ($line -match '^\s*extern\s+"C"\s*\{') {
      $depth = 1; $i++
      while ($i -lt $n -and $depth -gt 0) {
        foreach ($ch in $lines[$i].ToCharArray()) {
          if ($ch -eq '{') { $depth++ } elseif ($ch -eq '}') { $depth-- }
        }
        $i++
      }
      continue
    }
    if ($line -match '^\s*(pub\s+)?fn\s+') {
      $isPub = $line -match '^\s*pub\s+fn\s+'
      # Header = from fn line to (and incl.) the first line whose code ends with '{'.
      $header = ""
      $j = $i
      while ($j -lt $n -and ($j - $i) -lt 40) {
        $l = $lines[$j]
        $t = $l -replace '//.*$', ''
        $header += $l + "`n"
        if ($t.TrimEnd().EndsWith('{')) { break }
        $j++
      }
      $hc = ([regex]::Matches($header, '(requires|ensures)\s*:')).Count
      $fns++; $clauses += $hc
      if ($isPub) { $pubFns++; if ($hc -gt 0) { $pubCovered++ } }
      $i = $j + 1
      continue
    }
    # Type invariants count toward the clause total (not fn headers).
    if ($line -match '^\s*invariant\s*:') { $clauses++ }
    $i++
  }
  $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
  $idx = $rel.IndexOfAny([char[]]@('\', '/'))
  $dir = if ($idx -ge 0) { $rel.Substring(0, $idx) } else { '(root)' }
  $rows += [pscustomobject]@{
    File = $rel; Dir = $dir; Fns = $fns; PubFns = $pubFns
    Clauses = $clauses; PubCovered = $pubCovered
    PubPct = if ($pubFns -gt 0) { [math]::Round(100.0 * $pubCovered / $pubFns, 1) } else { 0 }
  }
  $totFns += $fns; $totPub += $pubFns; $totClauses += $clauses; $totPubCovered += $pubCovered
}
$byDir = $rows | Group-Object Dir | ForEach-Object {
  $g = $_.Group
  $f = ($g | Measure-Object Fns -Sum).Sum
  $p = ($g | Measure-Object PubFns -Sum).Sum
  $c = ($g | Measure-Object Clauses -Sum).Sum
  $pc = ($g | Measure-Object PubCovered -Sum).Sum
  [pscustomobject]@{
    Dir = $_.Name; Fns = $f; PubFns = $p; Clauses = $c; PubCovered = $pc
    ClausesPerFn = if ($f -gt 0) { [math]::Round(100.0 * $c / $f, 1) } else { 0 }
    PubPct = if ($p -gt 0) { [math]::Round(100.0 * $pc / $p, 1) } else { 0 }
  }
} | Sort-Object -Property @{Expression = 'PubPct'; Descending = $false}, Dir
Write-Output ("GLOBAL: fns=" + $totFns + "  pubFns=" + $totPub + "  clauses=" + $totClauses + "  pubCovered=" + $totPubCovered)
Write-Output ("GLOBAL clauses/fns = " + [math]::Round(100.0 * $totClauses / $totFns, 1) + "%   pub-with-clause = " + [math]::Round(100.0 * $totPubCovered / $totPub, 1) + "%")
Write-Output ""
Write-Output "PER-DIRECTORY (worst pub coverage first):"
$byDir | Format-Table Dir, Fns, PubFns, Clauses, ClausesPerFn, PubPct -AutoSize | Out-String -Width 200 | Write-Output
if ($Detail) {
  Write-Output "PER-FILE (io/string/collect + any pub coverage < 60%):"
  $rows | Where-Object { $_.Dir -in @('io','string','collect') -or ($_.PubFns -gt 0 -and $_.PubPct -lt 60) } |
    Sort-Object Dir, File | Format-Table File, Fns, PubFns, Clauses, PubPct -AutoSize | Out-String -Width 200 | Write-Output
}
if ($DumpFloors -ne "") {
  $floors = [ordered]@{}
  foreach ($d in $byDir) { $floors[$d.Dir] = $d.PubPct }
  $obj = [pscustomobject]@{ Generated = (Get-Date -Format s); Global = [math]::Round(100.0 * $totPubCovered / $totPub, 1); Floors = $floors }
  $obj | ConvertTo-Json -Depth 4 | Set-Content $DumpFloors
  Write-Output ("FLOORS WRITTEN: " + $DumpFloors)
}
if ($RatchetFile -ne "") {
  if (-not (Test-Path $RatchetFile)) {
    Write-Output ("RATCHET FAIL: floors file missing: " + $RatchetFile)
    exit 1
  }
  $fail = 0
  $json = Get-Content $RatchetFile -Raw | ConvertFrom-Json
  foreach ($entry in $json.Floors.PSObject.Properties) {
    $dir = $entry.Name
    $floor = [double]$entry.Value
    $actual = ($byDir | Where-Object { $_.Dir -eq $dir } | Select-Object -First 1)
    if ($null -eq $actual) { Write-Output ("RATCHET FAIL: module " + $dir + " not found"); $fail++; continue }
    if ($actual.PubPct -lt $floor) {
      Write-Output ("RATCHET FAIL: " + $dir + " pub-coverage " + $actual.PubPct + "% < floor " + $floor + "%")
      $fail++
    }
  }
  if ($fail -gt 0) { Write-Output ("RATCHET: FAILED (" + $fail + ")"); exit 1 }
  Write-Output "RATCHET: OK"
}
