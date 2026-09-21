// XIOM - String: Lowercase
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.lowercase

// Depends on: xiom.string, xiom.char

// ============================================================================
// Lowercase conversion for strings and single characters. The string variant
// delegates to the flat string library; the character variant delegates to
// the character library. Both are pure and ASCII-correct.
// ============================================================================

use xiom.string;

/// Converts all characters of `s` to lowercase.
/// Returns a new string with the same byte length as `s`.
/// Complexity: O(|s|).
pub fn str_lowercase(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_lower(s);
}

/// Returns the lowercase variant of `c`, or `c` unchanged when `c` has no
/// lowercase mapping.
/// Complexity: O(1).
pub fn char_lowercase(c: Char) -> Char {
  return xiom.char.to_lowercase(c);
}
