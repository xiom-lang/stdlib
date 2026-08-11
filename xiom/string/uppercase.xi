// XIOM - String: Uppercase
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.uppercase

// Depends on: xiom.string, xiom.char

// ============================================================================
// Uppercase conversion for strings and single characters. The string variant
// delegates to the flat string library; the character variant delegates to
// the character library. Both are pure and ASCII-correct.
// ============================================================================

use xiom.string;

// Converts all characters of `s` to uppercase.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_uppercase(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_upper(s);
}

// Returns the uppercase variant of `c`, or `c` unchanged when `c` has no
// uppercase mapping.
// Complexity: O(1).
pub fn char_uppercase(c: Char) -> Char {
  return xiom.char.to_uppercase(c);
}
