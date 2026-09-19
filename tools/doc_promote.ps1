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
  [switch]$Detail,
  [switch]$Dedupe
)
if ($Root -eq "") { $Root = Join-Path (Split-Path -Parent $PSScriptRoot) "xiom" }
if (-not (Test-Path -LiteralPath $Root)) { Write-Output ("ERROR: root not found: " + $Root); exit 2 }
$files = Get-ChildItem -Path $Root -Filter *.xi -Recurse | Sort-Object FullName
$totalBlocks = 0; $totalLines = 0; $skipped = 0; $changedFiles = @()
foreach ($f in $files) {
  # Split on LF only: CRLF files keep their trailing CR per line, mixed files
  # keep their exact bytes, and a final newline survives as a trailing ""
  # element when the file is re-joined with LF.
  $raw = [System.IO.File]::ReadAllText($f.FullName)
  $lines = $raw -split "`n"

  if ($Dedupe) {
    # Remove plain `// text` lines that an adjacent `/// text` run duplicates.
    # The first promoter version emitted converted lines IN ADDITION to the
    # originals for blocks it saw while passing them; this cleans that up.
    # Comment-only, exact-text match.
    $dout = New-Object System.Collections.Generic.List[string]
    $k = 0; $removed = 0
    while ($k -lt $lines.Count) {
      $cur = $lines[$k]
      if ($cur -match '^\s*//(?!/)') {
        # Maximal plain-comment run [k..m).
        $m = $k
        while ($m -lt $lines.Count -and $lines[$m] -match '^\s*//(?!/)') { $m++ }
        # Following doc run [m..n) must be identical in texts.
        $n = $m
        while ($n -lt $lines.Count -and $lines[$n] -match '^\s*///') { $n++ }
        $plain = @(); for ($x = $k; $x -lt $m; $x++) { $plain += (($lines[$x] -replace '^\s*//\s?', '')).TrimEnd("`r") }
        $doc = @(); for ($x = $m; $x -lt $n; $x++) { $doc += (($lines[$x] -replace '^\s*///\s?', '')).TrimEnd("`r") }
        if ($plain.Count -gt 0 -and $plain.Count -eq $doc.Count) {
          $same = $true
          for ($x = 0; $x -lt $plain.Count; $x++) { if ($plain[$x] -ne $doc[$x]) { $same = $false; break } }
          if ($same) {
            for ($x = $m; $x -lt $n; $x++) { $dout.Add($lines[$x]) | Out-Null }
            $removed += $plain.Count
            $k = $n
            continue
          }
        }
      }
      $dout.Add($cur) | Out-Null
      $k++
    }
    if ($removed -gt 0) {
      $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/')
      $changedFiles += $rel
      $totalBlocks++; $totalLines += $removed
      if ($Detail) { Write-Output ("  {0}: deduped_lines={1}" -f $rel, $removed) }
      if ($Apply) {
        [System.IO.File]::WriteAllText($f.FullName, ($dout -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
      }
    }
    continue
  }

  $out = New-Object System.Collections.Generic.List[string]
  $fileBlocks = 0; $fileLines = 0
  $i = 0
  while ($i -lt $lines.Count) {
    $line = $lines[$i]
    if ($line -match '^\s*pub\s+(fn|type|const|static|enum|trait|interface)\b') {
      # Collect the comment block directly above (tolerating ONE blank line,
      # the bits/sort/ptr banner pattern).
      $e = $i - 1
      $blanks = 0
      while ($e -ge 0 -and $lines[$e].Trim() -eq '' -and $blanks -lt 1) { $e--; $blanks++ }
      $start = $e + 1
      while ($start -gt 0 -and $lines[$start - 1] -match '^\s*//(?!/)') { $start-- }
      $block = @()
      if ($start -le $e) { $block = $lines[$start..$e] }
      $convertible = $true
      $bannerProse = @()
      if ($block.Count -eq 0) { $convertible = $false }
      foreach ($b in $block) {
        $t = $b.Trim()
        if ($b -match 'Copyright|SPDX-License|^\s*//\s*XIOM -') { $convertible = $false }
        if ($t -notmatch '^//\s*=+\s*$' -and $t -notmatch '^//\s*-+\s*$') { $bannerProse += $b }
      }
      if ($block.Count -gt 0 -and $block[0].Trim() -match '^//\s*Depends on:') { $convertible = $false }
      # Banner-wrapped prose (bits/sort/ptr pattern): a `// ----` framed block
      # whose middle lines are real prose. Promote the prose lines and drop
      # the separator framing; separator-only blocks stay untouched.
      $hasSeparators = ($bannerProse.Count -lt $block.Count)
      if ($hasSeparators -and $bannerProse.Count -eq 0) { $convertible = $false }
      if ($convertible -and $bannerProse.Count -gt 0) {
        # Remove the original block lines (and the blank line) that were
        # already emitted, so the converted block replaces them instead of
        # being appended as a duplicate.
        $removeN = ($i - $start)
        if ($removeN -gt 0 -and $out.Count -ge $removeN) { $out.RemoveRange($out.Count - $removeN, $removeN) }
        foreach ($b in $bannerProse) {
          $conv = $b -replace '^(\s*)//\s?', '$1/// '
          $out.Add($conv) | Out-Null
        }
        # The blank line between a banner block and the declaration is NOT
        # re-added: the `///` block must sit directly above the decl to be a
        # doc comment.
        $fileBlocks++; $fileLines += $bannerProse.Count
      } else {
        if ($block.Count -gt 0) { $skipped++ }
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
      # UTF-8 WITHOUT BOM: some modules carry non-ASCII string literals
      # (e.g. number_systems.xi); writing ASCII would corrupt them.
      [System.IO.File]::WriteAllText($f.FullName, ($out -join "`n"), (New-Object System.Text.UTF8Encoding($false)))
    }
  }
}
$mode = "DRY-RUN"
if ($Apply) { $mode = "APPLIED" }
Write-Output ("DOC-PROMOTE [{0}]: files={1} blocks={2} lines={3} skipped_blocks={4}" -f $mode, $changedFiles.Count, $totalBlocks, $totalLines, $skipped)
if (-not $Apply) { Write-Output "Re-run with -Apply to write." }
exit 0
