# doc_promote.ps1 -- promote attached plain comments to `///` doc comments.
# Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Many pub declarations already have prose written as `//` comments directly
# above them; the API-docs generator only publishes `///`, so those entries
# fall back to generated summaries. This tool converts the contiguous plain
# comment block IMMEDIATELY above a pub declaration into a `///` block.
#
# Conservative guards (a block is skipped when):
#   - it contains a separator/banner line (`// ====`, `// ----`)
#   - it contains Copyright / SPDX / a `XIOM -` module banner
#   - its first line starts with `Depends on:`
#   - any line is already `///`
# Dry-run is the default; pass -Apply to write changes. Comment-only edits:
# codegen, contracts and semantics are untouched.
param(
  [string]$Root = "",
  [switch]$Apply,
  [switch]$Detail
)
if ($Root -eq "") { $Root = Join-Path (Split-Path -Parent $PSScriptRoot) "xiom" }
if (-not (Test-Path -LiteralPath $Root)) { Write-Output ("ERROR: root not found: " + $Root); exit 2 }
$files = Get-ChildItem -Path $Root -Filter *.xi -Recurse | Sort-Object FullName
$totalBlocks = 0; $totalLines = 0; $skipped = 0; $changedFiles = @()
foreach ($f in $files) {
  $lines = [System.IO.File]::ReadAllLines($f.FullName)
  $out = New-Object System.Collections.Generic.List[string]
  $fileBlocks = 0; $fileLines = 0
  $i = 0
  while ($i -lt $lines.Count) {
    $line = $lines[$i]
    if ($line -match '^\s*pub\s+(fn|type|const|static|enum|trait|interface)\b') {
      # Collect the contiguous plain-comment block directly above.
      $start = $i
      while ($start -gt 0 -and $lines[$start - 1] -match '^\s*//(?!/)') { $start-- }
      $block = @()
      if ($start -lt $i) { $block = $lines[$start..($i - 1)] }
      $convertible = $true
      if ($block.Count -eq 0) { $convertible = $false }
      foreach ($b in $block) {
        $t = $b.Trim()
        if ($t -match '^//\s*=+\s*$' -or $t -match '^//\s*-+\s*$') { $convertible = $false }
        if ($b -match 'Copyright|SPDX-License|^\s*//\s*XIOM -') { $convertible = $false }
      }
      if ($block.Count -gt 0 -and $block[0].Trim() -match '^//\s*Depends on:') { $convertible = $false }
      if ($convertible) {
        for ($k = 0; $k -lt $block.Count; $k++) {
          $conv = $block[$k] -replace '^(\s*)//\s?', '$1/// '
          $out.Add($conv) | Out-Null
        }
        $fileBlocks++; $fileLines += $block.Count
      } else {
        if ($block.Count -gt 0) { $skipped++ }
        foreach ($b in $block) { $out.Add($b) | Out-Null }
      }
      $out.Add($line) | Out-Null
      $i++
      continue
    }
    $out.Add($line) | Out-Null
    $i++
  }
  if ($fileBlocks -gt 0) {
    $totalBlocks += $fileBlocks; $totalLines += $fileLines
    $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
    $changedFiles += $rel
    if ($Detail) { Write-Output ("  {0}: blocks={1} lines={2}" -f $rel, $fileBlocks, $fileLines) }
    if ($Apply) {
      $raw = [System.IO.File]::ReadAllText($f.FullName)
      $nl = "`n"
      if ($raw.Contains("`r`n")) { $nl = "`r`n" }
      [System.IO.File]::WriteAllText($f.FullName, ($out -join $nl), (New-Object System.Text.ASCIIEncoding))
    }
  }
}
$mode = "DRY-RUN"
if ($Apply) { $mode = "APPLIED" }
Write-Output ("DOC-PROMOTE [{0}]: files={1} blocks={2} lines={3} skipped_blocks={4}" -f $mode, $changedFiles.Count, $totalBlocks, $totalLines, $skipped)
if (-not $Apply) { Write-Output "Re-run with -Apply to write." }
exit 0
