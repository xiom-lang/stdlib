// XIOM - String: Truncate
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.truncate

// Depends on: none

// ============================================================================
// Truncate a string by length, by bytes, or from the middle, with optional
// ellipsis. NOTE: current implementation lives in misc.truncate - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.char;

extern "C" {
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Returns the last `n` characters of `s` (n as a Unicode character count),
/// walking back across UTF-8 boundaries. n < 1 yields "", n >= |s| yields `s`.
/// Complexity: O(n).
fn _last_chars(s: Str, n: Int) -> Str {
  let len = string.str_len(s);
  if n <= 0 {
    return "";
  };
  if n >= len {
    return s;
  };
  var count: Int = 0;
  var i = len;
  while count < n {
    var char_start = i - 1;
    var guard: Int = 0;
    while char_start > 0 && guard < 4 {
      let b = (string.byte_at(s, char_start) as Int) & 0xFF;
      if (b & 0xC0) != 0x80 {
        break;
      };
      char_start = char_start - 1;
      guard = guard + 1;
    };
    let b0 = (string.byte_at(s, char_start) as Int) & 0xFF;
    var bl: Int = 1;
    if b0 <= 0x7F {
      bl = 1;
    } elif (b0 & 0xE0) == 0xC0 {
      bl = 2;
    } elif (b0 & 0xF0) == 0xE0 {
      bl = 3;
    } else {
      bl = 4;
    };
    i = char_start;
    count = count + 1;
  };
  string.str_slice(s, i, len)
}

/// Truncates `s` to at most `max_len` Unicode characters, cutting only at
/// character boundaries. max_len < 0 yields the empty string; a string at or
/// under the limit is returned unchanged.
/// Params: s the source string; max_len the character limit.
/// Returns: the truncated string (result.len() <= s.len()).
/// Error case: "" when max_len < 0.
/// Complexity: O(s.len()).
pub fn str_truncate(s: Str, max_len: Int) -> Str
  ensures: result.len() <= s.len()
{
  if max_len < 0 {
    return "";
  };
  let len = string.str_len(s);
  if max_len >= len {
    return s;
  };
  if max_len == 0 {
    return "";
  };
  var count: Int = 0;
  var i: Int = 0;
  var cut: Int = 0;
  while i < len && count < max_len {
    let ch = xiom_char_at(s, i);
    let bl = char.len_utf8(ch);
    cut = i + bl;
    i = i + bl;
    count = count + 1;
  };
  string.str_slice(s, 0, cut)
}

/// Truncates `s` to at most `max_bytes` bytes, cutting only at a UTF-8
/// boundary so no multi-byte character is split. A string at or under the
/// limit is returned unchanged; max_bytes <= 0 yields the empty string.
/// Params: s the source string; max_bytes the byte limit.
/// Returns: the truncated string.
/// Error case: "" when max_bytes <= 0.
/// Complexity: O(s.len()).
pub fn str_truncate_utf8(s: Str, max_bytes: Int) -> Str
  ensures: result.len() <= s.len()
{
  string.str_truncate_utf8(s, max_bytes)
}

/// Truncates `s` keeping both ends and removing the middle: the first half of
/// the budget comes from the front, the second half from the back. A string at
/// or under `max_len` characters is returned unchanged; max_len < 0 yields
/// the empty string.
/// Params: s the source string; max_len the character budget.
/// Returns: the head+tail string (result.len() <= s.len()).
/// Error case: "" when max_len < 0.
/// Complexity: O(s.len()).
pub fn str_truncate_middle(s: Str, max_len: Int) -> Str
  ensures: result.len() <= s.len()
{
  if max_len < 0 {
    return "";
  };
  let len = string.str_len(s);
  if len <= max_len {
    return s;
  };
  if max_len == 0 {
    return "";
  };
  if max_len <= 2 {
    return str_truncate(s, max_len);
  };
  let front = max_len / 2;
  let back = max_len - front;
  var head = str_truncate(s, front);
  var tail = _last_chars(s, back);
  string.str_concat(head, tail)
}

/// Truncates `s` to `max_len` characters appending an ellipsis: the result is
/// `(max_len - 3)` leading characters followed by "...". For limits too small
/// to hold an ellipsis (max_len <= 3) plain truncation is used; a string at or
/// under the limit is returned unchanged; max_len < 0 yields the empty string.
/// Params: s the source string; max_len the total length including "...".
/// Returns: the truncated-with-ellipsis string.
/// Error case: "" when max_len < 0.
/// Complexity: O(s.len()).
pub fn str_truncate_with_ellipsis(s: Str, max_len: Int) -> Str
  ensures: result.len() <= s.len()
{
  if max_len < 0 {
    return "";
  };
  let len = string.str_len(s);
  if len <= max_len {
    return s;
  };
  if max_len == 0 {
    return "";
  };
  if max_len <= 3 {
    return str_truncate(s, max_len);
  };
  let keep = max_len - 3;
  var head = str_truncate(s, keep);
  string.str_concat(head, "...")
}
