// XIOM - String: Ngram
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.ngram

// Depends on: xiom.text.similarity

// ============================================================================
// Extract and count the n-grams of a string. Extraction delegates to
// xiom.text.similarity.ngram_extract (the canonical implementation); the
// count is a closed-form length computation.
// ============================================================================

use xiom.text.similarity;

/// All contiguous length-n character n-grams of `s` (n = 1 -> single
/// characters), in order of appearance, duplicates included. Delegates to
/// `xiom.text.similarity.ngram_extract`.
/// Params: s - the source string; n - the n-gram size (>= 1).
/// Returns: the list of n-grams; empty when n < 1 or when s is shorter than
/// `n`. A source of length exactly `n` yields the single n-gram `s`.
/// Errors: none (short/empty inputs yield an empty list).
/// Complexity: O(|s|) time with O(|s|) output.
pub fn ngram_extract(s: Str, n: Int) -> Vec[Str] {
  similarity.ngram_extract(s, n)
}

/// Number of contiguous length-n character n-grams of `s`, i.e.
/// max(0, |s| - n + 1) for n >= 1.
/// Params: s - the source string; n - the n-gram size (>= 1).
/// Returns: the n-gram count; 0 when n < 1 or when s is shorter than `n`.
/// Errors: none.
/// Complexity: O(1).
pub fn ngram_count(s: Str, n: Int) -> Int
  ensures: result >= 0
{
  if n <= 0 {
    return 0;
  };
  let len = s.len();
  if len < n {
    return 0;
  };
  len - n + 1
}
