// XIOM - String: Trim
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.trim

// Depends on: xiom.string

// ============================================================================
// Remove leading and/or trailing whitespace or a given set of characters.
// Trimming never increases the byte length of the input; `str_trim` delegates
// to the flat string library, the other variants are implemented here.
// ============================================================================

use xiom.string;

// Returns true when byte `b` is ASCII whitespace (space, tab, LF, CR).
// Complexity: O(1).
fn _is_ws(b: UInt8) -> Bool {
  let v = b as Int;
  return v == 32 || v == 9 || v == 10 || v == 13;
}

// Returns true when byte `b` occurs anywhere in `s`.
// Complexity: O(|s|).
fn _char_in_str(s: Str, b: UInt8) -> Bool {
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    if string.byte_at(s, i) == b {
      return true;
    };
    i = i + 1;
  };
  false
}

// Removes leading and trailing whitespace from `s`.
// Returns a new string no longer than `s`.
// Complexity: O(|s|).
pub fn str_trim(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  return string.str_trim(s);
}

// Removes leading whitespace from `s`.
// Returns a new string no longer than `s`.
// Complexity: O(|s|).
pub fn str_trim_start(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  let len = string.str_len(s);
  var start: Int = 0;
  while start < len && _is_ws(string.byte_at(s, start)) {
    start = start + 1;
  };
  string.str_slice(s, start, len)
}

// Removes trailing whitespace from `s`.
// Returns a new string no longer than `s`.
// Complexity: O(|s|).
pub fn str_trim_end(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  let len = string.str_len(s);
  var end: Int = len;
  while end > 0 && _is_ws(string.byte_at(s, end - 1)) {
    end = end - 1;
  };
  string.str_slice(s, 0, end)
}

// Removes leading and trailing characters listed in `chars` from `s`.
// When `chars` is empty, `s` is returned unchanged.
// Returns a new string no longer than `s`.
// Complexity: O(|s| * |chars|).
pub fn str_trim_matches(s: Str, chars: Str) -> Str
  ensures: result.len() <= s.len()
{
  let len = string.str_len(s);
  var start: Int = 0;
  while start < len && _char_in_str(chars, string.byte_at(s, start)) {
    start = start + 1;
  };
  var end: Int = len;
  while end > start && _char_in_str(chars, string.byte_at(s, end - 1)) {
    end = end - 1;
  };
  string.str_slice(s, start, end)
}

// Removes leading characters listed in `chars` from `s`.
// When `chars` is empty, `s` is returned unchanged.
// Returns a new string no longer than `s`.
// Complexity: O(|s| * |chars|).
pub fn str_trim_start_matches(s: Str, chars: Str) -> Str
  ensures: result.len() <= s.len()
{
  let len = string.str_len(s);
  var start: Int = 0;
  while start < len && _char_in_str(chars, string.byte_at(s, start)) {
    start = start + 1;
  };
  string.str_slice(s, start, len)
}

// Removes trailing characters listed in `chars` from `s`.
// When `chars` is empty, `s` is returned unchanged.
// Returns a new string no longer than `s`.
// Complexity: O(|s| * |chars|).
pub fn str_trim_end_matches(s: Str, chars: Str) -> Str
  ensures: result.len() <= s.len()
{
  let len = string.str_len(s);
  var end: Int = len;
  while end > 0 && _char_in_str(chars, string.byte_at(s, end - 1)) {
    end = end - 1;
  };
  string.str_slice(s, 0, end)
}
