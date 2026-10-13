// XIOM - String: Replace
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.replace

// Depends on: xiom.string, xiom.char

// ============================================================================
// Replace substrings within a string: all, first, last, and count-limited
// replacements. All replacements are non-overlapping; an empty `from` pattern
// leaves the input unchanged. NOTE: the flat string library's replace is not
// delegated to because passing a str_slice result to string.index_of inside a
// loop crashes the runtime (stack-buffer-overrun, see docs/COMPILER_BUGS.md);
// these implementations scan byte-by-byte with direct slice comparisons.
// ============================================================================

// Returns the raw byte at byte index `i` of `s`, as a Char (the historical
// byte-level semantics: multi-byte leads are not decoded here).
// Precondition: 0 <= i < s.len().
// Wave 127: raw read over the cached pointer -- xiom.string.byte_at strnlens
// the whole string per call, so the per-position scans were quadratic.
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return ((*(base + i)) as Int) as Char;
  }
}

// Raw byte at byte index `i` of `s` (see _char_at).
// Complexity: O(1).
fn _raw_byte(s: Str, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return *(base + i);
  }
}

// Returns true when `from` occurs in `s` at byte position `pos`.
// Wave 127: byte compare over the cached pointers (the previous
// str_slice-per-position compare allocated a fresh slice at every probe);
// callers bound `pos + |from|` against `|s|` (the internal str_len(s) here
// was a full rescan per position).
// Complexity: O(|from|).
fn _matches_at(s: Str, pos: Int, from: Str) -> Bool {
  let from_len = xiom.string.str_len(from);
  if from_len == 0 {
    return false;
  };
  var k: Int = 0;
  while k < from_len {
    if _raw_byte(s, pos + k) != _raw_byte(from, k) {
      return false;
    };
    k = k + 1;
  };
  true
}

/// Replaces all non-overlapping occurrences of `from` with `to` in `s`.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace(s: Str, from: Str, to: Str) -> Str
  ensures: from.len() == 0 => result == s
{
  let from_len = xiom.string.str_len(from);
  if from_len == 0 {
    return s;
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  var pos: Int = 0;
  let s_len = xiom.string.str_len(s);
  while pos < s_len {
    if pos + from_len <= s_len && _matches_at(s, pos, from) {
      var k: Int = 0;
      let tl = xiom.string.str_len(to);
      while k < tl {
        out.push(_raw_byte(to, k));
        k = k + 1;
      };
      pos = pos + from_len;
    } else {
      let c = _char_at(s, pos);
      let bl = xiom.char.len_utf8(c);
      var k2: Int = 0;
      while k2 < bl && pos + k2 < s_len {
        out.push(_raw_byte(s, pos + k2));
        k2 = k2 + 1;
      };
      pos = pos + bl;
    };
  };
  Str::from_utf8(out)
}

/// Replaces all non-overlapping occurrences of `from` with `to` in `s`.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace_all(s: Str, from: Str, to: Str) -> Str
  ensures: from.len() == 0 => result == s
{
  str_replace(s, from, to)
}

/// Replaces at most `n` non-overlapping occurrences of `from` with `to` in `s`.
/// When `n <= 0`, returns `s` unchanged.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace_n(s: Str, from: Str, to: Str, n: Int) -> Str
  ensures: n <= 0 => result == s
{
  let from_len = xiom.string.str_len(from);
  if from_len == 0 {
    return s;
  };
  if n <= 0 {
    return s;
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  var pos: Int = 0;
  var count: Int = 0;
  let s_len = xiom.string.str_len(s);
  while pos < s_len {
    if count < n && pos + from_len <= s_len && _matches_at(s, pos, from) {
      var k: Int = 0;
      let tl = xiom.string.str_len(to);
      while k < tl {
        out.push(_raw_byte(to, k));
        k = k + 1;
      };
      pos = pos + from_len;
      count = count + 1;
    } else {
      let c = _char_at(s, pos);
      let bl = xiom.char.len_utf8(c);
      var k2: Int = 0;
      while k2 < bl && pos + k2 < s_len {
        out.push(_raw_byte(s, pos + k2));
        k2 = k2 + 1;
      };
      pos = pos + bl;
    };
  };
  Str::from_utf8(out)
}

/// Replaces the first occurrence of `from` with `to` in `s`.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace_first(s: Str, from: Str, to: Str) -> Str
  ensures: from.len() == 0 => result == s
{
  let from_len = xiom.string.str_len(from);
  if from_len == 0 {
    return s;
  };
  let idx_opt = xiom.string.index_of(s, from);
  match idx_opt {
    Some(idx) => {
      let before = xiom.string.str_slice(s, 0, idx);
      let after = xiom.string.str_slice(s, idx + from_len, xiom.string.str_len(s));
      return xiom.string.str_concat(xiom.string.str_concat(before, to), after);
    };
    None => { return s; };
  }
}

/// Replaces the last occurrence of `from` with `to` in `s`.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace_last(s: Str, from: Str, to: Str) -> Str
  ensures: from.len() == 0 => result == s
{
  let from_len = xiom.string.str_len(from);
  if from_len == 0 {
    return s;
  };
  let idx_opt = xiom.string.last_index_of(s, from);
  match idx_opt {
    Some(idx) => {
      let before = xiom.string.str_slice(s, 0, idx);
      let after = xiom.string.str_slice(s, idx + from_len, xiom.string.str_len(s));
      return xiom.string.str_concat(xiom.string.str_concat(before, to), after);
    };
    None => { return s; };
  }
}
