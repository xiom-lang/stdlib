// XIOM - String: LCSuffix
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.lcsuffix

// Depends on: xiom.text.similarity

// ============================================================================
// Longest common suffix of two strings. The canonical implementation lives
// in xiom.text.similarity; this module re-exposes it under the
// xiom.string.lcsuffix API.
// ============================================================================

use xiom.text.similarity;

/// Length of the longest common suffix of `a` and `b` (in bytes). Delegates
/// to `xiom.text.similarity.longest_common_suffix`.
/// Params: a, b - the strings to compare.
/// Returns: the shared suffix length in 0..min(|a|, |b|).
/// Errors: none.
/// Complexity: O(min(|a|, |b|)).
pub fn longest_common_suffix(a: Str, b: Str) -> Int
  ensures: result >= 0
{
  similarity.longest_common_suffix(a, b)
}
