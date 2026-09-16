// XIOM - String: LCS
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.lcs

// Depends on: xiom.text.similarity

// ============================================================================
// Longest common subsequence and longest common substring lengths. Both
// delegate to the canonical implementations in xiom.text.similarity.
// ============================================================================

use xiom.text.similarity;

/// Length of the longest common subsequence of `a` and `b` (a subsequence
/// keeps the relative order of characters without requiring contiguity).
/// Delegates to `xiom.text.similarity.longest_common_subsequence`.
/// Params: a, b - the strings to compare.
/// Returns: the LCS length (>= 0); e.g. 3 for ("ABCDGH", "AEDFHR") whose
/// longest common subsequence is "ADH".
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn longest_common_subsequence(a: Str, b: Str) -> Int
  ensures: result >= 0
{
  similarity.longest_common_subsequence(a, b)
}

/// Length of the longest common contiguous substring of `a` and `b`.
/// Delegates to `xiom.text.similarity.longest_common_substring`.
/// Params: a, b - the strings to compare.
/// Returns: the substring length (>= 0); e.g. 3 for ("abcdef", "zcdemf")
/// whose longest common substring is "cde".
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn longest_common_substring(a: Str, b: Str) -> Int
  ensures: result >= 0
{
  similarity.longest_common_substring(a, b)
}
