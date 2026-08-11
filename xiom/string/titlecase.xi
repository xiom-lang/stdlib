// XIOM - String: Titlecase
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.titlecase

// Depends on: xiom.string

// ============================================================================
// Unicode title-case conversion of a whole string and per-word. Both variants
// delegate to the flat string library's title-casing routine.
// ============================================================================

use xiom.string;

// Converts `s` to title case: the first character of each whitespace-separated
// word is uppercased and the remaining characters are lowercased.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_titlecase(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_title_case(s);
}

// Converts each word of `s` to title case, exactly like `str_titlecase`.
// Returns a new string with the same byte length as `s`.
// Complexity: O(|s|).
pub fn str_titlecase_words(s: Str) -> Str
  ensures: result.len() == s.len()
{
  return string.str_title_case(s);
}
