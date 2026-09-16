// XIOM - String: Compat
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.compat

// Depends on: none

// ============================================================================
// Unicode compatibility normalization and decomposition. NOTE: current
// implementation lives in string.unicode stub - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.string.normalize;
use xiom.convert;

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// UTF-8 sequence length given the leading byte.
// Complexity: O(1).
fn _seq_len(b0: Int) -> Int {
  if b0 <= 0x7F {
    return 1;
  };
  if (b0 & 0xE0) == 0xC0 {
    return 2;
  };
  if (b0 & 0xF0) == 0xE0 {
    return 3;
  };
  if (b0 & 0xF8) == 0xF0 {
    return 4;
  };
  1
}

// UTF-8 byte length of a valid code point.
// Complexity: O(1).
fn _char_len(cp: Int) -> Int {
  if cp <= 0x7F {
    return 1;
  };
  if cp <= 0x7FF {
    return 2;
  };
  if cp <= 0xFFFF {
    return 3;
  };
  4
}

// Decodes the code point at byte `pos`, or -1 on malformed input.
// Complexity: O(1).
fn _decode_cp_at(s: Str, pos: Int, len: Int) -> Int {
  let b0 = _byte(s, pos);
  let n = _seq_len(b0);
  if pos + n > len {
    return -1;
  };
  if n == 1 {
    return b0;
  };
  if n == 2 {
    let b1 = _byte(s, pos + 1);
    if (b1 & 0xC0) != 0x80 {
      return -1;
    };
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if n == 3 {
    let b1 = _byte(s, pos + 1);
    let b2 = _byte(s, pos + 2);
    if (b1 & 0xC0) != 0x80 {
      return -1;
    };
    if (b2 & 0xC0) != 0x80 {
      return -1;
    };
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp >= 0xD800 && cp <= 0xDFFF {
      return -1;
    };
    return cp;
  };
  let b1 = _byte(s, pos + 1);
  let b2 = _byte(s, pos + 2);
  let b3 = _byte(s, pos + 3);
  if (b1 & 0xC0) != 0x80 {
    return -1;
  };
  if (b2 & 0xC0) != 0x80 {
    return -1;
  };
  if (b3 & 0xC0) != 0x80 {
    return -1;
  };
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

// String holding the UTF-8 encoding of the code point `cp`; "" when invalid.
// Complexity: O(1).
fn _cp_str(cp: Int) -> Str {
  if cp < 0 || cp > 0x10FFFF {
    return "";
  };
  var out = Vec[UInt8].new();
  let c_opt = convert.int_to_char(cp);
  match c_opt {
    Some(c) => {
      xiom.char.encode_utf8(c, &mut out);
    };
    None => {
      return "";
    };
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  unsafe {
    Str.from_cstring(out.data)
  }
}

// Single-level canonical decomposition of `cp`: (base, mark), or (cp, -1)
// when `cp` does not decompose. Covers the Latin-1 Supplement accented letters
// (A..y); all other code points pass through undecoded (documented subset).
// Complexity: O(1).
fn _decomp(cp: Int) -> (Int, Int) {
  if cp == 0xC0 { return (0x41, 0x300); };
  if cp == 0xC1 { return (0x41, 0x301); };
  if cp == 0xC2 { return (0x41, 0x302); };
  if cp == 0xC3 { return (0x41, 0x303); };
  if cp == 0xC4 { return (0x41, 0x308); };
  if cp == 0xC5 { return (0x41, 0x30A); };
  if cp == 0xC7 { return (0x43, 0x327); };
  if cp == 0xC8 { return (0x45, 0x300); };
  if cp == 0xC9 { return (0x45, 0x301); };
  if cp == 0xCA { return (0x45, 0x302); };
  if cp == 0xCB { return (0x45, 0x308); };
  if cp == 0xCC { return (0x49, 0x300); };
  if cp == 0xCD { return (0x49, 0x301); };
  if cp == 0xCE { return (0x49, 0x302); };
  if cp == 0xCF { return (0x49, 0x308); };
  if cp == 0xD1 { return (0x4E, 0x303); };
  if cp == 0xD2 { return (0x4F, 0x300); };
  if cp == 0xD3 { return (0x4F, 0x301); };
  if cp == 0xD4 { return (0x4F, 0x302); };
  if cp == 0xD5 { return (0x4F, 0x303); };
  if cp == 0xD6 { return (0x4F, 0x308); };
  if cp == 0xD9 { return (0x55, 0x300); };
  if cp == 0xDA { return (0x55, 0x301); };
  if cp == 0xDB { return (0x55, 0x302); };
  if cp == 0xDC { return (0x55, 0x308); };
  if cp == 0xDD { return (0x59, 0x301); };
  if cp == 0xE0 { return (0x61, 0x300); };
  if cp == 0xE1 { return (0x61, 0x301); };
  if cp == 0xE2 { return (0x61, 0x302); };
  if cp == 0xE3 { return (0x61, 0x303); };
  if cp == 0xE4 { return (0x61, 0x308); };
  if cp == 0xE5 { return (0x61, 0x30A); };
  if cp == 0xE7 { return (0x63, 0x327); };
  if cp == 0xE8 { return (0x65, 0x300); };
  if cp == 0xE9 { return (0x65, 0x301); };
  if cp == 0xEA { return (0x65, 0x302); };
  if cp == 0xEB { return (0x65, 0x308); };
  if cp == 0xEC { return (0x69, 0x300); };
  if cp == 0xED { return (0x69, 0x301); };
  if cp == 0xEE { return (0x69, 0x302); };
  if cp == 0xEF { return (0x69, 0x308); };
  if cp == 0xF1 { return (0x6E, 0x303); };
  if cp == 0xF2 { return (0x6F, 0x300); };
  if cp == 0xF3 { return (0x6F, 0x301); };
  if cp == 0xF4 { return (0x6F, 0x302); };
  if cp == 0xF5 { return (0x6F, 0x303); };
  if cp == 0xF6 { return (0x6F, 0x308); };
  if cp == 0xF9 { return (0x75, 0x300); };
  if cp == 0xFA { return (0x75, 0x301); };
  if cp == 0xFB { return (0x75, 0x302); };
  if cp == 0xFC { return (0x75, 0x308); };
  if cp == 0xFD { return (0x79, 0x301); };
  if cp == 0xFF { return (0x79, 0x308); };
  (cp, -1)
}

/// Compatibility-normalize `s` to NFKC. Delegates to the canonical NFKC
/// engine; see `xiom.string.normalize.unicode_normalize_nfkc` for the
/// documented coverage (fullwidth forms, ligatures, fractions, circled
/// numbers, ...).
/// Params: s the string to normalize.
/// Returns: the NFKC-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_compatibility_normalize(s: Str) -> Str {
  let r = normalize.unicode_normalize_nfkc(s);
  r
}

/// The canonical decomposition of each code point of `s`, one element per
/// input code point in source order. Code points that decompose into a base
/// letter plus a combining mark (the Latin-1 Supplement accented letters, see
/// the local table) yield that pair concatenated as a single string; all other
/// code points yield themselves.
/// Params: s the string to decompose.
/// Returns: a Vec[Str] with one element per code point of `s`.
/// Error case: none; malformed UTF-8 bytes pass through as single bytes.
/// Complexity: O(|s|).
pub fn unicode_decompose(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let cp = _decode_cp_at(s, i, len);
    if cp < 0 {
      let raw = string.str_slice(s, i, i + 1);
      out.push(raw);
      i = i + 1;
    } else {
      let d = _decomp(cp);
      if d.1 >= 0 {
        let base = _cp_str(d.0);
        let mark = _cp_str(d.1);
        let piece = string.str_concat(base, mark);
        out.push(piece);
      } else {
        let piece2 = _cp_str(cp);
        out.push(piece2);
      };
      i = i + _char_len(cp);
    };
  };
  out
}
