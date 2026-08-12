// XIOM - String: Normalize
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.normalize

// Depends on: xiom.string, xiom.char

// ============================================================================
// Unicode normalization (NFC/NFD/NFKC/NFKD) and ASCII folding.
//
// COVERAGE (documented honestly): the canonical decomposition/composition
// tables cover ASCII, the Latin-1 Supplement accented forms, the decomposable
// Latin Extended-A accented pairs, the standard Greek accented vowels, and the
// Cyrillic diaeresis/grave forms (Ѐ/Ё/ѐ/ё). Compatibility decompositions cover
// fullwidth forms, NBSP, superscript/subscript digits, fractions, the Latin
// ligatures (ff/fi/fl/ffi/ffl, IJ/ij), circled numbers/letters, ideographic
// space, and a few symbol-to-ASCII mappings. Everything else passes through
// unchanged.
// TODO(unicode-data): full table for the remaining Unicode ranges (Greek
// polytonic beyond the basics, Latin Extended-B and beyond, CJK compatibility,
// mathematical alphanumerics, ...).
// ============================================================================

use xiom.string;
use xiom.char;

/// Normalize `s` to NFC (canonical composition): characters are canonically
/// decomposed, canonically reordered, then recomposed to their precomposed
/// forms where one exists (e.g. "e\u0301" -> "é"). Characters outside the
/// covered table pass through unchanged.
/// Params: s the string to normalize.
/// Returns: the NFC-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfc(s: Str) -> Str {
  var cps = Vec[Int].new();
  _walk_decomp(s, &mut cps);
  _reorder(&mut cps);
  _recompose(&mut cps);
  _build(&cps)
}

/// Normalize `s` to NFD (canonical decomposition): precomposed characters are
/// decomposed into their base letter plus combining marks, and combining marks
/// are canonically reordered by combining class (e.g. "é" -> "e" + U+0301).
/// Params: s the string to normalize.
/// Returns: the NFD-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfd(s: Str) -> Str {
  var cps = Vec[Int].new();
  _walk_decomp(s, &mut cps);
  _reorder(&mut cps);
  _build(&cps)
}

/// Normalize `s` to NFKC (compatibility composition): NFKD then NFC-style
/// recomposition. Compatibility characters such as ligatures, superscripts and
/// fullwidth forms are decomposed first (e.g. "①" -> "1", "ｦ" -> "ｦ"... 1:1
/// fullwidth forms fold to ASCII). See the module header for the covered set.
/// Params: s the string to normalize.
/// Returns: the NFKC-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfkc(s: Str) -> Str {
  var cps = Vec[Int].new();
  _walk_compat(s, &mut cps);
  _reorder(&mut cps);
  _recompose(&mut cps);
  _build(&cps)
}

/// Normalize `s` to NFKD (compatibility decomposition): like NFD plus the
/// compatibility mappings (e.g. "ﬁ" -> "fi", "½" -> "1/2", "⑧" -> "8").
/// Params: s the string to normalize.
/// Returns: the NFKD-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfkd(s: Str) -> Str {
  var cps = Vec[Int].new();
  _walk_compat(s, &mut cps);
  _reorder(&mut cps);
  _build(&cps)
}

/// Fold `s` to plain ASCII, removing accents and combining marks. Accented
/// Latin letters reduce to their base letter ("café" -> "cafe"); common
/// non-ASCII letters without an ASCII base are transliterated via a small map
/// ("ø" -> "o", "ß" -> "s", "æ" -> "a"). Characters with no ASCII
/// transliteration are dropped. See the module header for the covered set.
/// Params: s the string to fold.
/// Returns: an ASCII-only string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn str_normalize_ascii(s: Str) -> Str {
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
    let base = _ascii_base(cp);
    var mapped: Int = -1;
    if base <= 0x7F {
      mapped = base;
    } else {
      mapped = _ascii_map(base);
    };
    if mapped >= 0 {
      _push_cp(&mut out, mapped);
    };
    i = i + _char_len(cp);
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

// ── Private helpers ─────────────────────────────────────────────────────────

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

