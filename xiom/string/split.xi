// XIOM - String: Split
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.split

// Depends on: xiom.string

// ============================================================================
// Split a string into parts by a delimiter, multiple delimiters, or whitespace,
// with limited-count and reversed variants. Splitting always produces at least
// one part; `str_split`, `str_lines` and `str_words` delegate to the flat
// string library, the remaining variants are implemented here.
// ============================================================================

use xiom.string;

// Splits `s` on every occurrence of `delim`.
// Always returns at least one part.
// Complexity: O(|s|).
pub fn str_split(s: Str, delim: Str) -> Vec[Str]
  requires: delim.len() > 0
  ensures:  result.len() >= 1
{
  return string.str_split(s, delim);
}

// Splits `s` on `delim` into at most `n` parts. When `n <= 1`, returns a
// single part holding all of `s`.
// Always returns at least one part.
// Complexity: O(|s|).
pub fn str_split_n(s: Str, delim: Str, n: Int) -> Vec[Str]
  ensures:  result.len() >= 1
{
  var result = Vec[Str].new();
  if n <= 1 {
    result.push(s);
    return result;
  };
  let delim_len = string.str_len(delim);
  if delim_len == 0 {
    result.push(s);
    return result;
  };
  let s_len = string.str_len(s);
  var start: Int = 0;
  var pos: Int = 0;
  var parts: Int = 0;
  while pos < s_len && parts < n - 1 {
    if pos + delim_len <= s_len && string.str_slice(s, pos, pos + delim_len) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + delim_len;
      start = pos;
      parts = parts + 1;
    } else {
      pos = pos + 1;
    };
  }
  result.push(string.str_slice(s, start, s_len));
  result
}

// Splits `s` on any of the delimiters in `delims`. The longest delimiter
// match at each position wins; when `delims` is empty, returns a single part
// holding all of `s`.
// Always returns at least one part.
// Complexity: O(|s| * |delims|).
pub fn str_split_any(s: Str, delims: &Vec[Str]) -> Vec[Str]
  ensures:  result.len() >= 1
{
  var result = Vec[Str].new();
  let s_len = string.str_len(s);
  let d_count = delims.len();
  if d_count == 0 {
    result.push(s);
    return result;
  };
  var start: Int = 0;
  var pos: Int = 0;
  while pos < s_len {
    var matched = false;
    var adv: Int = 0;
    var i: Int = 0;
    while i < d_count {
      var d = delims[i];
      let d_len = string.str_len(d);
      if d_len > 0 && pos + d_len <= s_len && string.str_slice(s, pos, pos + d_len) == d {
        matched = true;
        adv = d_len;
        break;
      };
      i = i + 1;
    };
    if matched {
      result.push(string.str_slice(s, start, pos));
      pos = pos + adv;
      start = pos;
    } else {
      pos = pos + 1;
    };
  }
  result.push(string.str_slice(s, start, s_len));
  result
}

// Splits `s` at the first occurrence of `delim` into a pair holding the part
// before `delim` and the part after it. When `delim` does not occur in `s`,
// returns `(s, "")`.
// Complexity: O(|s|).
pub fn str_split_once(s: Str, delim: Str) -> (Str, Str) {
  let idx = string.index_of(s, delim);
  match idx {
    Some(i) => {
      let before = string.str_slice(s, 0, i);
      let after = string.str_slice(s, i + string.str_len(delim), string.str_len(s));
      return (before, after);
    };
    None => { return (s, ""); };
  }
}

// Splits `s` on newline boundaries; the lines exclude the trailing newline.
// Always returns at least one part.
// Complexity: O(|s|).
pub fn str_lines(s: Str) -> Vec[Str]
  ensures:  result.len() >= 1
{
  return string.lines(s);
}

// Splits `s` on whitespace boundaries into words.
// Returns an empty vector when `s` contains no words.
// Complexity: O(|s|).
pub fn str_words(s: Str) -> Vec[Str] {
  return string.words(s);
}

// Splits `s` on `delim` scanning from the end of `s`; the parts are returned
// in source order. When `delim` is empty or does not occur, returns a single
// part holding all of `s`.
// Complexity: O(|s|).
pub fn str_rsplit(s: Str, delim: Str) -> Vec[Str]
  ensures:  result.len() >= 1
{
  var rev = Vec[Str].new();
  let delim_len = string.str_len(delim);
  if delim_len == 0 {
    rev.push(s);
    return rev;
  };
  var rem = s;
  loop {
    let idx = string.last_index_of(rem, delim);
    match idx {
      Some(i) => {
        rev.push(string.str_slice(rem, i + delim_len, string.str_len(rem)));
        rem = string.str_slice(rem, 0, i);
      };
      None => {
        rev.push(rem);
        break;
      };
    };
  }
  var result = Vec[Str].new();
  var i: Int = rev.len() - 1;
  while i >= 0 {
    var p = rev[i];
    result.push(p);
    i = i - 1;
  };
  result
}
