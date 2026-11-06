# contract_tail_inventory.ps1 -- B2 working list for the EX-0 contract tail.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Lists every public function that has no requires/ensures clause, using the
# same header rules as the authoritative tools/coverage_scan.ps1. It then
# cross-checks its per-module counts against the scanner and fails if they
# diverge, so the inventory cannot silently drift from the gate.
#
# Outputs:
#   console            summary
#   -Json <path>       machine-readable rows
#   -Markdown <path>   docs/CONTRACT_TAIL.md style table
#
# The list is the input to B2: each row becomes a clause or an EX-1..EX-5
# exemption record (EX-0 is closed to new entries).
param(
  [string]$Root = "",
  [string]$Json = "",
  [string]$Markdown = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
if ($Root -eq "") { $Root = Join-Path $repoRoot "xiom" }
$Root = (Resolve-Path -LiteralPath $Root).Path

# Authoritative totals + per-directory uncovered counts.
. (Join-Path $PSScriptRoot "coverage_scan.ps1") -Root $Root | Out-Null
$scanDirs = @{}
foreach ($r in @($byDir)) {
  $scanDirs[[string]$r.Dir] = [int]$r.PubFns - [int]$r.PubCovered
}

$rows = @()
$files = Get-ChildItem -Path $Root -Filter *.xi -Recurse | Sort-Object FullName
foreach ($f in $files) {
  $lines = [System.IO.File]::ReadAllLines($f.FullName)
  $n = $lines.Count
  $i = 0
  while ($i -lt $n) {
    $line = $lines[$i]
    if ($line -match '^\s*extern\s+"C"\s*\{') {
      $depth = 1
      $i++
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
      $header = ""
      $j = $i
      while ($j -lt $n -and ($j - $i) -lt 40) {
        $l = $lines[$j]
        $t = $l -replace '//.*$', ''
        $header += $l + "`n"
        if ($t.TrimEnd().EndsWith('{')) { break }
        $j++
      }
      if ($isPub) {
        $hc = ([regex]::Matches($header, '(requires|ensures)\s*:')).Count
        if ($hc -eq 0) {
          $name = "(unknown)"
          if ($line -match '^\s*pub\s+fn\s+([A-Za-z_][A-Za-z0-9_]*)(?:\[[^\]]*\])?(?:\.([A-Za-z_][A-Za-z0-9_]*))?') {
            $name = $Matches[1]
            if ($Matches.Count -ge 3 -and [string]$Matches[2] -ne "") {
              $name = $name + "." + [string]$Matches[2]
            }
          }
          $rel = $f.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
          $idx = $rel.IndexOfAny([char[]]@('\', '/'))
          $dir = if ($idx -ge 0) { $rel.Substring(0, $idx) } else { '(root)' }
          $sig = $line.Trim()
          if ($sig.Length -gt 160) { $sig = $sig.Substring(0, 160) + "..." }
          $rows += [pscustomobject]@{
            Module = $dir
            File = $rel
            Line = $i + 1
            Function = $name
            Signature = $sig
          }
        }
      }
      $i = $j + 1
      continue
    }
    $i++
  }
}

$rows = @($rows | Sort-Object Module, File, Line)

# Join the per-function B2 exemptions so the inventory is a progress tracker,
# not just a raw list. Any function without a per-function record is EX-0.
$exPath = Join-Path $repoRoot "tools/contract_exemptions.json"
$fnCategories = @{}
if (Test-Path -LiteralPath $exPath) {
  $exDoc = Get-Content -LiteralPath $exPath -Raw | ConvertFrom-Json
  foreach ($m in @($exDoc.modules)) {
    $mod = [string]$m.module
    $cat = [string]$m.category
    if (-not [string]::IsNullOrWhiteSpace([string]$m.function)) {
      $fnCategories[$mod + "|" + [string]$m.function] = $cat
    }
    if ($null -ne $m.functions) {
      foreach ($x in @($m.functions)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$x)) {
          $fnCategories[$mod + "|" + [string]$x] = $cat
        }
      }
    }
  }
}
foreach ($row in $rows) {
  $key = $row.Module + "|" + $row.Function
  $cat = "EX-0"
  if ($fnCategories.ContainsKey($key)) { $cat = $fnCategories[$key] }
  $row | Add-Member -NotePropertyName Category -NotePropertyValue $cat
}
$ex0Count = 0
$perFnCount = 0
foreach ($row in $rows) {
  if ($row.Category -eq "EX-0") { $ex0Count++ } else { $perFnCount++ }
}

$errs = New-Object System.Collections.Generic.List[string]
$invDirs = @{}
foreach ($row in $rows) {
  if ($invDirs.ContainsKey($row.Module)) { $invDirs[$row.Module]++ } else { $invDirs[$row.Module] = 1 }
}
foreach ($d in $scanDirs.Keys) {
  $got = 0
  if ($invDirs.ContainsKey($d)) { $got = $invDirs[$d] }
  if ($got -ne $scanDirs[$d]) {
    $errs.Add(("module '{0}': inventory {1} != scanner {2}" -f $d, $got, $scanDirs[$d]))
  }
}
foreach ($d in $invDirs.Keys) {
  if (-not $scanDirs.ContainsKey($d)) { $errs.Add("module '$d' is not in the scanner") }
}
$expected = [int]$totPub - [int]$totPubCovered
if ($rows.Count -ne $expected) {
  $errs.Add(("total: inventory {0} != scanner uncovered {1}" -f $rows.Count, $expected))
}

if ($errs.Count -gt 0) {
  Write-Output "CONTRACT TAIL: FAIL"
  foreach ($e in $errs) { Write-Output ("  " + $e) }
  exit 1
}

Write-Output ("contract-tail: uncovered=" + $rows.Count + " modules=" + $invDirs.Count + " ex0=" + $ex0Count + " per-function=" + $perFnCount + " (pubFns=" + $totPub + " covered=" + $totPubCovered + ")")
$modEx0 = @{}
$modPer = @{}
foreach ($row in $rows) {
  if ($row.Category -eq "EX-0") {
    if ($modEx0.ContainsKey($row.Module)) { $modEx0[$row.Module]++ } else { $modEx0[$row.Module] = 1 }
  } else {
    if ($modPer.ContainsKey($row.Module)) { $modPer[$row.Module]++ } else { $modPer[$row.Module] = 1 }
  }
}
foreach ($d in ($invDirs.Keys | Sort-Object)) {
  $e0 = 0
  $pf = 0
  if ($modEx0.ContainsKey($d)) { $e0 = $modEx0[$d] }
  if ($modPer.ContainsKey($d)) { $pf = $modPer[$d] }
  Write-Output ("  {0}: {1} (EX-0 {2}, per-function {3})" -f $d, $invDirs[$d], $e0, $pf)
}

if ($Json -ne "") {
  $doc = [pscustomobject]@{
    generated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
    source = "tools/coverage_scan.ps1"
    exemptions = "tools/contract_exemptions.json"
    total = $rows.Count
    ex0 = $ex0Count
    per_function = $perFnCount
    modules = $invDirs
    functions = $rows
  }
  $doc | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $Json -Encoding utf8
  Write-Output ("JSON: " + $Json)
}

if ($Markdown -ne "") {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("<!--")
  [void]$sb.AppendLine("Copyright (c) 2026 Eleftherios Notas and The XIOM Authors")
  [void]$sb.AppendLine("SPDX-License-Identifier: MIT OR Apache-2.0")
  [void]$sb.AppendLine("-->")
  [void]$sb.AppendLine("# Contract Tail Inventory (roadmap B2)")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("Generated: " + (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd") + " by ``tools/contract_tail_inventory.ps1``.")
  [void]$sb.AppendLine("Authoritative counts: ``tools/coverage_scan.ps1``. Policy: ``docs/CONTRACT_POLICY.md``.")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine(("**{0} uncovered public functions across {1} modules: {2} EX-0 and {3} per-function exemptions.** Each row becomes a clause or an EX-1..EX-5 exemption in B2; EX-0 is closed to new entries." -f $rows.Count, $invDirs.Count, $ex0Count, $perFnCount))
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("| Module | Uncovered | EX-0 | Per-function |")
  [void]$sb.AppendLine("|---|---:|---:|---:|")
  foreach ($d in ($invDirs.Keys | Sort-Object)) {
    $e0 = 0
    $pf = 0
    if ($modEx0.ContainsKey($d)) { $e0 = $modEx0[$d] }
    if ($modPer.ContainsKey($d)) { $pf = $modPer[$d] }
    [void]$sb.AppendLine(("| {0} | {1} | {2} | {3} |" -f $d, $invDirs[$d], $e0, $pf))
  }
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("## Functions")
  [void]$sb.AppendLine("")
  [void]$sb.AppendLine("| Module | File | Line | Function | Category | Signature |")
  [void]$sb.AppendLine("|---|---|---:|---|---|---|")
  foreach ($r in $rows) {
    $sig = $r.Signature -replace '\|', '\|'
    [void]$sb.AppendLine(("| {0} | {1} | {2} | ``{3}`` | ``{4}`` | ``{5}`` |" -f $r.Module, $r.File, $r.Line, $r.Function, $r.Category, $sig))
  }
  Set-Content -LiteralPath $Markdown -Value $sb.ToString() -Encoding utf8
  Write-Output ("MARKDOWN: " + $Markdown)
}
exit 0
