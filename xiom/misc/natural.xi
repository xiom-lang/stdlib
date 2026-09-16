// XIOM - Misc: Natural Sort
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.misc.natural

// Depends on: xiom.string

// ============================================================================
// Natural (human) ordering that compares embedded digit runs numerically,
// with sorting helpers and key extraction.
// ============================================================================

use xiom.string;
use xiom.char;

/// Compare a and b in natural order: -1, 0, or 1. Embedded digit runs are
/// compared numerically (so "file2" < "file10"); other characters compare by
/// code point. O(min(len_a, len_b)).
pub fn natural_compare(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  var alen = a.len();
  var blen = b.len();
  var ai = 0;
  var bi = 0;
  while ai < alen && bi < blen {
    var ac = a.char_at(ai);
    var bc = b.char_at(bi);
    if xiom.char.is_digit(ac) && xiom.char.is_digit(bc) {
      var a_num = 0;
      var b_num = 0;
      while ai < alen && xiom.char.is_digit(a.char_at(ai)) {
        a_num = a_num * 10 + ((a.char_at(ai) as Int) - 48);
        ai = ai + 1;
      }
      while bi < blen && xiom.char.is_digit(b.char_at(bi)) {
        b_num = b_num * 10 + ((b.char_at(bi) as Int) - 48);
        bi = bi + 1;
      }
      if a_num < b_num { return -1; }
      if a_num > b_num { return 1; }
    } else {
      if (ac as Int) < (bc as Int) { return -1; }
      if (ac as Int) > (bc as Int) { return 1; }
      ai = ai + 1;
      bi = bi + 1;
    }
  }
  if ai == alen && bi == blen {
    return 0;
  }
  if ai < alen { return 1; }
  -1
}

/// Natural comparison ignoring case: digit runs compare numerically, letters
/// compare by lowercase code point. O(min(len_a, len_b)).
pub fn natural_compare_ignore_case(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  var alen = a.len();
  var blen = b.len();
  var ai = 0;
  var bi = 0;
  while ai < alen && bi < blen {
    var ac = a.char_at(ai);
    var bc = b.char_at(bi);
    if xiom.char.is_digit(ac) && xiom.char.is_digit(bc) {
      var a_num = 0;
      var b_num = 0;
      while ai < alen && xiom.char.is_digit(a.char_at(ai)) {
        a_num = a_num * 10 + ((a.char_at(ai) as Int) - 48);
        ai = ai + 1;
      }
      while bi < blen && xiom.char.is_digit(b.char_at(bi)) {
        b_num = b_num * 10 + ((b.char_at(bi) as Int) - 48);
        bi = bi + 1;
      }
      if a_num < b_num { return -1; }
      if a_num > b_num { return 1; }
    } else {
      var al = lower_cp(ac);
      var bl2 = lower_cp(bc);
      if al < bl2 { return -1; }
      if al > bl2 { return 1; }
      ai = ai + 1;
      bi = bi + 1;
    }
  }
  if ai == alen && bi == blen {
    return 0;
  }
  if ai < alen { return 1; }
  -1
}

/// Lowercase code point of a character.
fn lower_cp(c: Char) -> Int {
  var v = c as Int;
  if v >= 65 && v <= 90 {
    v + 32
  } else {
    v
  }
}

/// A copy of strings sorted naturally (ascending). O(k^2 * n) with insertion
/// sort; stable.
pub fn natural_sort(strings: &Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  var i = 0;
  while i < strings.len() {
    out.push(strings[i]);
    i = i + 1;
  }
  var j = 1;
  while j < out.len() {
    var k = j;
    while k > 0 {
      var left = out[k - 1];
      var right = out[k];
      if natural_compare(left, right) > 0 {
        out[k - 1] = right;
        out[k] = left;
        k = k - 1;
      } else {
        k = 0;
      }
    }
    j = j + 1;
  }
  out
}

