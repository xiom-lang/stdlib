// XIOM - String: Slice
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
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

// Wave 111 (xvector REL-20261011-1453): raw byte access over a cached
// (base, len) view. string.byte_at re-scans the whole string per call
// (runtime strnlen), so byte-stepped conversions were quadratic in the
// string size (`str_bytes` on 400 KB took ~3.7 s). Callers bounds-check
// against the cached length.
fn _slice_raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// Masking UTF-8 decode at byte `pos` over a cached (base, len) view --
/// byte-exact mirror of the previous `_char_at_decoded` (which read through
/// `string.byte_at`): continuation bytes are masked, NOT validated, and
/// out-of-range bytes read as 0 exactly like the old accessor. Kept as the
/// `str_code_points` decoder for behavior compatibility.
/// Complexity: O(1).
fn _char_at_masked(base: *UInt8, len: Int, pos: Int) -> Char {
  var b0 = 0;
  if pos >= 0 && pos < len {
    b0 = (_slice_raw_byte(base, pos) as Int) & 0xFF;
  }
  if b0 <= 0x7F {
    return to_char(b0);
  }
  if (b0 & 0xE0) == 0xC0 {
    var b1 = 0;
    if pos + 1 < len {
      b1 = (_slice_raw_byte(base, pos + 1) as Int) & 0xFF;
    }
    let cp = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    return to_char(cp);
  }
  if (b0 & 0xF0) == 0xE0 {
    var b1 = 0;
    if pos + 1 < len {
      b1 = (_slice_raw_byte(base, pos + 1) as Int) & 0xFF;
    }
    var b2 = 0;
    if pos + 2 < len {
      b2 = (_slice_raw_byte(base, pos + 2) as Int) & 0xFF;
    }
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    return to_char(cp);
  }
  var b1 = 0;
  if pos + 1 < len {
    b1 = (_slice_raw_byte(base, pos + 1) as Int) & 0xFF;
  }
  var b2 = 0;
  if pos + 2 < len {
    b2 = (_slice_raw_byte(base, pos + 2) as Int) & 0xFF;
  }
  var b3 = 0;
  if pos + 3 < len {
    b3 = (_slice_raw_byte(base, pos + 3) as Int) & 0xFF;
  }
  let cp = ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F);
  to_char(cp)
}

/// Runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached (base, len)
/// view: continuation bytes are validated, a malformed or truncated
/// sequence yields the leading byte itself, and a stray continuation byte
/// is returned as-is. Out-of-range positions/bytes read as 0 (the NUL byte
/// the runtime would see).
/// Complexity: O(1).
fn _char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_slice_raw_byte(base, pos) as Int) & 0xFF;
  if b0 < 0x80 {
    return to_char(b0);
  }
  var n = 0;
  var cp = 0;
  if (b0 & 0xE0) == 0xC0 {
    n = 2;
    cp = b0 & 0x1F;
  } elif (b0 & 0xF0) == 0xE0 {
    n = 3;
    cp = b0 & 0x0F;
  } elif (b0 & 0xF8) == 0xF0 {
    n = 4;
    cp = b0 & 0x07;
  } else {
    return to_char(b0);
  }
  var i = 1;
  while i < n {
    var cb = 0;
    if pos + i < len {
      cb = (_slice_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
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
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let ch = _char_at_runtime(base, len, i);
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
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    result.push(_slice_raw_byte(base, i));
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
  let len = s.len();
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let ch = _char_at_masked(base, len, i);
    result.push(to_int_from_char(ch));
    let bl = char.len_utf8(ch);
    i = i + bl;
  };
  result
}
