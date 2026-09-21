// XIOM - String: Word Break
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.wordbreak

// Depends on: xiom.string

// ============================================================================
// Unicode word segmentation (UAX #29, compact approximation). Words are runs
// of letters, digits and underscore; punctuation forms its own word tokens;
// whitespace separates words (and stays with the preceding word when the text
// is split at the boundaries). Mid-word apostrophes and hyphens join the
// surrounding letters ("don't", "well-known"), and a period between digits
// stays inside a number ("3.14"). A boundary is the byte offset where a new
// word begins, so "Hello,world" yields ["Hello", ",", "world"]. Word ranges
// are stored in a sorted constant table and located by binary search (see
// COMPILER_BUGS.md BUG 20).
// ============================================================================

use xiom.string;

/// Byte offsets in `s` where a new word begins (the start of every word after
/// the first), in increasing order. For "Hello,world" the offsets are [5, 6].
/// Params: s the string to analyse.
/// Returns: the list of word-start byte offsets (may be empty).
/// Error case: none; malformed UTF-8 bytes are skipped without boundaries.
/// Complexity: O(|s| * log table size).
pub fn unicode_word_boundaries(s: Str) -> Vec[Int] {
  let len = string.str_len(s);
  var bounds = Vec[Int].new();
  var i: Int = 0;
  var last_type: Int = -1;
  var saw_space: Bool = false;
  var prev_cp: Int = -1;
  while i < len {
    let pos = i;
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let adv = _char_len(cp);
    if _is_space(cp) {
      saw_space = true;
      i = i + adv;
      continue;
    };
    var t: Int = 1;
    if _is_word(cp) {
      t = 0;
    } elif cp == 0x27 {
      if last_type == 0 && !saw_space {
        t = 3;
      } else {
        t = 1;
      };
    } elif cp == 0x2D {
      let next_cp = _decode(s, i + adv, len);
      if last_type == 0 && !saw_space && _is_word(next_cp) {
        t = 3;
      } else {
        t = 1;
      };
    } elif cp == 0x2E {
      let next_cp = _decode(s, i + adv, len);
      if _is_digit(prev_cp) && _is_digit(next_cp) {
        t = 0;
      } else {
        t = 1;
      };
    };
    if !saw_space && last_type >= 0 {
      var no_break = false;
      if t == 1 && last_type == 1 {
        no_break = true;
      };
      if t == 3 && last_type == 0 {
        no_break = true;
      };
      if t == 0 && last_type == 0 {
        no_break = true;
      };
      if t == 0 && last_type == 3 {
        no_break = true;
      };
      if !no_break {
        bounds.push(pos);
      };
    } else {
      if saw_space && last_type >= 0 {
        bounds.push(pos);
      };
    };
    last_type = t;
    saw_space = false;
    prev_cp = cp;
    i = i + adv;
  }
  bounds
}

/// Split `s` into word tokens at the word boundaries. Whitespace stays with
/// the preceding token; consecutive punctuation forms one token.
/// Params: s the string to split.
/// Returns: the list of word substrings.
/// Error case: none.
/// Complexity: O(|s| + number of boundaries).
pub fn unicode_split_words(s: Str) -> Vec[Str] {
  let bounds = unicode_word_boundaries(s);
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

/// True when `cp` is a word character (letters, digits, underscore).
/// NOTE (BUG 20): the ranges are walked through a small recursive helper; a
/// straight-line range-check chain would be SIMD-vectorized by the -O2
/// vectorizer into AVX-512 instructions that trap on CPUs without AVX-512.
fn _is_word(cp: Int) -> Bool {
  _word_r(cp, 0)
}

fn _word_r(cp: Int, i: Int) -> Bool {
  if i == 0 {
    if cp >= 0x30 && cp <= 0x39 { return true; };
  };
  if i == 1 {
    if cp >= 0x41 && cp <= 0x5A { return true; };
  };
  if i == 2 {
    if cp == 0x5F { return true; };
  };
  if i == 3 {
    if cp >= 0x61 && cp <= 0x7A { return true; };
  };
  if i == 4 {
    if cp == 0xB5 { return true; };
  };
  if i == 5 {
    if cp >= 0xC0 && cp <= 0xD6 { return true; };
  };
  if i == 6 {
    if cp >= 0xD8 && cp <= 0xF6 { return true; };
  };
  if i == 7 {
    if cp >= 0xF8 && cp <= 0xFF { return true; };
  };
  if i == 8 {
    if cp >= 0x100 && cp <= 0x17F { return true; };
  };
  if i == 9 {
    if cp >= 0x370 && cp <= 0x3FF { return true; };
  };
  if i == 10 {
    if cp >= 0x400 && cp <= 0x52F { return true; };
  };
  if i == 11 {
    if cp >= 0x590 && cp <= 0x5FF { return true; };
  };
  if i == 12 {
    if cp >= 0x600 && cp <= 0x6FF { return true; };
  };
  if i == 13 {
    if cp >= 0x900 && cp <= 0xFFF { return true; };
  };
  if i == 14 {
    if cp >= 0x1100 && cp <= 0x11FF { return true; };
  };
  if i == 15 {
    if cp >= 0x1E00 && cp <= 0x1EFF { return true; };
  };
  if i == 16 {
    if cp >= 0x3040 && cp <= 0x30FF { return true; };
  };
  if i == 17 {
    if cp >= 0x3130 && cp <= 0x318F { return true; };
  };
  if i == 18 {
    if cp >= 0x3400 && cp <= 0x4DBF { return true; };
  };
  if i == 19 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return true; };
  };
  if i == 20 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return true; };
  };
  if i == 21 {
    if cp >= 0xF900 && cp <= 0xFAFF { return true; };
  };
  if i == 22 {
    if cp >= 0x20000 && cp <= 0x2A6DF { return true; };
  };
  if i < 22 {
    return _word_r(cp, i + 1);
  };
  false
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
  if pos >= len {
    return -1;
  };
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

/// Whitespace separators.
fn _is_space(cp: Int) -> Bool {
  if cp == 0x09 || cp == 0x0A || cp == 0x0B || cp == 0x0C || cp == 0x0D { return true; };
  if cp == 0x20 || cp == 0xA0 { return true; };
  if cp == 0x1680 { return true; };
  if cp >= 0x2000 && cp <= 0x200A { return true; };
  if cp == 0x2028 || cp == 0x2029 || cp == 0x202F || cp == 0x205F || cp == 0x3000 { return true; };
  false
}

/// Digits.
fn _is_digit(cp: Int) -> Bool {
  if cp >= 0x30 && cp <= 0x39 { return true; };
  if cp >= 0x660 && cp <= 0x669 { return true; };
  false
}
