// XIOM - String: Strip
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.strip

// Depends on: xiom.string, xiom.char

// ============================================================================
// Strip a prefix or suffix and remove whitespace or control characters. The
// prefix/suffix variants delegate to the flat string library; the whitespace
// and control variants are implemented here.
// ============================================================================

use xiom.string;

// Returns the character at byte index `i` of `s`.
// Precondition: 0 <= i < s.len().
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char {
  let b = string.byte_at(s, i) as Int;
  return b as Char;
}

/// If `s` starts with `prefix`, returns `Some(s without the prefix)`.
/// Returns `None` when `s` does not start with `prefix`.
/// Complexity: O(|prefix|).
pub fn str_strip_prefix(s: Str, prefix: Str) -> Option[Str] {
  return string.str_strip_prefix(s, prefix);
}

/// If `s` ends with `suffix`, returns `Some(s without the suffix)`.
/// Returns `None` when `s` does not end with `suffix`.
/// Complexity: O(|suffix|).
pub fn str_strip_suffix(s: Str, suffix: Str) -> Option[Str] {
  return string.str_strip_suffix(s, suffix);
}

/// Removes all whitespace characters from `s`.
/// Returns a new string no longer than `s`.
/// Complexity: O(|s|).
pub fn str_strip_whitespace(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if !xiom.char.is_whitespace(c) {
      result = string.str_concat(result, string.str_slice(s, i, i + bl));
    };
    i = i + bl;
  };
  result
}

/// Removes all control characters from `s`.
/// Returns a new string no longer than `s`.
/// Complexity: O(|s|).
pub fn str_strip_control(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if !xiom.char.is_control(c) {
      result = string.str_concat(result, string.str_slice(s, i, i + bl));
    };
    i = i + bl;
  };
  result
}
