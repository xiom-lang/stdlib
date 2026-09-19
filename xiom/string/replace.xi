// XIOM - String: Replace
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
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

// Returns the character at byte index `i` of `s`.
// Precondition: 0 <= i < s.len().
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char {
  let b = xiom.string.byte_at(s, i) as Int;
  return b as Char;
}

// Returns true when `from` occurs in `s` at byte position `pos`.
// Complexity: O(|from|).
fn _matches_at(s: Str, pos: Int, from: Str) -> Bool {
  let from_len = xiom.string.str_len(from);
  let s_len = xiom.string.str_len(s);
  if from_len == 0 {
    return false;
  };
  if pos + from_len > s_len {
    return false;
  };
  xiom.string.str_slice(s, pos, pos + from_len) == from
}

// Replaces all non-overlapping occurrences of `from` with `to` in `s`.
// Returns `s` unchanged when `from` is empty or does not occur.
// Complexity: O(|s| * |from|).
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
  var result = "";
  var pos: Int = 0;
  let s_len = xiom.string.str_len(s);
  while pos < s_len {
    if _matches_at(s, pos, from) {
      result = xiom.string.str_concat(result, to);
      pos = pos + from_len;
    } else {
      let c = _char_at(s, pos);
      let bl = xiom.char.len_utf8(c);
      result = xiom.string.str_concat(result, xiom.string.str_slice(s, pos, pos + bl));
      pos = pos + bl;
    };
  };
  result
}

// Replaces all non-overlapping occurrences of `from` with `to` in `s`.
// Returns `s` unchanged when `from` is empty or does not occur.
// Complexity: O(|s| * |from|).
/// Replaces all non-overlapping occurrences of `from` with `to` in `s`.
/// Returns `s` unchanged when `from` is empty or does not occur.
/// Complexity: O(|s| * |from|).
pub fn str_replace_all(s: Str, from: Str, to: Str) -> Str
  ensures: from.len() == 0 => result == s
{
  str_replace(s, from, to)
}

// Replaces at most `n` non-overlapping occurrences of `from` with `to` in `s`.
// When `n <= 0`, returns `s` unchanged.
// Returns `s` unchanged when `from` is empty or does not occur.
// Complexity: O(|s| * |from|).
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
  var result = "";
  var pos: Int = 0;
  var count: Int = 0;
  let s_len = xiom.string.str_len(s);
  while pos < s_len {
    if count < n && _matches_at(s, pos, from) {
      result = xiom.string.str_concat(result, to);
      pos = pos + from_len;
      count = count + 1;
    } else {
      let c = _char_at(s, pos);
      let bl = xiom.char.len_utf8(c);
      result = xiom.string.str_concat(result, xiom.string.str_slice(s, pos, pos + bl));
      pos = pos + bl;
    };
  };
  result
}

// Replaces the first occurrence of `from` with `to` in `s`.
// Returns `s` unchanged when `from` is empty or does not occur.
// Complexity: O(|s| * |from|).
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

// Replaces the last occurrence of `from` with `to` in `s`.
// Returns `s` unchanged when `from` is empty or does not occur.
// Complexity: O(|s| * |from|).
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