/// Append a codepoint to a byte buffer. Sentinel 0x110000..0x1100FF carries a
/// raw byte (malformed-input passthrough); codepoints outside 0..0x10FFFF are
/// ignored.
fn _push_cp(out: &mut Vec[UInt8], cp: Int) {
  if cp >= 0x110000 && cp <= 0x1100FF {
    out.push((cp - 0x110000) as UInt8);
    return;
  };
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

/// Build a string from a codepoint vector.
fn _build(cps: &Vec[Int]) -> Str {
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < cps.len() {
    _push_cp(&mut out, cps[i]);
    i = i + 1;
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  _bytes_to_str(&out)
}

/// Canonical combining class (subset covering the marks used by the tables).
fn _ccc(cp: Int) -> Int {
  if cp >= 0x300 && cp <= 0x30C { return 230; };
  if cp == 0x315 { return 232; };
  if cp == 0x31B { return 216; };
  if cp == 0x31C { return 202; };
  if cp >= 0x31D && cp <= 0x320 { return 220; };
  if cp >= 0x321 && cp <= 0x322 { return 202; };
  if cp >= 0x323 && cp <= 0x326 { return 220; };
  if cp == 0x327 || cp == 0x328 { return 202; };
  if cp >= 0x329 && cp <= 0x33D { return 220; };
  0
}

/// Canonical ordering: insertion-sort combining marks by combining class,
/// stably, within each base-plus-marks run.
fn _reorder(cps: &mut Vec[Int]) {
  let n = cps.len();
  var i: Int = 1;
  while i < n {
    let ci = _ccc(cps[i]);
    if ci > 0 {
      var j = i;
      while j > 0 {
        let cj = _ccc(cps[j - 1]);
        if cj > ci {
          let t = cps[j];
          cps[j] = cps[j - 1];
          cps[j - 1] = t;
          j = j - 1;
        } else {
          break;
        };
      };
    };
    i = i + 1;
  }
}

/// NFC-style recomposition in place.
fn _recompose(cps: &mut Vec[Int]) {
  var out = Vec[Int].new();
  var i: Int = 0;
  let n = cps.len();
  var last_starter: Int = -1;
  var last_pos: Int = -1;
  while i < n {
    let cp = cps[i];
    let cc = _ccc(cp);
    if cc > 0 {
      if last_starter >= 0 {
        let comp = _compose(last_starter, cp);
        if comp >= 0 {
          out[last_pos] = comp;
          last_starter = comp;
          i = i + 1;
          continue;
        };
      };
      out.push(cp);
    } else {
      out.push(cp);
      last_starter = cp;
      last_pos = out.len() - 1;
    };
    i = i + 1;
  }
  cps.clear();
  var k: Int = 0;
  while k < out.len() {
    cps.push(out[k]);
    k = k + 1;
  }
}

/// Recursively decompose a codepoint into base + marks, appending to `out`.
fn _decompose_all(cp: Int, out: &mut Vec[Int]) {
  let d = _decomp(cp);
  if d.1 < 0 {
    out.push(cp);
    return;
  };
  _decompose_all(d.0, out);
  out.push(d.1);
}

/// Walk `s`, canonical-decomposing every character into `out`.
fn _walk_decomp(s: Str, out: &mut Vec[Int]) {
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      out.push(0x110000 + _byte_at(s, i));
      i = i + 1;
    } else {
      let d = _decomp(cp);
      if d.1 >= 0 {
        _decompose_all(d.0, out);
        out.push(d.1);
      } else {
        out.push(cp);
      };
      i = i + _char_len(cp);
    };
  }
}

/// Walk `s`, compatibility-decomposing every character into `out`.
fn _walk_compat(s: Str, out: &mut Vec[Int]) {
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let cp = _decode(s, i, len);
    if cp < 0 {
      out.push(0x110000 + _byte_at(s, i));
      i = i + 1;
    } else {
      _compat_push(cp, out);
      i = i + _char_len(cp);
    };
  }
}

/// Single-character compatibility mapping, -1 when none.
fn _compat_char(cp: Int) -> Int {
  if cp >= 0xFF01 && cp <= 0xFF5E { return cp - 0xFEE0; };
  if cp == 0x00A0 { return 0x20; };
  if cp == 0x3000 { return 0x20; };
  if cp == 0x00B9 { return 0x31; };
  if cp == 0x00B2 { return 0x32; };
  if cp == 0x00B3 { return 0x33; };
  if cp == 0x2070 { return 0x30; };
  if cp >= 0x2074 && cp <= 0x2079 { return cp - 0x2074 + 0x34; };
  if cp >= 0x2080 && cp <= 0x2089 { return cp - 0x2080 + 0x30; };
  if cp >= 0x2460 && cp <= 0x2468 { return cp - 0x2460 + 0x31; };
  if cp >= 0x24B6 && cp <= 0x24CF { return cp - 0x24B6 + 0x41; };
  if cp >= 0x24D0 && cp <= 0x24E9 { return cp - 0x24D0 + 0x61; };
  -1
}

