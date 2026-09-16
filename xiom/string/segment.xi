// XIOM - String: Segment
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.segment

// Depends on: none

// ============================================================================
// Grapheme cluster segmentation of a string. NOTE: current implementation lives
// in string.unicode stub - move the functions here during the implementation
// phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// True when byte `b` is a UTF-8 continuation byte (0b10xxxxxx).
// Complexity: O(1).
fn _is_cont(b: Int) -> Bool {
  let masked = b & 0xC0;
  masked == 0x80
}

// Splits `s` into its individual Unicode characters (one Str per code point).
// Malformed UTF-8 bytes are treated as single-byte characters.
// Complexity: O(|s|).
fn _split_chars(s: Str) -> Vec[Str] {
  var chars = Vec[Str].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var start = i;
    var adv: Int = 1;
    while start + adv < len && _is_cont(_byte(s, start + adv)) {
      adv = adv + 1;
    };
    chars.push(string.str_slice(s, start, start + adv));
    i = start + adv;
  };
  chars
}

// Decodes the code point of a single-character string.
// Complexity: O(1).
fn _decode_cp(c: Str) -> Int {
  let b0 = _byte(c, 0);
  if b0 <= 0x7F {
    return b0;
  };
  if (b0 & 0xE0) == 0xC0 {
    let b1 = _byte(c, 1);
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if (b0 & 0xF0) == 0xE0 {
    let b1 = _byte(c, 1);
    let b2 = _byte(c, 2);
    return ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
  };
  let b1 = _byte(c, 1);
  let b2 = _byte(c, 2);
  let b3 = _byte(c, 3);
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}

// True when `cp` is a Grapheme_Extend character (combining marks, ZWNJ/ZWJ).
// Covers the common combining blocks; other Grapheme_Extend code points are
// treated as cluster starters (documented subset).
// Complexity: O(1).
fn _is_extend(cp: Int) -> Bool {
  if cp == 0x200C || cp == 0x200D {
    return true;
  };
  if cp >= 0x300 && cp <= 0x36F {
    return true;
  };
  if cp >= 0x483 && cp <= 0x489 {
    return true;
  };
  if cp >= 0x1AB0 && cp <= 0x1AFF {
    return true;
  };
  if cp >= 0x1DC0 && cp <= 0x1DFF {
    return true;
  };
  if cp >= 0x20D0 && cp <= 0x20FF {
    return true;
  };
  if cp >= 0xFE20 && cp <= 0xFE2F {
    return true;
  };
  false
}

// True when `c` ends with a carriage-return byte.
// Complexity: O(1).
fn _ends_with_cr(c: Str) -> Bool {
  let l = string.str_len(c);
  l >= 1 && _byte(c, l - 1) == 13
}

// Merges the character list into grapheme clusters: a cluster is a base
// character followed by any Extend characters and a CR followed by LF. The
// CRLF pair is treated as a single cluster per UAX #29.
// Complexity: O(|chars|).
fn _clusterize(chars: &Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  var i: Int = 0;
  while i < chars.len() {
    let c = chars[i];
    if out.len() == 0 {
      out.push(c);
    } else {
      let cp = _decode_cp(c);
      let prev = out[out.len() - 1];
      var merge = false;
      if _is_extend(cp) {
        merge = true;
      };
      if cp == 10 && _ends_with_cr(prev) {
        merge = true;
      };
      if merge {
        let merged = string.str_concat(prev, c);
        out[out.len() - 1] = merged;
      } else {
        out.push(c);
      };
    };
    i = i + 1;
  };
  out
}

/// Segment `s` into grapheme clusters, each returned as its own string. A
/// cluster is a base character followed by its combining (Extend) marks; a
/// CR followed by LF forms a single cluster. Characters outside the covered
/// Extend set start their own cluster.
/// Params: s the string to segment.
/// Returns: a Vec[Str] whose concatenation equals `s`.
/// Error case: none; malformed UTF-8 bytes pass through as single bytes.
/// Complexity: O(|s|).
pub fn unicode_grapheme_clusters(s: Str) -> Vec[Str] {
  let chars = _split_chars(s);
  let clusters = _clusterize(&chars);
  clusters
}

/// Return the byte offsets of the grapheme cluster boundaries of `s`,
/// including the start (0) and the end (|s|). Adjacent boundaries delimit the
/// clusters reported by `unicode_grapheme_clusters`.
/// Params: s the string to segment.
/// Returns: a Vec[Int] with the first element 0 and the last element |s|.
/// Error case: none; empty input yields [0].
/// Complexity: O(|s|).
pub fn unicode_segment_graphemes(s: Str) -> Vec[Int] {
  var out = Vec[Int].new();
  out.push(0);
  let clusters = unicode_grapheme_clusters(s);
  var pos: Int = 0;
  var i: Int = 0;
  while i < clusters.len() {
    let cl = clusters[i];
    pos = pos + cl.len();
    out.push(pos);
    i = i + 1;
  };
  out
}
