// XIOM - String: Split
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
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

/// Splits `s` on every occurrence of `delim`.
/// Always returns at least one part.
/// Complexity: O(|s|).
pub fn str_split(s: Str, delim: Str) -> Vec[Str]
  requires: delim.len() > 0
  ensures:  result.len() >= 1
{
  return string.str_split(s, delim);
}

/// Splits `s` on `delim` into at most `n` parts. When `n <= 1`, returns a
/// single part holding all of `s`.
/// Always returns at least one part.
/// Complexity: O(|s|).
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

/// Splits `s` on any of the delimiters in `delims`. The longest delimiter
/// match at each position wins; when `delims` is empty, returns a single part
/// holding all of `s`.
/// Always returns at least one part.
/// Complexity: O(|s| * |delims|).
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

/// Splits `s` at the first occurrence of `delim` into a pair holding the part
/// before `delim` and the part after it. When `delim` does not occur in `s`,
/// returns `(s, "")`.
/// Complexity: O(|s|).
pub fn str_split_once(s: Str, delim: Str) -> (Str, Str)
  ensures: (string.index_of(s, delim).is_none) => (result.0 == s && result.1.len() == 0)
  ensures: (string.index_of(s, delim).is_some) => (result.0.len() + result.1.len() + delim.len() == s.len())
{
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

/// Splits `s` on newline boundaries; the lines exclude the trailing newline.
/// Always returns at least one part.
/// Complexity: O(|s|).
pub fn str_lines(s: Str) -> Vec[Str]
  ensures:  result.len() >= 1
{
  return string.lines(s);
}

/// Splits `s` on whitespace boundaries into words.
/// Returns an empty vector when `s` contains no words.
/// Complexity: O(|s|).
pub fn str_words(s: Str) -> Vec[Str]
  ensures: result.len() <= s.len()
  ensures: (s.len() == 0) => (result.len() == 0)
{
  return string.words(s);
}

/// Splits `s` on `delim` scanning from the end of `s`; the parts are returned
/// in source order. When `delim` is empty or does not occur, returns a single
/// part holding all of `s`.
/// Complexity: O(|s|).
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

// ============================================================================
// Wave 166 (2026-10-01 intake row 36; requesters chef, k8s, cfn): substring
// before/after a delimiter, multi-delimiter scanning, and split-into-offsets
// (byte ranges, no Vec[Str]). Scanners run over a cached raw view -- no
// str_slice equality per position.
// ============================================================================

// Raw byte at `i` over a cached pointer (T007 confinement; callers bound i).
fn _split_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}

// True when `delim` occurs at byte `at` of the cached (base, len) view.
fn _split_match_at(base: *UInt8, len: Int, at: Int, delim: Str) -> Bool {
  let dlen = string.str_len(delim);
  if dlen == 0 || at + dlen > len {
    return false;
  };
  let db = delim.c_str();
  var i = 0;
  while i < dlen {
    if _split_raw(base, at + i) != _split_raw(db, i) {
      return false;
    };
    i = i + 1;
  };
  true
}

/// Part of `s` before the first occurrence of `delim` (delimiter excluded).
/// When `delim` does not occur, returns all of `s`; an empty `delim` yields ""
/// (consistent with index_of's Some(0) for an empty needle).
/// Complexity: O(|s| * |delim|).
pub fn str_before(s: Str, delim: Str) -> Str
  ensures: result.len() <= s.len()
  ensures: (delim.len() == 0) => (result.len() == 0)
  ensures: (string.index_of(s, delim).is_none) => (result == s)
{
  let idx = string.index_of(s, delim);
  match idx {
    Some(i) => {
      return string.str_slice(s, 0, i);
    },
    None => {
      return s;
    },
  }
}

/// Part of `s` after the first occurrence of `delim` (delimiter excluded).
/// When `delim` does not occur, returns ""; an empty `delim` yields all of `s`
/// (consistent with index_of's Some(0) for an empty needle).
/// Complexity: O(|s| * |delim|).
pub fn str_after(s: Str, delim: Str) -> Str
  ensures: result.len() <= s.len()
  ensures: (delim.len() == 0) => (result == s)
  ensures: (string.index_of(s, delim).is_none) => (result.len() == 0)
{
  let idx = string.index_of(s, delim);
  match idx {
    Some(i) => {
      return string.str_slice(s, i + string.str_len(delim), string.str_len(s));
    },
    None => {
      return "";
    },
  }
}