/// Multi-character compatibility decomposition: append codepoints to `out`.
fn _compat_push(cp: Int, out: &mut Vec[Int]) {
  let m = _compat_char(cp);
  if m >= 0 {
    out.push(m);
    return;
  };
  if cp == 0xFB00 { out.push(0x66); out.push(0x66); return; };
  if cp == 0xFB01 { out.push(0x66); out.push(0x69); return; };
  if cp == 0xFB02 { out.push(0x66); out.push(0x6C); return; };
  if cp == 0xFB03 { out.push(0x66); out.push(0x66); out.push(0x69); return; };
  if cp == 0xFB04 { out.push(0x66); out.push(0x66); out.push(0x6C); return; };
  if cp == 0x132 { out.push(0x49); out.push(0x4A); return; };
  if cp == 0x133 { out.push(0x69); out.push(0x6A); return; };
  if cp == 0xBC { out.push(0x31); out.push(0x2F); out.push(0x34); return; };
  if cp == 0xBD { out.push(0x31); out.push(0x2F); out.push(0x32); return; };
  if cp == 0xBE { out.push(0x33); out.push(0x2F); out.push(0x34); return; };
  if cp == 0x2122 { out.push(0x54); out.push(0x4D); return; };
  if cp == 0x2121 { out.push(0x54); out.push(0x45); out.push(0x4C); return; };
  if cp == 0x2116 { out.push(0x4E); out.push(0x6F); return; };
  let d = _decomp(cp);
  if d.1 >= 0 {
    _decompose_all(d.0, out);
    out.push(d.1);
    return;
  };
  out.push(cp);
}

/// Reduce a codepoint to its canonical base (recursively).
fn _ascii_base(cp: Int) -> Int {
  let d = _decomp(cp);
  if d.1 >= 0 {
    return _ascii_base(d.0);
  };
  cp
}

/// Small transliteration map for non-decomposable non-ASCII letters.
fn _ascii_map(cp: Int) -> Int {
  if cp == 0xD8 { return 0x4F; };
  if cp == 0xF8 { return 0x6F; };
  if cp == 0xC6 { return 0x41; };
  if cp == 0xE6 { return 0x61; };
  if cp == 0x152 { return 0x4F; };
  if cp == 0x153 { return 0x6F; };
  if cp == 0xDF { return 0x73; };
  if cp == 0x1E9E { return 0x73; };
  if cp == 0xDE { return 0x74; };
  if cp == 0xFE { return 0x74; };
  if cp == 0xD0 { return 0x64; };
  if cp == 0xF0 { return 0x64; };
  if cp == 0x141 { return 0x4C; };
  if cp == 0x142 { return 0x6C; };
  if cp == 0x126 { return 0x48; };
  if cp == 0x127 { return 0x68; };
  if cp == 0x17F { return 0x73; };
  if cp == 0x131 { return 0x69; };
  if cp == 0xB5 { return 0x75; };
  if cp == 0xBA { return 0x6F; };
  if cp == 0xAA { return 0x61; };
  if cp == 0xB4 { return 0x27; };
  if cp == 0xA8 { return 0x22; };
  if cp == 0xAF { return 0x2D; };
  if cp == 0xB8 { return 0x2C; };
  if cp == 0x2018 { return 0x27; };
  if cp == 0x2019 { return 0x27; };
  if cp == 0x201C { return 0x22; };
  if cp == 0x201D { return 0x22; };
  if cp == 0x2013 { return 0x2D; };
  if cp == 0x2014 { return 0x2D; };
  if cp == 0x2022 { return 0x2A; };
  -1
}

