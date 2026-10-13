// XIOM - String: Escape
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.escape

// Depends on: none

// ============================================================================
// Escape special characters in a string for safe embedding in source or data.
// NOTE: current implementation lives in string.str_escape - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Wave 125: raw byte access over a cached (base, len) view (the wave-111
// pattern): xiom.byte_at re-scans with strnlen per call, so byte-stepped
// loops were quadratic. Callers bounds-check against the cached length.
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// Decodes the full UTF-8 character starting at byte `pos` over a cached
/// (base, len) view and returns its code point. The runtime char reader only
/// exposes the leading byte, so the sequence is decoded from the raw bytes.
/// Invalid continuation bytes are treated conservatively as the leading byte
/// value. Out-of-range positions read as 0 exactly like the old
/// `string.byte_at` accessor. Complexity: O(1).
fn _code_point_at(base: *UInt8, len: Int, pos: Int) -> Int {
  var b0 = 0;
  if pos >= 0 && pos < len {
    b0 = (_raw_byte(base, pos) as Int) & 0xFF;
  };
  if b0 <= 0x7F {
    return b0;
  };
  var c1 = 0;
  if pos + 1 >= 0 && pos + 1 < len {
    c1 = (_raw_byte(base, pos + 1) as Int) & 0xFF;
  };
  if (b0 & 0xE0) == 0xC0 {
    return ((b0 & 0x1F) << 6) | (c1 & 0x3F);
  };
  var c2 = 0;
  if pos + 2 >= 0 && pos + 2 < len {
    c2 = (_raw_byte(base, pos + 2) as Int) & 0xFF;
  };
  if (b0 & 0xF0) == 0xE0 {
    return ((b0 & 0x0F) << 12) | ((c1 & 0x3F) << 6) | (c2 & 0x3F);
  };
  var c3 = 0;
  if pos + 3 >= 0 && pos + 3 < len {
    c3 = (_raw_byte(base, pos + 3) as Int) & 0xFF;
  };
  ((b0 & 0x07) << 18) | ((c1 & 0x3F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F)
}

/// Escapes the control and special characters of `s` (\n, \t, \", \\, \r) so
/// the result can be embedded safely in source or data. All other characters
/// pass through unchanged.
/// Params: s the source string.
/// Returns: the escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape(s: Str) -> Str
  ensures: s.len() == 0 => result.len() == 0
{
  string.str_escape(s)
}

/// Interprets the escape sequences in `s` (\n, \t, \", \\, \r) back into
/// literal characters. Unrecognised escapes are left unchanged, so
/// str_escape then str_unescape is a faithful round-trip.
/// Params: s the source string.
/// Returns: the unescaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_unescape(s: Str) -> Str
  ensures: s.len() == 0 => result.len() == 0
{
  string.str_unescape(s)
}

// Renders a hex digit 0..15 as its lowercase ASCII byte.
// Complexity: O(1).
fn _hex_digit(v: Int) -> UInt8 {
  if v < 10 {
    return (48 + v) as UInt8;
  }
  (87 + v) as UInt8
}

/// Escapes every non-ASCII byte of `s` as a lowercase \xNN sequence; ASCII
/// bytes pass through unchanged. Useful for producing pure-ASCII output.
/// Wave 125: builds the result in one Vec pass (the previous
/// slice+concat-per-byte loop was quadratic in allocations).
/// Params: s the source string.
/// Returns: the ASCII-escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape_ascii(s: Str) -> Str
  ensures: s.len() == 0 => result.len() == 0
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = string.str_len(s);
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let b = (_raw_byte(base, i) as Int) & 0xFF;
    if b < 0x80 {
      out.push(b as UInt8);
    } else {
      out.push(92);  // backslash
      out.push(120); // 'x'
      out.push(_hex_digit((b >> 4) & 0x0F));
      out.push(_hex_digit(b & 0x0F));
    };
    i = i + 1;
  };
  Str::from_utf8(out)
}

/// Escapes every non-ASCII code point of `s` as a lowercase \uNNNN sequence
/// (four hex digits, high bits dropped for code points above U+FFFF); ASCII
/// code points pass through unchanged. Useful for producing pure-ASCII output.
/// Wave 125: builds the result in one Vec pass (the previous
/// slice+concat-per-char loop was quadratic in allocations).
/// Params: s the source string.
/// Returns: the Unicode-escaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_escape_unicode(s: Str) -> Str
  ensures: s.len() == 0 => result.len() == 0
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = string.str_len(s);
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    let cp = _code_point_at(base, len, i);
    if cp < 0x80 {
      out.push(_raw_byte(base, i));
    } else {
      out.push(92);  // backslash
      out.push(117); // 'u'
      var shift: Int = 12;
      while shift >= 0 {
        out.push(_hex_digit((cp >> shift) & 0x0F));
        shift = shift - 4;
      };
    };
    let b0 = (_raw_byte(base, i) as Int) & 0xFF;
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
  Str::from_utf8(out)
}
