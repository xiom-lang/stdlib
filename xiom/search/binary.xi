// XIOM - Search: Binary Search
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.search.binary

// Depends on: none

// ============================================================================
// Binary search family: O(log n) search and bounds on sorted arrays.
// ============================================================================

/// Index of target in a sorted v, or None. O(log n). Requires v to be sorted
/// in non-decreasing order.
pub fn binary_search(v: &Vec[Int], target: Int) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value < v.len()
{
  var n = v.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi {
    var mid = lo + (hi - lo) / 2;
    if v[mid] == target {
      return Some(mid);
    } elif v[mid] < target {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  None
}

/// Binary search restricted to the inclusive range v[lo..=hi]. O(log n).
/// Returns None when the range is empty, inverted, or out of bounds.
pub fn binary_search_range(v: &Vec[Int], target: Int, lo: Int, hi: Int) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value < v.len()
{
  var n = v.len();
  if lo < 0 || hi >= n || lo > hi { return None; }
  var left = lo;
  var right = hi;
  while left <= right {
    var mid = left + (right - left) / 2;
    if v[mid] == target {
      return Some(mid);
    } elif v[mid] < target {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }
  None
}

/// Index of the first element >= target; v.len() if none. O(log n).
/// Requires v to be sorted.
pub fn lower_bound(v: &Vec[Int], target: Int) -> Int
  ensures: result >= 0 && result <= v.len()
{
  var n = v.len();
  var lo = 0;
  var hi = n;
  while lo < hi {
    var mid = lo + (hi - lo) / 2;
    if v[mid] < target {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  lo
}

/// Index of the first element > target; v.len() if none. O(log n).
/// Requires v to be sorted.
pub fn upper_bound(v: &Vec[Int], target: Int) -> Int
  ensures: result >= 0 && result <= v.len()
{
  var n = v.len();
  var lo = 0;
  var hi = n;
  while lo < hi {
    var mid = lo + (hi - lo) / 2;
    if v[mid] <= target {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  lo
}

/// Binary search with a custom comparator: compare(&v[mid], &target).
/// O(log n). The comparator must be a named function returning -1/0/1.
/// Requires v to be sorted per the comparator.
pub fn binary_search_by(v: &Vec[Int], target: Int, compare: fn(&Int, &Int) -> Int) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value < v.len()
{
  var n = v.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi {
    var mid = lo + (hi - lo) / 2;
    var c = compare(&v[mid], &target);
    if c == 0 {
      return Some(mid);
    } elif c < 0 {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  None
}

/// (lo, hi) tuple: all occurrences of target span the half-open index range
/// [lo, hi). If target is absent, lo == hi (empty range). O(log n).
pub fn search_range(v: &Vec[Int], target: Int) -> (Int, Int)
  ensures: result.0 >= 0 && result.1 >= result.0 && result.1 <= v.len()
{
  var lo = lower_bound(v, target);
  var n = v.len();
  if lo == n || v[lo] != target {
    return (lo, lo);
  }
  var hi = upper_bound(v, target);
  (lo, hi)
}

/// Binary search for an exact float value in a sorted Vec[Float64].
/// O(log n). Requires v to be sorted ascending (exact IEEE-754 equality
/// semantics: -0.0 and +0.0 compare equal; NaN never matches because
/// NaN == NaN is false). Returns None when target is absent.
pub fn binary_search_float(v: &Vec[Float64], target: Float64) -> Option[Int]
  ensures: result is Some => result.value >= 0 && result.value < v.len()
{
  var n = v.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi {
    var mid = lo + (hi - lo) / 2;
    var m = v[mid];
    if m == target {
      return Some(mid);
    } elif m < target {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  None
}