/// Canonical composition of `a` + `b` (combining mark), -1 when not composable.
/// Inverse of `_decomp` for the covered table.
fn _compose(a: Int, b: Int) -> Int {
  if b == 0x300 {
    if a == 0x41 { return 0xC0; };
    if a == 0x61 { return 0xE0; };
    if a == 0x45 { return 0xC8; };
    if a == 0x65 { return 0xE8; };
    if a == 0x49 { return 0xCC; };
    if a == 0x69 { return 0xEC; };
    if a == 0x4F { return 0xD2; };
    if a == 0x6F { return 0xF2; };
    if a == 0x55 { return 0xD9; };
    if a == 0x75 { return 0xF9; };
    if a == 0x415 { return 0x400; };
    if a == 0x435 { return 0x450; };
    return -1;
  };
  if b == 0x301 {
    if a == 0x41 { return 0xC1; };
    if a == 0x61 { return 0xE1; };
    if a == 0x43 { return 0x106; };
    if a == 0x63 { return 0x107; };
    if a == 0x45 { return 0xC9; };
    if a == 0x65 { return 0xE9; };
    if a == 0x49 { return 0xCD; };
    if a == 0x69 { return 0xED; };
    if a == 0x4C { return 0x139; };
    if a == 0x6C { return 0x13A; };
    if a == 0x4E { return 0x143; };
    if a == 0x6E { return 0x144; };
    if a == 0x4F { return 0xD3; };
    if a == 0x6F { return 0xF3; };
    if a == 0x52 { return 0x154; };
    if a == 0x72 { return 0x155; };
    if a == 0x53 { return 0x15A; };
    if a == 0x73 { return 0x15B; };
    if a == 0x55 { return 0xDA; };
    if a == 0x75 { return 0xFA; };
    if a == 0x59 { return 0xDD; };
    if a == 0x79 { return 0xFD; };
    if a == 0x5A { return 0x179; };
    if a == 0x7A { return 0x17A; };
    if a == 0x391 { return 0x386; };
    if a == 0x395 { return 0x388; };
    if a == 0x397 { return 0x389; };
    if a == 0x399 { return 0x38A; };
    if a == 0x39F { return 0x38C; };
    if a == 0x3A5 { return 0x38E; };
    if a == 0x3A9 { return 0x38F; };
    if a == 0x3B1 { return 0x3AC; };
    if a == 0x3B5 { return 0x3AD; };
    if a == 0x3B7 { return 0x3AE; };
    if a == 0x3B9 { return 0x3AF; };
    if a == 0x3BF { return 0x3CC; };
    if a == 0x3C5 { return 0x3CD; };
    if a == 0x3C9 { return 0x3CE; };
    if a == 0x3CA { return 0x390; };
    if a == 0x3CB { return 0x3B0; };
    return -1;
  };
  if b == 0x302 {
    if a == 0x41 { return 0xC2; };
    if a == 0x61 { return 0xE2; };
    if a == 0x43 { return 0x108; };
    if a == 0x63 { return 0x109; };
    if a == 0x45 { return 0xCA; };
    if a == 0x65 { return 0xEA; };
    if a == 0x47 { return 0x11C; };
    if a == 0x67 { return 0x11D; };
    if a == 0x48 { return 0x124; };
    if a == 0x68 { return 0x125; };
    if a == 0x49 { return 0xCE; };
    if a == 0x69 { return 0xEE; };
    if a == 0x4A { return 0x134; };
    if a == 0x6A { return 0x135; };
    if a == 0x4F { return 0xD4; };
    if a == 0x6F { return 0xF4; };
    if a == 0x53 { return 0x15C; };
    if a == 0x73 { return 0x15D; };
    if a == 0x55 { return 0xDB; };
    if a == 0x75 { return 0xFB; };
    if a == 0x57 { return 0x174; };
    if a == 0x77 { return 0x175; };
    if a == 0x59 { return 0x176; };
    if a == 0x79 { return 0x177; };
    return -1;
  };
  if b == 0x303 {
    if a == 0x41 { return 0xC3; };
    if a == 0x61 { return 0xE3; };
    if a == 0x49 { return 0x128; };
    if a == 0x69 { return 0x129; };
    if a == 0x4E { return 0xD1; };
    if a == 0x6E { return 0xF1; };
    if a == 0x4F { return 0xD5; };
    if a == 0x6F { return 0xF5; };
    if a == 0x55 { return 0x168; };
    if a == 0x75 { return 0x169; };
    return -1;
  };
  if b == 0x304 {
    if a == 0x41 { return 0x100; };
    if a == 0x61 { return 0x101; };
    if a == 0x45 { return 0x112; };
    if a == 0x65 { return 0x113; };
    if a == 0x49 { return 0x12A; };
    if a == 0x69 { return 0x12B; };
    if a == 0x4F { return 0x14C; };
    if a == 0x6F { return 0x14D; };
    if a == 0x55 { return 0x16A; };
    if a == 0x75 { return 0x16B; };
    return -1;
  };
  if b == 0x306 {
    if a == 0x41 { return 0x102; };
    if a == 0x61 { return 0x103; };
    if a == 0x47 { return 0x11E; };
    if a == 0x67 { return 0x11F; };
    if a == 0x49 { return 0x12C; };
    if a == 0x69 { return 0x12D; };
    if a == 0x4F { return 0x14E; };
    if a == 0x6F { return 0x14F; };
    if a == 0x55 { return 0x16C; };
    if a == 0x75 { return 0x16D; };
    return -1;
  };
  if b == 0x307 {
    if a == 0x43 { return 0x10A; };
    if a == 0x63 { return 0x10B; };
    if a == 0x45 { return 0x116; };
    if a == 0x65 { return 0x117; };
    if a == 0x47 { return 0x120; };
    if a == 0x67 { return 0x121; };
    if a == 0x49 { return 0x130; };
    if a == 0x5A { return 0x17B; };
    if a == 0x7A { return 0x17C; };
    return -1;
  };
  if b == 0x308 {
    if a == 0x41 { return 0xC4; };
    if a == 0x61 { return 0xE4; };
    if a == 0x45 { return 0xCB; };
    if a == 0x65 { return 0xEB; };
    if a == 0x49 { return 0xCF; };
    if a == 0x69 { return 0xEF; };
    if a == 0x4F { return 0xD6; };
    if a == 0x6F { return 0xF6; };
    if a == 0x55 { return 0xDC; };
    if a == 0x75 { return 0xFC; };
    if a == 0x59 { return 0x178; };
    if a == 0x79 { return 0xFF; };
    if a == 0x399 { return 0x3AA; };
    if a == 0x3A5 { return 0x3AB; };
    if a == 0x3B9 { return 0x3CA; };
    if a == 0x3C5 { return 0x3CB; };
    if a == 0x415 { return 0x401; };
    if a == 0x435 { return 0x451; };
    return -1;
  };
  if b == 0x30A {
    if a == 0x41 { return 0xC5; };
    if a == 0x61 { return 0xE5; };
    if a == 0x55 { return 0x16E; };
    if a == 0x75 { return 0x16F; };
    return -1;
  };
  if b == 0x30B {
    if a == 0x4F { return 0x150; };
    if a == 0x6F { return 0x151; };
    if a == 0x55 { return 0x170; };
    if a == 0x75 { return 0x171; };
    return -1;
  };
  if b == 0x30C {
    if a == 0x43 { return 0x10C; };
    if a == 0x63 { return 0x10D; };
    if a == 0x44 { return 0x10E; };
    if a == 0x64 { return 0x10F; };
    if a == 0x45 { return 0x11A; };
    if a == 0x65 { return 0x11B; };
    if a == 0x4C { return 0x13D; };
    if a == 0x6C { return 0x13E; };
    if a == 0x4E { return 0x147; };
    if a == 0x6E { return 0x148; };
    if a == 0x52 { return 0x158; };
    if a == 0x72 { return 0x159; };
    if a == 0x53 { return 0x160; };
    if a == 0x73 { return 0x161; };
    if a == 0x54 { return 0x164; };
    if a == 0x74 { return 0x165; };
    if a == 0x5A { return 0x17D; };
    if a == 0x7A { return 0x17E; };
    return -1;
  };
  if b == 0x327 {
    if a == 0x43 { return 0xC7; };
    if a == 0x63 { return 0xE7; };
    if a == 0x47 { return 0x122; };
    if a == 0x67 { return 0x123; };
    if a == 0x4B { return 0x136; };
    if a == 0x6B { return 0x137; };
    if a == 0x4C { return 0x13B; };
    if a == 0x6C { return 0x13C; };
    if a == 0x4E { return 0x145; };
    if a == 0x6E { return 0x146; };
    if a == 0x52 { return 0x156; };
    if a == 0x72 { return 0x157; };
    if a == 0x53 { return 0x15E; };
    if a == 0x73 { return 0x15F; };
    if a == 0x54 { return 0x162; };
    if a == 0x74 { return 0x163; };
    return -1;
  };
  if b == 0x328 {
    if a == 0x41 { return 0x104; };
    if a == 0x61 { return 0x105; };
    if a == 0x45 { return 0x118; };
    if a == 0x65 { return 0x119; };
    if a == 0x49 { return 0x12E; };
    if a == 0x69 { return 0x12F; };
    if a == 0x55 { return 0x172; };
    if a == 0x75 { return 0x173; };
    return -1;
  };
  -1
}

