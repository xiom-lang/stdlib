// XIOM - Search: Linear Search
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.search.linear

// Depends on: none

// ============================================================================
// Linear search family: O(n) sequential scan over unsorted or sorted data.
// ============================================================================

/// Index of the first occurrence of target, or None. O(n). Works on any data.
pub fn linear_search(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  var i = 0;
  while i < n {
    if v[i] == target {
      return Some(i);
    }
    i = i + 1;
  }
  None
}

/// Index of the first occurrence of target at or after start, or None. O(n).
/// A negative start behaves as 0; a start beyond the end yields None.
pub fn linear_search_from(v: &Vec[Int], target: Int, start: Int) -> Option[Int] {
  var n = v.len();
  var i = start;
  if i < 0 { i = 0; }
  while i < n {
    if v[i] == target {
      return Some(i);
    }
    i = i + 1;
  }
  None
}

/// Indices of every occurrence of target, in ascending order. O(n).
pub fn linear_search_all(v: &Vec[Int], target: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var n = v.len();
  var i = 0;
  while i < n {
    if v[i] == target {
      out.push(i);
    }
    i = i + 1;
  }
  out
}

/// Index of the first element satisfying pred, or None. O(n). Short-circuits.
/// The predicate must be a named function.
pub fn linear_search_by(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Option[Int] {
  var n = v.len();
  var i = 0;
  while i < n {
    var x = v[i];
    if pred(&x) {
      return Some(i);
    }
    i = i + 1;
  }
  None
}
