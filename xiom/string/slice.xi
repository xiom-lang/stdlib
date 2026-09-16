// XIOM - String: Slice
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.slice

// Depends on: none

// ============================================================================
// Extract substrings and enumerate the characters, bytes, and code points of a
// string. NOTE: current implementation lives in string - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.char;

extern "C" {
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Decodes the full UTF-8 character starting at byte `pos` of `s` and returns
/// it as a Char whose code point equals the decoded Unicode scalar value.
/// The runtime char reader only exposes the leading byte, so the sequence is
/// decoded from the raw bytes. Invalid continuation bytes are treated
/// conservatively as the leading byte itself.
/// Complexity: O(1).
fn _char_at_decoded(s: Str, pos: Int) -> Char {
  let b0 = (string.byte_at(s, pos) as Int) & 0xFF;
  if b0 <= 0x7F {
    return to_char(b0);
  };
  if (b0 & 0xE0) == 0xC0 {
    let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
    let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    return to_char(cp);
  };
  if (b0 & 0xF0) == 0xE0 {
    let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
    let b2 = (string.byte_at(s, pos + 2) as Int) & 0xFF;
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    return to_char(cp);
  };
  let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
  let b2 = (string.byte_at(s, pos + 2) as Int) & 0xFF;
  let b3 = (string.byte_at(s, pos + 3) as Int) & 0xFF;
  let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
  to_char(cp)
}

/// Returns the substring of `s` from byte index `start` (inclusive) to byte
/// index `end` (exclusive), following the string.str_slice convention: a
/// negative `start` is clamped to 0, `end` beyond the string length is clamped
/// to the length, and an out-of-order range yields the empty string.
/// Params: s the source string; start the inclusive start byte index;
///         end the exclusive end byte index.
/// Returns: the substring in [start, end).
/// Error case: none - indices are clamped before use; never out-of-bounds.
/// Complexity: O(end - start).
pub fn str_slice(s: Str, start: Int, end: Int) -> Str
  ensures: result.len() <= s.len()
{
  var s_start = start;
  var s_end = end;
  let len = string.str_len(s);
  if s_start < 0 {
    s_start = 0;
  };
  if s_end > len {
    s_end = len;
  };
  if s_start >= s_end {
    return "";
  };
  string.str_slice(s, s_start, s_end)
}

/// Returns `len` bytes of `s` starting at byte index `start`.
/// Invalid ranges (negative `start`, negative `len`, or `start` at/after the
/// end of `s`) are rejected with the empty string - never out-of-bounds.
/// Params: s the source string; start the inclusive start byte index;
///         len the number of bytes to take.
/// Returns: the substring, or "" when the range is invalid.
/// Error case: "" when start < 0, len < 0, or start >= s.len().
/// Complexity: O(len).
pub fn str_substring(s: Str, start: Int, len: Int) -> Str
  ensures: result.len() <= s.len()
{
  let s_len = string.str_len(s);
  if start < 0 {
    return "";
  };
  if len < 0 {
    return "";
  };
  if start >= s_len {
    return "";
  };
  var end = start + len;
  if end > s_len {
    end = s_len;
  };
  string.str_slice(s, start, end)
}

/// Returns the characters of `s` as a vector, in source order. The runtime's
/// char reader is byte-oriented, so each element carries the leading byte of
/// the UTF-8 sequence it starts (for ASCII this equals the code point).
/// Iteration advances at real UTF-8 boundaries, so one element is produced per
/// Unicode character.
/// Params: s the source string.
/// Returns: a Vec[Char] with one element per Unicode character.
/// Error case: none; empty input yields an empty vector.
/// Complexity: O(s.len()).
pub fn str_chars(s: Str) -> Vec[Char]
  ensures: result.len() <= s.len()
{
  var result = Vec[Char].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let ch = xiom_char_at(s, i);
    result.push(ch);
    let bl = char.len_utf8(ch);
    i = i + bl;
  };
  result
}

/// Returns the raw bytes of `s` as a vector, in source order.
/// Params: s the source string.
/// Returns: a Vec[UInt8] with one element per byte of `s`.
/// Error case: none; empty input yields an empty vector.
/// Complexity: O(s.len()).
pub fn str_bytes(s: Str) -> Vec[UInt8]
  ensures: result.len() == s.len()
{
  var result = Vec[UInt8].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    result.push(string.byte_at(s, i));
    i = i + 1;
  };
  result
}

/// Returns the Unicode code points of `s` as integers, in source order.
/// Iterates at UTF-8 character boundaries via the runtime char reader.
/// Params: s the source string.
/// Returns: a Vec[Int] with one element per Unicode code point of `s`.
/// Error case: none; empty input yields an empty vector.
/// Complexity: O(s.len()).
pub fn str_code_points(s: Str) -> Vec[Int]
  ensures: result.len() <= s.len()
{
  var result = Vec[Int].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let ch = _char_at_decoded(s, i);
    result.push(to_int_from_char(ch));
    let bl = char.len_utf8(ch);
    i = i + bl;
  };
  result
}
