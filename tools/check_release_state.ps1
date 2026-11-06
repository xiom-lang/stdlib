# check_release_state.ps1 -- G3 release-state guard.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Catches the v0.65.5 branch-drift class before it can recur:
#   - the latest stdlib release tag is annotated and an ancestor of HEAD;
#   - package.xi has not regressed behind that release (it may be ahead
#     while a release-prep branch is open);
#   - no merge commits exist after the release tag;
#   - release-notes/v<version>.md and the CHANGELOG entry exist;
#   - COMPILER_VERSION is a concrete vX.Y.Z pin.
#
# Needs full history and tags: CI checks out with fetch-depth: 0.
# Exit 0 when consistent, 1 with a list of violations.
param(
  [string]$RepoRoot = "",
  [string]$TagPrefix = "stdlib-v",
  [string]$HeadRef = ""
)

$ErrorActionPreference = "Stop"
if ($RepoRoot -eq "") { $RepoRoot = Split-Path -Parent $PSScriptRoot }
if ([string]::IsNullOrWhiteSpace($HeadRef)) { $HeadRef = "HEAD" }

$errs = New-Object System.Collections.Generic.List[string]
$notes = New-Object System.Collections.Generic.List[string]

function Compare-Version([string]$a, [string]$b) {
  $pa = $a.Split('.')
  $pb = $b.Split('.')
  $n = [Math]::Min($pa.Count, $pb.Count)
  for ($i = 0; $i -lt $n; $i++) {
    $x = 0; $y = 0
    if (-not [int]::TryParse($pa[$i], [ref]$x)) { return 0 }
    if (-not [int]::TryParse($pb[$i], [ref]$y)) { return 0 }
    if ($x -lt $y) { return -1 }
    if ($x -gt $y) { return 1 }
  }
  if ($pa.Count -lt $pb.Count) { return -1 }
  if ($pa.Count -gt $pb.Count) { return 1 }
  return 0
}

Push-Location $RepoRoot
try {
  $tag = ""
  $ver = ""
  $pkgVer = ""
  $cv = ""
  $mergeCount = -1

  $tags = @(& git tag --list ($TagPrefix + "*") --sort=-v:refname 2>&1)
  if ($LASTEXITCODE -ne 0) {
    $errs.Add("git tag list failed (is this a git checkout with tags?)")
  } elseif ($tags.Count -eq 0) {
    $errs.Add("no release tag matching '$TagPrefix*'")
  } else {
    $tag = ([string]$tags[0]).Trim()
    if (-not $tag.StartsWith($TagPrefix)) {
      $errs.Add("unexpected tag '$tag' (prefix '$TagPrefix')")
    } else {
      $ver = $tag.Substring($TagPrefix.Length)
      if ($ver -notmatch '^\d+\.\d+\.\d+$') {
        $errs.Add("tag '$tag' does not carry a X.Y.Z version")
      }
    }
  }

  if ($tag -ne "") {
    $tagType = (& git cat-file -t $tag 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
      $errs.Add("cannot inspect tag '$tag'")
    } elseif ($tagType -ne "tag") {
      $errs.Add("tag '$tag' is $tagType, expected an annotated tag")
    }

    & git merge-base --is-ancestor $tag $HeadRef 2>$null
    if ($LASTEXITCODE -ne 0) {
      $errs.Add("last release tag '$tag' is not an ancestor of $HeadRef (main does not contain the release)")
    }

    $mergeText = (& git rev-list --merges --count ("$tag..$HeadRef") 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
      $errs.Add("cannot count merge commits after '$tag'")
    } else {
      $mergeCount = [int]$mergeText
      if ($mergeCount -ne 0) {
        $errs.Add("$mergeCount merge commit(s) after '$tag' on $HeadRef (land linearly)")
      }
    }
  }

  if (Test-Path -LiteralPath (Join-Path $RepoRoot "package.xi")) {
    $pkg = Get-Content -LiteralPath (Join-Path $RepoRoot "package.xi") -Raw
    $m = [regex]::Match($pkg, 'version:\s*"([0-9]+\.[0-9]+\.[0-9]+)"')
    if (-not $m.Success) {
      $errs.Add('package.xi: version: "X.Y.Z" not found')
    } else {
      $pkgVer = $m.Groups[1].Value
      if ($ver -ne "") {
        $cmp = Compare-Version $pkgVer $ver
        if ($cmp -lt 0) {
          $errs.Add("package.xi version $pkgVer is behind the last release $ver")
        } elseif ($cmp -gt 0) {
          $notes.Add("package.xi is ahead of the last release ($pkgVer > $ver); release prep in progress")
        }
      }
    }
  } else {
    $errs.Add("package.xi missing")
  }

  if (Test-Path -LiteralPath (Join-Path $RepoRoot "COMPILER_VERSION")) {
    $cv = (Get-Content -LiteralPath (Join-Path $RepoRoot "COMPILER_VERSION") -Raw).Trim()
    if ($cv -notmatch '^v\d+\.\d+\.\d+$') {
      $errs.Add("COMPILER_VERSION '$cv' is not a concrete vX.Y.Z pin")
    }
  } else {
    $errs.Add("COMPILER_VERSION missing")
  }

  if ($ver -ne "") {
    $notePath = Join-Path $RepoRoot ("release-notes/v" + $ver + ".md")
    if (-not (Test-Path -LiteralPath $notePath)) {
      $errs.Add("release-notes/v$ver.md missing for the last release")
    }
    $changelogPath = Join-Path $RepoRoot "CHANGELOG.md"
    if (-not (Test-Path -LiteralPath $changelogPath)) {
      $errs.Add("CHANGELOG.md missing")
    } else {
      $changelog = Get-Content -LiteralPath $changelogPath -Raw
      $heading = '##\s*\[?' + [regex]::Escape($ver) + '\]?'
      if ($changelog -notmatch $heading) {
        $errs.Add("CHANGELOG.md has no '## [$ver]' entry")
      }
    }
  }
} finally {
  Pop-Location
}

Write-Output ("release-state: tag=" + $tag + " version=" + $ver + " package=" + $pkgVer + " compiler=" + $cv + " head=" + $HeadRef + " merges_after_tag=" + $mergeCount)
foreach ($n in $notes) { Write-Output ("  note: " + $n) }
if ($errs.Count -gt 0) {
  Write-Output "RELEASE STATE: FAIL"
  foreach ($e in $errs) { Write-Output ("  " + $e) }
  exit 1
}
Write-Output "RELEASE STATE: OK"
exit 0
