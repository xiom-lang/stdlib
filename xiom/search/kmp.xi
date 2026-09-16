// XIOM - Search: Knuth-Morris-Pratt
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.search.kmp

// Depends on: none

// ============================================================================
// KMP substring search: O(n + m) via the failure/prefix function.
// ============================================================================

/// Longest proper prefix-suffix lengths for each position of pattern.
/// pi[i] is the length of the longest proper prefix of pattern[0..=i] that is
/// also a suffix. O(m). Internal building block exposed for reuse.
pub fn kmp_prefix_table(pattern: Str) -> Vec[Int] {
  var m = pattern.len();
  var pi = Vec[Int].new();
  var i = 0;
  while i < m {
    pi.push(0);
    i = i + 1;
  }
  var j = 0;
  i = 1;
  while i < m {
    while j > 0 && pattern.char_at(i) != pattern.char_at(j) {
      j = pi[j - 1];
    }
    if pattern.char_at(i) == pattern.char_at(j) {
      j = j + 1;
    }
    pi[i] = j;
    i = i + 1;
  }
  pi
}

/// Start index of the first occurrence of pattern in text, or None. O(n + m).
/// Returns None when pattern is empty or longer than text.
pub fn kmp_search(text: Str, pattern: Str) -> Option[Int] {
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return None; }
  var pi = kmp_prefix_table(pattern);
  var j = 0;
  var i = 0;
  while i < n {
    while j > 0 && text.char_at(i) != pattern.char_at(j) {
      j = pi[j - 1];
    }
    if text.char_at(i) == pattern.char_at(j) {
      j = j + 1;
    }
    if j == m {
      return Some(i - m + 1);
    }
    i = i + 1;
  }
  None
}

/// Start indices of every (overlapping) occurrence of pattern in text. O(n+m).
/// Empty pattern yields an empty result.
pub fn kmp_search_all(text: Str, pattern: Str) -> Vec[Int] {
  var out = Vec[Int].new();
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return out; }
  var pi = kmp_prefix_table(pattern);
  var j = 0;
  var i = 0;
  while i < n {
    while j > 0 && text.char_at(i) != pattern.char_at(j) {
      j = pi[j - 1];
    }
    if text.char_at(i) == pattern.char_at(j) {
      j = j + 1;
    }
    if j == m {
      out.push(i - m + 1);
      j = pi[j - 1];
    }
    i = i + 1;
  }
  out
}

/// True if pattern occurs anywhere in text. O(n + m). Empty pattern is false.
pub fn kmp_contains(text: Str, pattern: Str) -> Bool {
  var r = kmp_search(text, pattern);
  match r {
    Some(_) => { return true; },
    None => {},
  }
  false
}

/// Number of non-overlapping occurrences of pattern in text. O(n + m).
/// Empty pattern yields 0.
pub fn kmp_count(text: Str, pattern: Str) -> Int {
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return 0; }
  var pi = kmp_prefix_table(pattern);
  var count = 0;
  var j = 0;
  var i = 0;
  while i < n {
    while j > 0 && text.char_at(i) != pattern.char_at(j) {
      j = pi[j - 1];
    }
    if text.char_at(i) == pattern.char_at(j) {
      j = j + 1;
    }
    if j == m {
      count = count + 1;
      j = 0;
    }
    i = i + 1;
  }
  count
}
