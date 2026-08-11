// XIOM - Misc: Semantic Versioning
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.semver

// Depends on: xiom.string

// ============================================================================
// SemVer parsing, comparison, constraint matching (caret, tilde, range),
// incrementing and serialization. NOTE: current implementation lives in
// misc.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// type SemVer - a semantic version: major, minor, patch, prerelease and build metadata.
// fn semver_parse(s: Str) -> Option[SemVer] - parse a semantic version string. TODO(compiler): implement.
// fn semver_compare(a: SemVer, b: SemVer) -> Int - order two versions: -1, 0, or 1. TODO(compiler): implement.
// fn semver_valid(s: Str) -> Bool - whether s is a valid semantic version. TODO(compiler): implement.
// fn semver_matches(version: Str, constraint: Str) -> Bool - whether a version satisfies a constraint string. TODO(compiler): implement.
// fn semver_satisfies(version, range) -> Bool - whether a version falls inside a hyphen or comma range. TODO(compiler): implement.
// fn semver_inc(s: Str, part: Str) -> Option[Str] - bump a version part ("major", "minor", "patch", "prerelease", "build"). TODO(compiler): implement.
// fn semver_to_string(v: SemVer) -> Str - serialize a version back to text. TODO(compiler): implement.
// fn semver_prerelease(v) -> Option[Str] - the prerelease identifier, if any. TODO(compiler): implement.
// fn semver_build(v) -> Option[Str] - the build metadata, if any. TODO(compiler): implement.
// fn semver_caret(a, b) -> Bool - caret compatibility (same major). TODO(compiler): implement.
// fn semver_tilde(a, b) -> Bool - tilde compatibility (same minor). TODO(compiler): implement.
// fn semver_gt(a, b) -> Bool - strict greater-than comparison. TODO(compiler): implement.
// fn semver_lt(a, b) -> Bool - strict less-than comparison. TODO(compiler): implement.
