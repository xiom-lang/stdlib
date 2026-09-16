// XIOM - String: Glob
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.glob

// Depends on: xiom.misc.glob

// ============================================================================
// Glob wildcard matching -- CONSOLIDATED SHIM.
//
// The canonical implementation lives in `xiom.misc.glob` (which also owns
// the richer surface: escape/unescape, has_magic, quote, translate, and the
// compile/compile_match handle API). This module delegates for the two
// string-side entry points. Before the compiler's delegation fix (round-22,
// m62) the matcher was a copy-paste duplicate; a 15-vector parity probe
// (including class-pattern and case-insensitive cases) shows byte-identical
// behavior, locked by smoke_string_glob_parity.
//
// Supported metacharacters: '*' (zero or more bytes), '?' (exactly one byte);
// every other byte matches literally.
// ============================================================================

use xiom.misc.glob;

/// Match `s` against the glob `pattern`, case-sensitive.
/// Params: pattern the glob pattern; s the string to test.
/// Returns: true when `s` matches `pattern`.
/// Error case: none.
/// Complexity: O(|pattern| * |s|) worst case.
pub fn glob_match(pattern: Str, s: Str) -> Bool {
  xiom.misc.glob.glob_match(pattern, s)
}

/// Match `s` against the glob `pattern`, ignoring ASCII letter case.
/// Bytes above 0x7F match byte-exactly.
/// Params: pattern the glob pattern; s the string to test.
/// Returns: true when `s` matches `pattern` case-insensitively.
/// Error case: none.
/// Complexity: O(|pattern| * |s|) worst case.
pub fn glob_match_case_insensitive(pattern: Str, s: Str) -> Bool {
  xiom.misc.glob.glob_match_case_insensitive(pattern, s)
}
