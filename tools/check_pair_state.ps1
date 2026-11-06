# check_pair_state.ps1 -- G3 compiler+stdlib pair check.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# The other half of the release guard: the compiler tag named by
# COMPILER_VERSION must expose STDLIB_VERSION, and that pin must name a real
# stdlib release tag. The pair is exact after the compiler release catches up
# to a new stdlib tag; during the stdlib-first window the compiler pin is one
# or more releases behind, which is reported as a warning unless
# -RequireLatest is set (use that at pair closeout).
#
# Modes:
#   -CompilerRepo <path>  read <tag>:STDLIB_VERSION from a local compiler clone
#                         (falls back to the worktree file if the tag is absent)
#   otherwise             fetch the public raw file from
#                         https://raw.githubusercontent.com/<slug>/<tag>/STDLIB_VERSION
#
# Exit 0 when the pair is consistent or a release-window lag is only a
# warning; exit 1 on a missing/malformed pin, an unknown stdlib tag, a pin
# ahead of the latest tag, or a lag under -RequireLatest.
param(
  [string]$RepoRoot = "",
  [string]$CompilerRepo = "",
  [string]$CompilerVersion = "",
  [string]$CompilerRepoSlug = "xiom-lang/xiom",
  [string]$TagPrefix = "stdlib-v",
  [switch]$RequireLatest,
  [switch]$Offline
)

$ErrorActionPreference = "Stop"
if ($RepoRoot -eq "") { $RepoRoot = Split-Path -Parent $PSScriptRoot }

$errs = New-Object System.Collections.Generic.List[string]
$warns = New-Object System.Collections.Generic.List[string]

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
  $latest = ""
  $latestVer = ""
  $cv = ""
  $pin = ""
  $pinVer = ""
  $source = ""

  $tags = @(& git tag --list ($TagPrefix + "*") --sort=-v:refname 2>&1)
  if ($LASTEXITCODE -ne 0) {
    $errs.Add("git tag list failed (needs a git checkout with tags)")
  } elseif ($tags.Count -eq 0) {
    $errs.Add("no stdlib release tag matching '$TagPrefix*'")
  } else {
    $latest = ([string]$tags[0]).Trim()
    $latestVer = $latest.Substring($TagPrefix.Length)
    if ($latestVer -notmatch '^\d+\.\d+\.\d+$') {
      $errs.Add("latest tag '$latest' does not carry X.Y.Z")
    }
  }

  if ($CompilerVersion -ne "") {
    $cv = $CompilerVersion.Trim()
  } else {
    $cvPath = Join-Path $RepoRoot "COMPILER_VERSION"
    if (Test-Path -LiteralPath $cvPath) {
      $cv = (Get-Content -LiteralPath $cvPath -Raw).Trim()
    } else {
      $errs.Add("COMPILER_VERSION missing")
    }
  }
  if ($cv -ne "" -and $cv -notmatch '^v\d+\.\d+\.\d+$') {
    $errs.Add("COMPILER_VERSION '$cv' is not a concrete vX.Y.Z pin")
  }

  if ($cv -ne "") {
    if ($CompilerRepo -ne "" -and (Test-Path -LiteralPath $CompilerRepo)) {
      & git -C $CompilerRepo rev-parse --verify "refs/tags/$cv" 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) {
        $pin = (& git -C $CompilerRepo show ("$cv" + ":STDLIB_VERSION") 2>&1 | Out-String).Trim()
        $source = "local-tag"
      } else {
        $pinPath = Join-Path $CompilerRepo "STDLIB_VERSION"
        if (Test-Path -LiteralPath $pinPath) {
          $pin = (Get-Content -LiteralPath $pinPath -Raw).Trim()
          $source = "local-worktree"
          $warns.Add("compiler tag '$cv' not found locally; using the worktree STDLIB_VERSION")
        } else {
          $errs.Add("compiler repo '$CompilerRepo' has no tag '$cv' and no STDLIB_VERSION")
        }
      }
    }

    if ($pin -eq "" -and -not $Offline) {
      $url = "https://raw.githubusercontent.com/" + $CompilerRepoSlug + "/" + $cv + "/STDLIB_VERSION"
      try {
        $resp = Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 30
        $pin = ([string]$resp.Content).Trim()
        $source = "network"
      } catch {
        $errs.Add("cannot fetch compiler pin '$url': " + $_.Exception.Message)
      }
    }
    if ($pin -eq "" -and $Offline) {
      $errs.Add("offline mode needs -CompilerRepo with tag '$cv' or its STDLIB_VERSION")
    }
  }

  if ($pin -ne "") {
    if (-not $pin.StartsWith($TagPrefix)) {
      $errs.Add("compiler pin '$pin' does not start with '$TagPrefix'")
    } else {
      $pinVer = $pin.Substring($TagPrefix.Length)
      if ($pinVer -notmatch '^\d+\.\d+\.\d+$') {
        $errs.Add("compiler pin '$pin' does not carry X.Y.Z")
      }
      $known = @(& git tag --list $pin 2>&1)
      if ($LASTEXITCODE -ne 0) {
        $errs.Add("cannot check stdlib tag '$pin'")
      } elseif ($known.Count -eq 0) {
        $errs.Add("compiler pin '$pin' is not a tag in this stdlib repo")
      }
    }
  }

  if ($pinVer -ne "" -and $latestVer -ne "") {
    $cmp = Compare-Version $pinVer $latestVer
    if ($cmp -lt 0) {
      $msg = "compiler pin is behind the latest stdlib tag ($pin < $latest); expected during the stdlib-first release window"
      if ($RequireLatest) { $errs.Add($msg) } else { $warns.Add($msg) }
    } elseif ($cmp -gt 0) {
      $errs.Add("compiler pin is ahead of the latest stdlib tag ($pin > $latest)")
    }
  }
} finally {
  Pop-Location
}

Write-Output ("pair-state: compiler=" + $cv + " compiler_pin=" + $pin + " stdlib_latest=" + $latest + " source=" + $source + " require_latest=" + [bool]$RequireLatest)
foreach ($w in $warns) { Write-Output ("  warn: " + $w) }
if ($errs.Count -gt 0) {
  Write-Output "PAIR STATE: FAIL"
  foreach ($e in $errs) { Write-Output ("  " + $e) }
  exit 1
}
Write-Output "PAIR STATE: OK"
exit 0
