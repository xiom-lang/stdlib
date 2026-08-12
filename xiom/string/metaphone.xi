// XIOM - String: Metaphone
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.metaphone

// Depends on: xiom.text.similarity

// ============================================================================
// Metaphone phonetic encoding and comparison for English words. The algorithm
// itself lives in xiom.text.similarity (canonical implementation); this module
// wraps it behind the xiom.string.metaphone API. Empty input encodes to "".
// ============================================================================

use xiom.text.similarity;

/// Metaphone code of `s`. Uppercases the input, keeps the first letter (with
/// a few start-of-word rules such as leading "kn" and "wr"), drops vowels,
/// maps the remaining consonants, then removes consecutive duplicate codes
/// and any non-leading H/W. Empty input encodes to "".
/// Params: s the word to encode.
/// Returns: the Metaphone code ("" for empty input).
/// Error case: none.
/// Complexity: O(|s|).
pub fn metaphone(s: Str) -> Str {
  similarity.metaphone(s)
}

/// True when `a` and `b` share the same Metaphone code, i.e. they sound alike.
/// Two empty strings compare equal (both encode to "").
/// Params: a, b the strings to compare.
/// Returns: true when metaphone(a) == metaphone(b).
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn metaphone_compare(a: Str, b: Str) -> Bool {
  let ca = similarity.metaphone(a);
  let cb = similarity.metaphone(b);
  ca == cb
}
