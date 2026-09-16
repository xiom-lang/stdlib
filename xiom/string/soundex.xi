// XIOM - String: Soundex
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.soundex

// Depends on: xiom.text.similarity

// ============================================================================
// Soundex phonetic encoding and comparison for English words. The algorithm
// itself lives in xiom.text.similarity (canonical implementation); this module
// wraps it behind the xiom.string.soundex API. Empty input encodes to "".
// ============================================================================

use xiom.text.similarity;

/// Four-character American Soundex code of `s`. The first letter is kept
/// uppercased, the remaining letters are mapped to digit codes with adjacent
/// duplicates collapsed (unless separated by a vowel), and the code is padded
/// or truncated to exactly 4 characters. Empty input encodes to "".
/// Params: s the word to encode.
/// Returns: the 4-character Soundex code ("" for empty input).
/// Error case: none; non-alphabetic leading characters yield their code 0.
/// Complexity: O(|s|).
pub fn soundex(s: Str) -> Str {
  similarity.soundex(s)
}

/// True when `a` and `b` share the same Soundex code, i.e. they sound alike.
/// Two empty strings compare equal (both encode to "").
/// Params: a, b the strings to compare.
/// Returns: true when soundex(a) == soundex(b).
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn soundex_compare(a: Str, b: Str) -> Bool {
  let ca = similarity.soundex(a);
  let cb = similarity.soundex(b);
  ca == cb
}
