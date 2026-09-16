// XIOM - String: Sentence Break
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.sentencebreak

// Depends on: xiom.string

// ============================================================================
// Unicode sentence segmentation (UAX #29, compact approximation). A sentence
// boundary is emitted after a run of sentence-ending punctuation
// (. ! ? ... and fullwidth forms) plus any closing quotes/brackets, when that
// run is followed by whitespace, a newline, or the end of the segment.
// Paragraph separators (U+2028/U+2029) and runs of two or more newlines are
// mandatory boundaries. Limitations (documented): abbreviations such as "e.g."
// and decimal numbers such as "3.14" are not recognised, so a period inside
// them can produce a boundary; see _is_digit for the one special case.
// ============================================================================

use xiom.string;

/// Byte offsets in `s` where a new sentence begins (the start of every
/// sentence after the first), in increasing order. A boundary follows the
/// terminator run and its whitespace, so the whitespace stays with the
/// previous sentence. See the module header for the covered rules.
/// Params: s the string to analyse.
/// Returns: the list of sentence-start byte offsets (may be empty).
/// Error case: none; malformed UTF-8 bytes are skipped without boundaries.
/// Complexity: O(|s|).
pub fn unicode_sentence_boundaries(s: Str) -> Vec[Int] {
  let len = string.str_len(s);
  var bounds = Vec[Int].new();
  var i: Int = 0;
  var state: Int = 0;
  while i < len {
    let pos = i;
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      state = 0;
      continue;
    };
    let adv = _char_len(cp);
    if cp == 0x2028 || cp == 0x2029 {
      bounds.push(pos + adv);
      state = 0;
      i = i + adv;
      continue;
    };
    if cp == 0x0A || cp == 0x0D {
      if state == 1 {
        bounds.push(pos);
      } else {
        var j = pos;
        var nl: Int = 0;
        while j < len {
          let c2 = _decode(s, j, len);
          if c2 == 0x0A || c2 == 0x0D {
            nl = nl + 1;
            j = j + _char_len(c2);
          } else {
            break;
          };
        };
        if nl >= 2 {
          bounds.push(j);
        };
      };
      state = 0;
      i = i + adv;
      continue;
    };
    if state == 1 {
      if _is_term(cp) || _is_closing(cp) || _is_space(cp) {
        // stay inside the terminator run
      } elif _is_digit(cp) {
        // "3.14" / "e.g.2" style: no boundary
        state = 0;
      } else {
        bounds.push(pos);
        state = 0;
      };
    };
    if state == 0 {
      if _is_term(cp) {
        state = 1;
      };
    };
    i = i + adv;
  }
  bounds
}

/// Split `s` into sentences at the sentence boundaries. The terminator run and
/// its trailing whitespace stay with the preceding sentence.
/// Params: s the string to split.
/// Returns: the list of sentence substrings.
/// Error case: none.
/// Complexity: O(|s| + number of boundaries).
pub fn unicode_split_sentences(s: Str) -> Vec[Str] {
  let bounds = unicode_sentence_boundaries(s);
  let len = string.str_len(s);
  var out = Vec[Str].new();
  var start: Int = 0;
  var i: Int = 0;
  while i < bounds.len() {
    let b = bounds[i];
    if b > start {
      out.push(string.str_slice(s, start, b));
    };
    start = b;
    i = i + 1;
  }
  if start < len {
    out.push(string.str_slice(s, start, len));
  };
  out
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

/// Sentence-ending punctuation.
fn _is_term(cp: Int) -> Bool {
  if cp == 0x2E || cp == 0x21 || cp == 0x3F { return true; };
  if cp == 0x2026 { return true; };
  if cp == 0xFF0E || cp == 0xFF01 || cp == 0xFF1F { return true; };
  false
}

/// Closing quotes/brackets that may follow sentence-ending punctuation.
fn _is_closing(cp: Int) -> Bool {
  if cp == 0x29 || cp == 0x5D || cp == 0x7D { return true; };
  if cp == 0x22 || cp == 0x27 { return true; };
  if cp == 0x2018 || cp == 0x2019 || cp == 0x201C || cp == 0x201D { return true; };
  if cp == 0xAB || cp == 0xBB { return true; };
  if cp == 0x3009 || cp == 0x300B || cp == 0x300D || cp == 0x300F || cp == 0x3011 { return true; };
  if cp == 0xFF09 || cp == 0xFF3D || cp == 0xFF5D { return true; };
  false
}

/// Whitespace that may follow a terminator before the next sentence.
fn _is_space(cp: Int) -> Bool {
  if cp == 0x09 || cp == 0x0B || cp == 0x0C { return true; };
  if cp == 0x20 || cp == 0xA0 { return true; };
  if cp == 0x1680 { return true; };
  if cp >= 0x2000 && cp <= 0x200A { return true; };
  if cp == 0x202F || cp == 0x205F || cp == 0x3000 { return true; };
  false
}

/// Digits: a terminator directly followed by a digit is not a sentence break.
fn _is_digit(cp: Int) -> Bool {
  if cp >= 0x30 && cp <= 0x39 { return true; };
  if cp >= 0x660 && cp <= 0x669 { return true; };
  false
}