/// Earliest byte offset >= `from` where any delimiter in `delims` matches, or
/// None. A negative `from` clamps to 0. Complexity: O((|s| - from) * |delims|).
pub fn str_find_any_at(s: Str, delims: &Vec[Str], from: Int) -> Option[Int]
  ensures: (delims.len() == 0) => (result.is_none)
  ensures: (from >= string.str_len(s)) => (result.is_none)
  ensures: (result.is_some) => (from < string.str_len(s))
  ensures: (result.is_some) => (delims.len() > 0)
{
  let len = string.str_len(s);
  var f = from;
  if f < 0 {
    f = 0;
  };
  let base = s.c_str();
  var pos = f;
  while pos < len {
    var di = 0;
    while di < delims.len() {
      if _split_match_at(base, len, pos, delims[di]) {
        return Some(pos);
      };
      di = di + 1;
    };
    pos = pos + 1;
  };
  None
}

/// Length of the LONGEST delimiter in `delims` matching at byte `pos`
/// (0 when none matches). Complexity: O(|delims| * max |delim|).
pub fn str_delim_len_at(s: Str, delims: &Vec[Str], pos: Int) -> Int
  ensures: result >= 0
  ensures: (pos < 0 || pos >= string.str_len(s)) => (result == 0)
  ensures: (pos >= 0 && pos < string.str_len(s)) => (result <= string.str_len(s) - pos)
  ensures: (result == 0) || (delims.len() > 0)
{
  let len = string.str_len(s);
  if pos < 0 || pos >= len {
    return 0;
  };
  let base = s.c_str();
  var best = 0;
  var di = 0;
  while di < delims.len() {
    let dlen = string.str_len(delims[di]);
    if dlen > best && _split_match_at(base, len, pos, delims[di]) {
      best = dlen;
    };
    di = di + 1;
  };
  best
}

/// Parts of `str_split(s, delim)` as flat [start, end, ...] byte-range pairs:
/// one Vec[Int], no Str per part. Matches str_split exactly, including the
/// empty-delimiter (per-byte) and trailing-empty-part cases.
/// Complexity: O(|s| * |delim|).
pub fn str_split_spans(s: Str, delim: Str) -> Vec[Int]
  ensures: result.len() >= 2
  ensures: result.len() % 2 == 0
  ensures: result.len() <= 2 * (string.str_len(s) + 1)
  ensures: (string.str_len(s) == 0) => (result.len() == 2)
{
  var result = Vec[Int].new();
  let len = string.str_len(s);
  let dlen = string.str_len(delim);
  let base = s.c_str();
  if dlen == 0 {
    var i = 0;
    while i < len {
      result.push(i);
      result.push(i + 1);
      i = i + 1;
    };
    if len == 0 {
      result.push(0);
      result.push(0);
    };
    return result;
  };
  var start = 0;
  var pos = 0;
  while pos < len {
    if _split_match_at(base, len, pos, delim) {
      result.push(start);
      result.push(pos);
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    };
  };
  result.push(start);
  result.push(len);
  result
}

/// Parts of `str_split_any(s, delims)` as flat [start, end, ...] byte-range
/// pairs (no Vec[Str]). The longest delimiter match at each position wins,
/// matching str_split_any; an empty `delims` (or only-empty delimiters) yields
/// a single whole-string span. Complexity: O(|s| * |delims| * max |delim|).
pub fn str_split_any_spans(s: Str, delims: &Vec[Str]) -> Vec[Int]
  ensures: result.len() >= 2
  ensures: result.len() % 2 == 0
  ensures: result.len() <= 2 * (string.str_len(s) + 1)
  ensures: (delims.len() == 0) => (result.len() == 2)
{
  var result = Vec[Int].new();
  let len = string.str_len(s);
  if delims.len() == 0 {
    result.push(0);
    result.push(len);
    return result;
  };
  let base = s.c_str();
  var start = 0;
  var pos = 0;
  while pos < len {
    var adv = 0;
    var di = 0;
    while di < delims.len() {
      let dlen = string.str_len(delims[di]);
      if dlen > adv && _split_match_at(base, len, pos, delims[di]) {
        adv = dlen;
      };
      di = di + 1;
    };
    if adv > 0 {
      result.push(start);
      result.push(pos);
      pos = pos + adv;
      start = pos;
    } else {
      pos = pos + 1;
    };
  };
  result.push(start);
  result.push(len);
  result
}
