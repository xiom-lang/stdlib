// XIOM - String: Casefold
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.casefold

// Depends on: xiom.string, xiom.char

// ============================================================================
// Unicode case folding for case-insensitive matching, plus a fast ASCII-only
// variant. Coverage: full 1:1 lowercase mappings for ASCII, Latin-1, Latin
// Extended-A, Greek and Cyrillic, plus the well-known multi-char folds
// (U+00DF/ss and U+1E9E/SS -> "ss", U+0130/I -> "i" + combining dot). Other
// scripts are passed through unchanged; see the inline TODO.
// ============================================================================

use xiom.string;
use xiom.char;

/// Full Unicode case folding of `s` for case-insensitive comparison. ASCII,
/// Latin-1, Latin Extended-A, Greek and Cyrillic uppercase letters are folded
/// to their lowercase forms; the sharp s (ss/SS) folds to "ss" and dotted
/// capital I (I) folds to "i" + combining dot, matching the Unicode full
/// case-folding mapping for those characters.
/// Params: s the string to fold.
/// Returns: the case-folded string.
/// Error case: none; malformed UTF-8 bytes pass through unchanged.
/// Complexity: O(|s|).
pub fn str_casefold(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    if cp == 0xDF || cp == 0x1E9E {
      _push_cp(&mut out, 0x73);
      _push_cp(&mut out, 0x73);
    } elif cp == 0x130 {
      _push_cp(&mut out, 0x69);
      _push_cp(&mut out, 0x307);
    } else {
      _push_cp(&mut out, _lower_cp(cp));
    };
    i = i + _char_len(cp);
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// ASCII-only case folding of `s`: 'A'..'Z' become lowercase, every other
/// byte is copied verbatim. No Unicode tables are consulted.
/// Params: s the string to fold.
/// Returns: the ASCII-folded string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_casefold_ascii(s: Str) -> Str {
  let len = string.str_len(s);
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      _push_byte(&mut out, _byte_at(s, i));
      i = i + 1;
      continue;
    };
    var lc = cp;
    if cp >= 65 && cp <= 90 {
      lc = cp + 32;
    };
    _push_cp(&mut out, lc);
    i = i + _char_len(cp);
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

// -- Private helpers ---------------------------------------------------------

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

/// Append a raw byte to `out`.
fn _push_byte(out: &mut Vec[UInt8], b: Int) {
  if b >= 0 && b <= 0xFF {
    out.push(b as UInt8);
  };
}

/// Null-terminate `buf` and wrap it as a Str. Callers must have pushed the 0.
fn _bytes_to_str(buf: &Vec[UInt8]) -> Str
  requires: buf.len() >= 1
{
  unsafe {
    Str.from_cstring(buf.data)
  }
}

/// Simple 1:1 lowercase mapping of one codepoint, itself when none exists.
/// Covers ASCII, Latin-1, Latin Extended-A, Greek and Cyrillic ranges.
/// NOTE (BUG 20): the mapping walks its ranges through a small recursive
/// helper; a straight-line range-check chain would be SIMD-vectorized by the
/// -O2 vectorizer into AVX-512 instructions that trap on CPUs without
/// AVX-512 (0xC000001D).
fn _lower_cp(cp: Int) -> Int {
  _lower_r(cp, 0)
}

fn _lower_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp >= 65 && cp <= 90 { return cp + 32; };
  };
  if i == 1 {
    if cp >= 0xC0 && cp <= 0xD6 { return cp + 0x20; };
  };
  if i == 2 {
    if cp >= 0xD8 && cp <= 0xDE { return cp + 0x20; };
  };
  if i == 3 {
    if cp >= 0x391 && cp <= 0x3A1 { return cp + 0x20; };
  };
  if i == 4 {
    if cp >= 0x3A3 && cp <= 0x3AB { return cp + 0x20; };
  };
  if i == 5 {
    if cp >= 0x400 && cp <= 0x40F { return cp + 0x50; };
  };
  if i == 6 {
    if cp >= 0x410 && cp <= 0x42F { return cp + 0x20; };
  };
  if i == 7 {
    if cp >= 0x100 && cp <= 0x12F && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 8 {
    if cp >= 0x132 && cp <= 0x137 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 9 {
    if cp >= 0x139 && cp <= 0x148 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 10 {
    if cp >= 0x14A && cp <= 0x177 && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 11 {
    if cp >= 0x179 && cp <= 0x17D && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 12 {
    if cp == 0x1E9E { return 0xDF; };
  };
  if i == 13 {
    if cp >= 0x1E00 && cp <= 0x1EFF && (cp & 1) == 0 { return cp + 1; };
  };
  if i == 14 {
    if cp == 0x178 { return 0xFF; };
  };
  if i < 14 {
    return _lower_r(cp, i + 1);
  };
  cp
}