/// Sort items by an extracted natural key, returning a new vector.
/// O(k^2 * n). The key function must be named and return a Str.
/// NOTE: implemented as a concrete Vec[Str] specialization of the frozen
/// generic API (compiler fn-ptr codegen bug - docs/STDLIB_GENERICS.md).
pub fn natural_sort_by(items: &Vec[Str], key: fn(&Str) -> Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var i = 0;
  while i < items.len() {
    out.push(items[i]);
    i = i + 1;
  }
  var j = 1;
  while j < out.len() {
    var k = j;
    while k > 0 {
      var left_item = out[k - 1];
      var right_item = out[k];
      var left_key = key(&left_item);
      var right_key = key(&right_item);
      if natural_compare(left_key, right_key) > 0 {
        out[k - 1] = right_item;
        out[k] = left_item;
        k = k - 1;
      } else {
        k = 0;
      }
    }
    j = j + 1;
  }
  out
}

/// The comparison segments of s; each tuple is (digit_value, chunk).
/// Digit runs yield (parsed_value, digit_string); text runs yield
/// (0, text_chunk). O(n).
pub fn natural_key(s: Str) -> Vec[(Int, Str)] {
  var out = Vec[(Int, Str)].new();
  var len = s.len();
  var i = 0;
  while i < len {
    var c = s.char_at(i);
    if xiom.char.is_digit(c) {
      var start = i;
      var value = 0;
      while i < len && xiom.char.is_digit(s.char_at(i)) {
        value = value * 10 + ((s.char_at(i) as Int) - 48);
        i = i + 1;
      }
      var chunk = xiom.string.str_slice(s, start, i);
      out.push((value, chunk));
    } else {
      var start = i;
      while i < len && !xiom.char.is_digit(s.char_at(i)) {
        i = i + 1;
      }
      var chunk = xiom.string.str_slice(s, start, i);
      out.push((0, chunk));
    }
  }
  out
}

/// Split s into alternating digit and text chunks. O(n).
pub fn natural_chunk(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  var len = s.len();
  var i = 0;
  while i < len {
    var c = s.char_at(i);
    if xiom.char.is_digit(c) {
      var start = i;
      while i < len && xiom.char.is_digit(s.char_at(i)) {
        i = i + 1;
      }
      out.push(xiom.string.str_slice(s, start, i));
    } else {
      var start = i;
      while i < len && !xiom.char.is_digit(s.char_at(i)) {
        i = i + 1;
      }
      out.push(xiom.string.str_slice(s, start, i));
    }
  }
  out
}

/// Whether s contains a digit run starting at index i. O(1).
/// Returns false when i is out of bounds.
pub fn natural_is_digit_run(s: Str, i: Int) -> Bool {
  if i < 0 || i >= s.len() { return false; }
  xiom.char.is_digit(s.char_at(i))
}

/// Compare two pure numeric strings by value (leading zeros are ignored).
/// O(n). Returns -1, 0, or 1. Non-digit content compares lexicographically.
pub fn natural_compare_numeric(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  var alen = a.len();
  var blen = b.len();
  var ai = 0;
  var bi = 0;
  while ai < alen && a.char_at(ai) == '0' {
    ai = ai + 1;
  }
  while bi < blen && b.char_at(bi) == '0' {
    bi = bi + 1;
  }
  var a_digits = alen - ai;
  var b_digits = blen - bi;
  if a_digits < b_digits { return -1; }
  if a_digits > b_digits { return 1; }
  while ai < alen && bi < blen {
    var ac = a.char_at(ai);
    var bc = b.char_at(bi);
    if ac != bc {
      if (ac as Int) < (bc as Int) { return -1; }
      return 1;
    }
    ai = ai + 1;
    bi = bi + 1;
  }
  if alen - ai < blen - bi { return -1; }
  if alen - ai > blen - bi { return 1; }
  0
}

/// A copy of strings sorted naturally in descending order. O(k^2 * n).
pub fn natural_sort_desc(strings: &Vec[Str]) -> Vec[Str] {
  var out = Vec[Str].new();
  var i = 0;
  while i < strings.len() {
    out.push(strings[i]);
    i = i + 1;
  }
  var j = 1;
  while j < out.len() {
    var k = j;
    while k > 0 {
      var left = out[k - 1];
      var right = out[k];
      if natural_compare(left, right) < 0 {
        out[k - 1] = right;
        out[k] = left;
        k = k - 1;
      } else {
        k = 0;
      }
    }
    j = j + 1;
  }
  out
}
