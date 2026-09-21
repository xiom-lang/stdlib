# doc_scan.ps1 -- documentation coverage scanner for xiom/ (API-docs quality).
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Counts pub declarations (pub fn/type/const/static/enum/trait/interface) and
# how many carry a preceding `///` doc line (the prose the API-docs generator
# publishes). Emits a global + per-top-level-directory summary, an optional
# per-file detail, and can dump/replay a ratchet baseline so doc coverage
# never falls below what was reached.
#
# Repo-relative by default: scans <repo root>/xiom. Runs on PowerShell 5.1
# and pwsh 7+.
param(
  [string]$Root = "",
  [switch]$Detail,
  [string]$DumpBaseline = "",
  [string]$RatchetFile = ""
)
if ($Root -eq "") { $Root = Join-Path (Split-Path -Parent $PSScriptRoot) "xiom" }
if (-not (Test-Path -LiteralPath $Root)) { Write-Output ("ERROR: root not found: " + $Root); exit 2 }
$files = Get-ChildItem -Path $Root -Filter *.xi -Recurse | Sort-Object FullName
$fileRows = @()
foreach ($f in $files) {
  $lines = [System.IO.File]::ReadAllLines($f.FullName)
  $pub = 0; $docs = 0
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^\s*pub\s+(fn|type|const|static|enum|trait|interface)\b') {
      $pub++
      $j = $i - 1
      while ($j -ge 0 -and $lines[$j].Trim() -eq '') { $j-- }
      if ($j -ge 0 -and $lines[$j].TrimStart().StartsWith('///')) { $docs++ }
    }
  }
  if ($pub -gt 0) { $fileRows += [pscustomobject]@{ File = $f.FullName; Pub = $pub; Doc = $docs } }
}
$totalPub = 0; $totalDoc = 0
$dirRows = @()
# Aggregate per directory (PowerShell 5.1-safe loop).
$agg = @{}
foreach ($r in $fileRows) {
  $rel = $r.File.Substring($Root.Length).TrimStart('\', '/')
  $dir = "."
  if ($rel.Contains('\')) { $dir = ($rel -split '\\')[0] }
  if (-not $agg.ContainsKey($dir)) { $agg[$dir] = @{ Pub = 0; Doc = 0 } }
  $agg[$dir].Pub += $r.Pub
  $agg[$dir].Doc += $r.Doc
  $totalPub += $r.Pub
  $totalDoc += $r.Doc
}
$globalPct = 0
if ($totalPub -gt 0) { $globalPct = [math]::Round(100.0 * $totalDoc / $totalPub, 1) }
Write-Output ("DOCS: pub=$totalPub documented=$totalDoc missing=$($totalPub - $totalDoc) pct=$globalPct")
Write-Output ""
Write-Output "PER-DIRECTORY (worst coverage first):"
Write-Output ""
Write-Output ("Dir          Pub  Doc  Missing  Pct")
Write-Output ("---          ---  ---  -------  ---")
$dirRows = $agg.Keys | ForEach-Object {
  $a = $agg[$_]
  $pct = 0
  if ($a.Pub -gt 0) { $pct = [math]::Round(100.0 * $a.Doc / $a.Pub, 1) }
  [pscustomobject]@{ Dir = $_; Pub = $a.Pub; Doc = $a.Doc; Missing = ($a.Pub - $a.Doc); Pct = $pct }
}
$dirRows | Sort-Object Pct, Dir | ForEach-Object {
  "{0,-12} {1,4} {2,4} {3,8} {4,5}" -f $_.Dir, $_.Pub, $_.Doc, $_.Missing, $_.Pct
}
if ($Detail) {
  Write-Output ""
  Write-Output "PER-FILE (lowest coverage first):"
  $fileRows | ForEach-Object {
    $pct = 0
    if ($_.Pub -gt 0) { $pct = [math]::Round(100.0 * $_.Doc / $_.Pub, 1) }
    [pscustomobject]@{ File = $_.File.Substring($Root.Length).TrimStart('\', '/'); Pub = $_.Pub; Doc = $_.Doc; Pct = $pct }
  } | Sort-Object Pct | ForEach-Object {
    "{0,5} {1,4}/{2,-4} {3}" -f $_.Pct, $_.Doc, $_.Pub, $_.File
  }
}
if ($DumpBaseline -ne "") {
  $floors = @{}
  foreach ($r in $dirRows) { $floors[$r.Dir] = $r.Doc }
  $obj = [pscustomobject]@{ Generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"); Pub = $totalPub; Doc = $totalDoc; GlobalPct = $globalPct; Floors = $floors }
  $obj | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $DumpBaseline -Encoding ASCII
  Write-Output ("DOC BASELINE WRITTEN: " + $DumpBaseline)
}
if ($RatchetFile -ne "") {
  if (-not (Test-Path -LiteralPath $RatchetFile)) { Write-Output ("ERROR: ratchet not found: " + $RatchetFile); exit 2 }
  $base = Get-Content -LiteralPath $RatchetFile -Raw | ConvertFrom-Json
  $viol = @()
  foreach ($k in $base.Floors.PSObject.Properties.Name) {
    $cur = 0
    if ($agg.ContainsKey($k)) { $cur = $agg[$k].Doc }
    $floor = [int]$base.Floors.$k
    if ($cur -lt $floor) { $viol += ("{0}: {1} < {2}" -f $k, $cur, $floor) }
  }
  if ($totalDoc -lt [int]$base.Doc) { $viol += ("global: {0} < {1}" -f $totalDoc, $base.Doc) }
  if ($viol.Count -gt 0) {
    Write-Output ("DOC RATCHET: FAIL")
    $viol | ForEach-Object { Write-Output ("  " + $_) }
    exit 1
  }
  Write-Output "DOC RATCHET: OK"
}
exit 0
