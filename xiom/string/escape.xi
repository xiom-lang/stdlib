// XIOM - String: Escape
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.escape

// Depends on: none

// ============================================================================
// Escape special characters in a string for safe embedding in source or data.
// NOTE: current implementation lives in string.str_escape - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Decodes the full UTF-8 character starting at byte `pos` of `s` and returns
/// its code point. The runtime char reader only exposes the leading byte, so
/// the sequence is decoded from the raw bytes. Invalid continuation bytes are
/// treated conservatively as the leading byte value.
/// Complexity: O(1).
fn _code_point_at(s: Str, pos: Int) -> Int {
  let b0 = (string.byte_at(s, pos) as Int) & 0xFF;
  if b0 <= 0x7F {
    return b0;
  };
  if (b0 & 0xE0) == 0xC0 {
    let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if (b0 & 0xF0) == 0xE0 {
    let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
    let b2 = (string.byte_at(s, pos + 2) as Int) & 0xFF;
    return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
  };
  let b1 = (string.byte_at(s, pos + 1) as Int) & 0xFF;
  let b2 = (string.byte_at(s, pos + 2) as Int) & 0xFF;
  let b3 = (string.byte_at(s, pos + 3) as Int) & 0xFF;
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

/// Escapes the control and special characters of `s` (\n, \t, \", \\, \r) so
/// the result can be embedded safely in source or data. All other characters
/// pass through unchanged.
/// Params: s the source string.
/// Returns: the escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape(s: Str) -> Str {
  string.str_escape(s)
}

/// Interprets the escape sequences in `s` (\n, \t, \", \\, \r) back into
/// literal characters. Unrecognised escapes are left unchanged, so
/// str_escape then str_unescape is a faithful round-trip.
/// Params: s the source string.
/// Returns: the unescaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_unescape(s: Str) -> Str {
  string.str_unescape(s)
}

/// Renders the low 8 bits of `v` as a lowercase two-digit hex string.
/// Complexity: O(1).
fn _hex2(v: Int) -> Str {
  let table = "0123456789abcdef";
  let hi = (v >> 4) & 0x0F;
  let lo = v & 0x0F;
  let s1 = string.str_slice(table, hi, hi + 1);
  let s2 = string.str_slice(table, lo, lo + 1);
  string.str_concat(s1, s2)
}

/// Renders the low 16 bits of `v` as a lowercase four-digit hex string.
/// Complexity: O(1).
fn _hex4(v: Int) -> Str {
  let table = "0123456789abcdef";
  var result = "";
  var shift: Int = 12;
  while shift >= 0 {
    let digit = (v >> shift) & 0x0F;
    let piece = string.str_slice(table, digit, digit + 1);
    result = string.str_concat(result, piece);
    shift = shift - 4;
  };
  result
}

/// Escapes every non-ASCII byte of `s` as a lowercase \xNN sequence; ASCII
/// bytes pass through unchanged. Useful for producing pure-ASCII output.
/// Params: s the source string.
/// Returns: the ASCII-escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape_ascii(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let b = (string.byte_at(s, i) as Int) & 0xFF;
    if b < 0x80 {
      let piece = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, piece);
    } else {
      result = string.str_concat(result, "\\x");
      let hex = _hex2(b);
      result = string.str_concat(result, hex);
    };
    i = i + 1;
  };
  result
}

/// Escapes every non-ASCII code point of `s` as a lowercase \uNNNN sequence
/// (four hex digits, high bits dropped for code points above U+FFFF); ASCII
/// code points pass through unchanged. Useful for producing pure-ASCII output.
/// Params: s the source string.
/// Returns: the Unicode-escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape_unicode(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let cp = _code_point_at(s, i);
    if cp < 0x80 {
      let piece = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, piece);
    } else {
      result = string.str_concat(result, "\\u");
      let hex = _hex4(cp);
      result = string.str_concat(result, hex);
    };
    let b0 = (string.byte_at(s, i) as Int) & 0xFF;
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
    i = i + bl;
  };
  result
}
