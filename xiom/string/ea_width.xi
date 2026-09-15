// XIOM - String: EA Width
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.ea_width

// Depends on: xiom.string, xiom.char

// ============================================================================
// East Asian display width of characters and strings (wcwidth-style). The
// table below is a compact representative subset of the Unicode East Asian
// Width property: control and zero-width/combining characters count 0,
// narrow/neutral/ambiguous count 1, and wide/fullwidth (CJK, Hangul, Hiragana,
// Katakana, fullwidth forms, emoji) count 2. Coverage is documented inline.
//
// NOTE (BUG 20): the classifier walks its table through a small recursive
// helper (one range per frame). A straight-line range-check chain gets
// SIMD-vectorized by the -O2 vectorizer into AVX-512 instructions that trap on
// CPUs without AVX-512 (0xC000001D); recursion keeps each frame tiny so the
// vectorizer never sees a long classification chain.
// ============================================================================

use xiom.string;
use xiom.char;

/// East Asian display width of `c`: 0 (control/combining/zero-width), 1
/// (narrow, neutral, ambiguous), or 2 (wide/fullwidth). Ambiguous characters
/// count 1 per the module contract. Unassigned codepoints fall back to 1.
/// Params: c the character to measure.
/// Returns: 0, 1 or 2 display cells.
/// Error case: none.
/// Complexity: O(1).
pub fn unicode_ea_width(c: Char) -> Int
  ensures: result >= 0
{
  _ea_w(to_int_from_char(c))
}

/// Display width of `s`, summing the per-character East Asian widths. This is
/// the width the string would occupy in a monospaced terminal or table cell.
/// Params: s the string to measure.
/// Returns: total display width in cells (>= 0).
/// Error case: none; malformed UTF-8 bytes are counted as width 1.
/// Complexity: O(|s|).
pub fn unicode_display_width(s: Str) -> Int
  ensures: result >= 0
{
  let len = string.str_len(s);
  var total: Int = 0;
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      total = total + 1;
      i = i + 1;
    } else {
      let cw = _ea_w(cp);
      total = total + cw;
      let bl = _char_len(cp);
      i = i + bl;
    };
  }
  total
}

/// Truncate `s` so its display width does not exceed `max_width` cells.
/// Characters are never split: the result ends on a character boundary, and a
/// wide character that would overflow the limit is dropped entirely.
/// Params: s the string to truncate; max_width the maximum display width.
/// Returns: the longest prefix of `s` whose display width is <= max_width.
/// Error case: max_width <= 0 yields ""; malformed bytes pass through whole.
/// Complexity: O(|s|).
pub fn unicode_truncate_display(s: Str, max_width: Int) -> Str {
  if max_width <= 0 {
    return "";
  };
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var w: Int = 0;
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let cw = _ea_w(cp);
    if w + cw > max_width {
      break;
    };
    _push_cp(&mut out, cp);
    w = w + cw;
    let bl = _char_len(cp);
    i = i + bl;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

// -- Private helpers ---------------------------------------------------------

/// East Asian Width of one codepoint; 1 when unmapped.
fn _ea_w(cp: Int) -> Int {
  _ea_r(cp, 0)
}

/// One range per recursion frame (see header note on BUG 20).
fn _ea_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 0 && cp <= 0x1F { return 0; };
  };
  if i == 1 {
    if cp >= 0x7F && cp <= 0x9F { return 0; };
  };
  if i == 2 {
    if cp == 0x00AD { return 0; };
  };
  if i == 3 {
    if cp >= 0x0300 && cp <= 0x036F { return 0; };
  };
  if i == 4 {
    if cp >= 0x1AB0 && cp <= 0x1AFF { return 0; };
  };
  if i == 5 {
    if cp >= 0x1DC0 && cp <= 0x1DFF { return 0; };
  };
  if i == 6 {
    if cp >= 0x20D0 && cp <= 0x20FF { return 0; };
  };
  if i == 7 {
    if cp >= 0xFE20 && cp <= 0xFE2F { return 0; };
  };
  if i == 8 {
    if cp >= 0xFE00 && cp <= 0xFE0F { return 0; };
  };
  if i == 9 {
    if cp >= 0xE0100 && cp <= 0xE01EF { return 0; };
  };
  if i == 10 {
    if cp == 0x200B || cp == 0x200C || cp == 0x200D { return 0; };
  };
  if i == 11 {
    if cp == 0xFEFF { return 0; };
  };
  if i == 12 {
    if cp >= 0x1160 && cp <= 0x11FF { return 0; };
  };
  if i == 13 {
    if cp >= 0xD7B0 && cp <= 0xD7FF { return 0; };
  };
  if i == 14 {
    if cp >= 0x1100 && cp <= 0x115F { return 2; };
  };
  if i == 15 {
    if cp >= 0x2E80 && cp <= 0x2EFF { return 2; };
  };
  if i == 16 {
    if cp >= 0x2F00 && cp <= 0x2FDF { return 2; };
  };
  if i == 17 {
    if cp >= 0x3000 && cp <= 0x303F { return 2; };
  };
  if i == 18 {
    if cp >= 0x3040 && cp <= 0x309F { return 2; };
  };
  if i == 19 {
    if cp >= 0x30A0 && cp <= 0x30FF { return 2; };
  };
  if i == 20 {
    if cp >= 0x3100 && cp <= 0x312F { return 2; };
  };
  if i == 21 {
    if cp >= 0x3130 && cp <= 0x318F { return 2; };
  };
  if i == 22 {
    if cp >= 0x31F0 && cp <= 0x31FF { return 2; };
  };
  if i == 23 {
    if cp >= 0x3200 && cp <= 0x33FF { return 2; };
  };
  if i == 24 {
    if cp >= 0x3400 && cp <= 0x4DBF { return 2; };
  };
  if i == 25 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return 2; };
  };
  if i == 26 {
    if cp >= 0xA000 && cp <= 0xA4CF { return 2; };
  };
  if i == 27 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return 2; };
  };
  if i == 28 {
    if cp >= 0xF900 && cp <= 0xFAFF { return 2; };
  };
  if i == 29 {
    if cp >= 0xFE30 && cp <= 0xFE4F { return 2; };
  };
  if i == 30 {
    if cp >= 0xFF00 && cp <= 0xFF60 { return 2; };
  };
  if i == 31 {
    if cp >= 0xFFE0 && cp <= 0xFFE6 { return 2; };
  };
  if i == 32 {
    if cp >= 0x1F300 && cp <= 0x1FAFF { return 2; };
  };
  if i == 33 {
    if cp >= 0x20000 && cp <= 0x2FFFD { return 2; };
  };
  if i == 34 {
    if cp >= 0x30000 && cp <= 0x3FFFD { return 2; };
  };
  if i == 35 {
    if cp < 0 { return 0; };
  };
  if i < 35 {
    return _ea_r(cp, i + 1);
  };
  1
}

/// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
fn _byte_at(s: Str, pos: Int) -> Int {
  let v = string.byte_at(s, pos) as Int;
  v & 0xFF
}

/// UTF-8 sequence length given the leading byte.
fn _seq_len(b0: Int) -> Int {
  if b0 <= 0x7F { return 1; };
  if (b0 & 0xE0) == 0xC0 { return 2; };
  if (b0 & 0xF0) == 0xE0 { return 3; };
  if (b0 & 0xF8) == 0xF0 { return 4; };
  1
}

/// UTF-8 byte length of a valid codepoint.
fn _char_len(cp: Int) -> Int {
  if cp <= 0x7F { return 1; };
  if cp <= 0x7FF { return 2; };
  if cp <= 0xFFFF { return 3; };
  4
}

/// Decode the codepoint at byte `pos`, or -1 on malformed input.
fn _decode(s: Str, pos: Int, len: Int) -> Int {
  let b0 = _byte_at(s, pos);
  let n = _seq_len(b0);
  if pos + n > len { return -1; };
  if n == 1 { return b0; };
  if n == 2 {
    let b1 = _byte_at(s, pos + 1);
    if (b1 & 0xC0) != 0x80 { return -1; };
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if n == 3 {
    let b1 = _byte_at(s, pos + 1);
    let b2 = _byte_at(s, pos + 2);
    if (b1 & 0xC0) != 0x80 { return -1; };
    if (b2 & 0xC0) != 0x80 { return -1; };
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp >= 0xD800 && cp <= 0xDFFF { return -1; };
    return cp;
  };
  let b1 = _byte_at(s, pos + 1);
  let b2 = _byte_at(s, pos + 2);
  let b3 = _byte_at(s, pos + 3);
  if (b1 & 0xC0) != 0x80 { return -1; };
  if (b2 & 0xC0) != 0x80 { return -1; };
  if (b3 & 0xC0) != 0x80 { return -1; };
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

/// Append the UTF-8 encoding of a codepoint to `out`.
fn _push_cp(out: &mut Vec[UInt8], cp: Int) {
  if cp < 0 || cp > 0x10FFFF {
    return;
  };
  char.encode_utf8(to_char(cp), out);
}

/// Null-terminate `buf` and wrap it as a Str. Callers must have pushed the 0.
fn _bytes_to_str(buf: &Vec[UInt8]) -> Str
  requires: buf.len() >= 1
{
  unsafe {
    Str.from_cstring(buf.data)
  }
}
