// XIOM - String: Search
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.search

// Depends on: none

// ============================================================================
// Substring search helpers built on index_of: first/last occurrence, containment,
// occurrence counting, and multi-needle search. NOTE: current implementation
// lives in string.index_of - move the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Returns the byte offset of the first occurrence of `needle` in `s`, or
/// None when `needle` does not occur. An empty `needle` matches at offset 0.
/// Params: s the haystack; needle the substring to find.
/// Returns: Some(offset) on the first match, None when absent.
/// Error case: none.
/// Complexity: O(|s| * |needle|).
pub fn str_index_of(s: Str, needle: Str) -> Option[Int]
  ensures: needle.len() == 0 => result.is_some
{
  if string.str_len(needle) == 0 {
    return Some(0);
  };
  string.str_index_of(s, needle)
}

/// Returns the byte offset of the last occurrence of `needle` in `s`, or
/// None when `needle` does not occur. An empty `needle` matches at the end of
/// `s` (offset s.len()).
/// Params: s the haystack; needle the substring to find.
/// Returns: Some(offset) on the last match, None when absent.
/// Error case: none.
/// Complexity: O(|s| * |needle|).
pub fn str_last_index_of(s: Str, needle: Str) -> Option[Int]
  ensures: needle.len() == 0 => result.is_some
{
  if string.str_len(needle) == 0 {
    return Some(string.str_len(s));
  };
  string.str_rindex_of(s, needle)
}

/// Returns true when `s` contains `needle` at least once.
/// Params: s the haystack; needle the substring to look for.
/// Returns: true on a match, false otherwise (including an empty needle).
/// Error case: none.
/// Complexity: O(|s| * |needle|).
pub fn str_contains(s: Str, needle: Str) -> Bool
  ensures: needle.len() == 0 => result == true
{
  if string.str_len(needle) == 0 {
    return true;
  };
  string.str_contains(s, needle)
}

/// Returns true when `s` contains at least one of the needles.
/// Params: s the haystack; needles the list of substrings to look for.
/// Returns: true on the first needle found, false when none match.
/// Error case: none.
/// Complexity: O(k * |s| * max |needle|) where k = needles.len().
pub fn str_contains_any(s: Str, needles: &Vec[Str]) -> Bool
  ensures: needles.len() == 0 => result == false
{
  string.str_contains_any(s, needles)
}

/// Returns the number of non-overlapping occurrences of `needle` in `s`.
/// An empty `needle` yields 0 (an occurrence requires at least one byte).
/// Params: s the haystack; needle the substring to count.
/// Returns: the occurrence count (>= 0).
/// Error case: none.
/// Complexity: O(|s| * |needle|).
pub fn str_count_occurrences(s: Str, needle: Str) -> Int
  ensures: result >= 0
{
  let nlen = string.str_len(needle);
  let slen = string.str_len(s);
  if nlen == 0 || nlen > slen {
    return 0;
  };
  var count: Int = 0;
  var i: Int = 0;
  while i <= slen - nlen {
    let rem = string.str_slice(s, i, slen);
    if string.str_starts_with(rem, needle) {
      count = count + 1;
      i = i + nlen;
    } else {
      i = i + 1;
    };
  };
  count
}

/// Returns the byte offset of the earliest occurrence of any needle in `s`,
/// or None when none of the needles occur. When several needles match at the
/// same offset the first needle in `needles` wins. Empty needles match at
/// offset 0.
/// Params: s the haystack; needles the list of substrings to look for.
/// Returns: Some(offset) of the earliest match, None when none match.
/// Error case: none.
/// Complexity: O(k * |s| * max |needle|) where k = needles.len().
pub fn str_find_any(s: Str, needles: &Vec[Str]) -> Option[Int]
  ensures: needles.len() == 0 => result.is_some == false
{
  let ncount = needles.len();
  var best: Int = -1;
  var found = false;
  var i: Int = 0;
  while i < ncount {
    var nd = needles[i];
    let nlen = string.str_len(nd);
    var idx: Option[Int] = None;
    if nlen == 0 {
      idx = Some(0);
    } else {
      idx = string.str_index_of(s, nd);
    };
    match idx {
      Some(p) => {
        if !found || p < best {
          best = p;
          found = true;
        };
      };
      None => {};
    };
    i = i + 1;
  };
  if found {
    return Some(best);
  };
  None
}
