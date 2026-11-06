# record_release_lock.ps1 -- G3 release immutability record.
# Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
# SPDX-License-Identifier: MIT OR Apache-2.0
#
# Run AFTER creating the annotated stdlib release tag. It records the tag
# object, the peeled commit and the tag's COMPILER_VERSION in
# release-locks/<tag>.json, then you commit that file to main. The guard in
# check_release_state.ps1 fails if the tag is later moved.
#
# This helper never creates, moves or deletes a tag. Do not use it to bless a
# moved tag: if the tag already moved, record the historical facts in a
# known_moved lock instead (see release-locks/stdlib-v0.65.6.json).
param(
  [Parameter(Mandatory = $true)]
  [string]$Tag,
  [string]$CompilerVersion = "",
  [string]$RepoRoot = "",
  [string]$Output = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
if ($RepoRoot -eq "") { $RepoRoot = Split-Path -Parent $PSScriptRoot }
if ($Tag -notmatch '^stdlib-v\d+\.\d+\.\d+$') {
  Write-Output "record-release-lock: FAIL - tag must be stdlib-vX.Y.Z"
  exit 1
}
$version = $Tag.Substring("stdlib-v".Length)

Push-Location $RepoRoot
try {
  $prevEap = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  & git rev-parse --verify "refs/tags/$Tag" 2>$null | Out-Null
  $ErrorActionPreference = $prevEap
  if ($LASTEXITCODE -ne 0) {
    Write-Output "record-release-lock: FAIL - tag '$Tag' does not exist"
    exit 1
  }
  $tagType = (& git cat-file -t $Tag 2>&1 | Out-String).Trim()
  if ($tagType -ne "tag") {
    Write-Output "record-release-lock: FAIL - tag '$Tag' is '$tagType', expected annotated"
    exit 1
  }
  $tagObject = (& git rev-parse $Tag 2>&1 | Out-String).Trim()
  $tagCommit = (& git rev-parse ("${Tag}^{}") 2>&1 | Out-String).Trim()
  $tagCv = (& git show ("${Tag}" + ":COMPILER_VERSION") 2>&1 | Out-String).Trim()
  if ($tagCv -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Output "record-release-lock: FAIL - tag COMPILER_VERSION '$tagCv' is not a concrete pin"
    exit 1
  }
  if ($CompilerVersion -ne "" -and $CompilerVersion.Trim() -ne $tagCv) {
    Write-Output "record-release-lock: FAIL - -CompilerVersion '$CompilerVersion' != tag pin '$tagCv'"
    exit 1
  }

  $doc = [pscustomobject]@{
    schema = 1
    tag = $Tag
    version = $version
    commit = $tagCommit
    tag_object = $tagObject
    compiler_version = $tagCv
    recorded = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
    source = "tools/record_release_lock.ps1 at cut time"
  }
  $json = $doc | ConvertTo-Json -Depth 4
  if ($DryRun) {
    Write-Output $json
    exit 0
  }
  if ($Output -eq "") { $Output = Join-Path $RepoRoot ("release-locks/" + $Tag + ".json") }
  $dir = Split-Path -Parent $Output
  if ($dir -ne "" -and -not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  Set-Content -LiteralPath $Output -Value $json -Encoding utf8
  Write-Output ("record-release-lock: wrote " + $Output)
  Write-Output ("  tag=" + $Tag + " tag_object=" + $tagObject + " commit=" + $tagCommit + " compiler=" + $tagCv)
} finally {
  Pop-Location
}
exit 0