/// Single-level canonical decomposition of `cp`: (base, mark), or (cp, -1).
fn _decomp(cp: Int) -> (Int, Int) {
  // ── Latin-1 Supplement ──
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
  // ── Latin Extended-A ──
  if cp == 0x100 { return (0x41, 0x304); };
  if cp == 0x101 { return (0x61, 0x304); };
  if cp == 0x102 { return (0x41, 0x306); };
  if cp == 0x103 { return (0x61, 0x306); };
  if cp == 0x104 { return (0x41, 0x328); };
  if cp == 0x105 { return (0x61, 0x328); };
  if cp == 0x106 { return (0x43, 0x301); };
  if cp == 0x107 { return (0x63, 0x301); };
  if cp == 0x108 { return (0x43, 0x302); };
  if cp == 0x109 { return (0x63, 0x302); };
  if cp == 0x10A { return (0x43, 0x307); };
  if cp == 0x10B { return (0x63, 0x307); };
  if cp == 0x10C { return (0x43, 0x30C); };
  if cp == 0x10D { return (0x63, 0x30C); };
  if cp == 0x10E { return (0x44, 0x30C); };
  if cp == 0x10F { return (0x64, 0x30C); };
  if cp == 0x112 { return (0x45, 0x304); };
  if cp == 0x113 { return (0x65, 0x304); };
  if cp == 0x116 { return (0x45, 0x307); };
  if cp == 0x117 { return (0x65, 0x307); };
  if cp == 0x118 { return (0x45, 0x328); };
  if cp == 0x119 { return (0x65, 0x328); };
  if cp == 0x11A { return (0x45, 0x30C); };
  if cp == 0x11B { return (0x65, 0x30C); };
  if cp == 0x11C { return (0x47, 0x302); };
  if cp == 0x11D { return (0x67, 0x302); };
  if cp == 0x11E { return (0x47, 0x306); };
  if cp == 0x11F { return (0x67, 0x306); };
  if cp == 0x120 { return (0x47, 0x307); };
  if cp == 0x121 { return (0x67, 0x307); };
  if cp == 0x122 { return (0x47, 0x327); };
  if cp == 0x123 { return (0x67, 0x327); };
  if cp == 0x124 { return (0x48, 0x302); };
  if cp == 0x125 { return (0x68, 0x302); };
  if cp == 0x128 { return (0x49, 0x303); };
  if cp == 0x129 { return (0x69, 0x303); };
  if cp == 0x12A { return (0x49, 0x304); };
  if cp == 0x12B { return (0x69, 0x304); };
  if cp == 0x12C { return (0x49, 0x306); };
  if cp == 0x12D { return (0x69, 0x306); };
  if cp == 0x12E { return (0x49, 0x328); };
  if cp == 0x12F { return (0x69, 0x328); };
  if cp == 0x130 { return (0x49, 0x307); };
  if cp == 0x134 { return (0x4A, 0x302); };
  if cp == 0x135 { return (0x6A, 0x302); };
  if cp == 0x136 { return (0x4B, 0x327); };
  if cp == 0x137 { return (0x6B, 0x327); };
  if cp == 0x139 { return (0x4C, 0x301); };
  if cp == 0x13A { return (0x6C, 0x301); };
  if cp == 0x13B { return (0x4C, 0x327); };
  if cp == 0x13C { return (0x6C, 0x327); };
  if cp == 0x13D { return (0x4C, 0x30C); };
  if cp == 0x13E { return (0x6C, 0x30C); };
  if cp == 0x143 { return (0x4E, 0x301); };
  if cp == 0x144 { return (0x6E, 0x301); };
  if cp == 0x145 { return (0x4E, 0x327); };
  if cp == 0x146 { return (0x6E, 0x327); };
  if cp == 0x147 { return (0x4E, 0x30C); };
  if cp == 0x148 { return (0x6E, 0x30C); };
  if cp == 0x14C { return (0x4F, 0x304); };
  if cp == 0x14D { return (0x6F, 0x304); };
  if cp == 0x14E { return (0x4F, 0x306); };
  if cp == 0x14F { return (0x6F, 0x306); };
  if cp == 0x150 { return (0x4F, 0x30B); };
  if cp == 0x151 { return (0x6F, 0x30B); };
  if cp == 0x154 { return (0x52, 0x301); };
  if cp == 0x155 { return (0x72, 0x301); };
  if cp == 0x156 { return (0x52, 0x327); };
  if cp == 0x157 { return (0x72, 0x327); };
  if cp == 0x158 { return (0x52, 0x30C); };
  if cp == 0x159 { return (0x72, 0x30C); };
  if cp == 0x15A { return (0x53, 0x301); };
  if cp == 0x15B { return (0x73, 0x301); };
  if cp == 0x15C { return (0x53, 0x302); };
  if cp == 0x15D { return (0x73, 0x302); };
  if cp == 0x15E { return (0x53, 0x327); };
  if cp == 0x15F { return (0x73, 0x327); };
  if cp == 0x160 { return (0x53, 0x30C); };
  if cp == 0x161 { return (0x73, 0x30C); };
  if cp == 0x162 { return (0x54, 0x327); };
  if cp == 0x163 { return (0x74, 0x327); };
  if cp == 0x164 { return (0x54, 0x30C); };
  if cp == 0x165 { return (0x74, 0x30C); };
  if cp == 0x168 { return (0x55, 0x303); };
  if cp == 0x169 { return (0x75, 0x303); };
  if cp == 0x16A { return (0x55, 0x304); };
  if cp == 0x16B { return (0x75, 0x304); };
  if cp == 0x16C { return (0x55, 0x306); };
  if cp == 0x16D { return (0x75, 0x306); };
  if cp == 0x16E { return (0x55, 0x30A); };
  if cp == 0x16F { return (0x75, 0x30A); };
  if cp == 0x170 { return (0x55, 0x30B); };
  if cp == 0x171 { return (0x75, 0x30B); };
  if cp == 0x172 { return (0x55, 0x328); };
  if cp == 0x173 { return (0x75, 0x328); };
  if cp == 0x174 { return (0x57, 0x302); };
  if cp == 0x175 { return (0x77, 0x302); };
  if cp == 0x176 { return (0x59, 0x302); };
  if cp == 0x177 { return (0x79, 0x302); };
  if cp == 0x178 { return (0x59, 0x308); };
  if cp == 0x179 { return (0x5A, 0x301); };
  if cp == 0x17A { return (0x7A, 0x301); };
  if cp == 0x17B { return (0x5A, 0x307); };
  if cp == 0x17C { return (0x7A, 0x307); };
  if cp == 0x17D { return (0x5A, 0x30C); };
  if cp == 0x17E { return (0x7A, 0x30C); };
  // ── Greek (standard accented vowels) ──
  if cp == 0x386 { return (0x391, 0x301); };
  if cp == 0x388 { return (0x395, 0x301); };
  if cp == 0x389 { return (0x397, 0x301); };
  if cp == 0x38A { return (0x399, 0x301); };
  if cp == 0x38C { return (0x39F, 0x301); };
  if cp == 0x38E { return (0x3A5, 0x301); };
  if cp == 0x38F { return (0x3A9, 0x301); };
  if cp == 0x390 { return (0x3CA, 0x301); };
  if cp == 0x3AA { return (0x399, 0x308); };
  if cp == 0x3AB { return (0x3A5, 0x308); };
  if cp == 0x3AC { return (0x3B1, 0x301); };
  if cp == 0x3AD { return (0x3B5, 0x301); };
  if cp == 0x3AE { return (0x3B7, 0x301); };
  if cp == 0x3AF { return (0x3B9, 0x301); };
  if cp == 0x3B0 { return (0x3CB, 0x301); };
  if cp == 0x3CA { return (0x3B9, 0x308); };
  if cp == 0x3CB { return (0x3C5, 0x308); };
  if cp == 0x3CC { return (0x3BF, 0x301); };
  if cp == 0x3CD { return (0x3C5, 0x301); };
  if cp == 0x3CE { return (0x3C9, 0x301); };
  // ── Cyrillic (grave and diaeresis forms) ──
  if cp == 0x400 { return (0x415, 0x300); };
  if cp == 0x401 { return (0x415, 0x308); };
  if cp == 0x450 { return (0x435, 0x300); };
  if cp == 0x451 { return (0x435, 0x308); };
  (cp, -1)
}
