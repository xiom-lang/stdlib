// XIOM -- Search Algorithms
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.search

use xiom.search.linear;
use xiom.search.binary;
use xiom.search.interpolation;
use xiom.search.kmp;
use xiom.search.boyer;

use xiom.cmp;
use xiom.cmp.min_int;
use xiom.cmp.max_int;

/// Linear search -- O(n) worst/average, O(1) best.
/// Scans the array sequentially from index 0. Works on unsorted data.
/// Returns Some(index) of the first match, or None if not found.
pub fn linear_search[T: Eq](arr: &Vec[T], target: &T) -> Option[Int] {
  var n = arr.len();
  var i = 0;
  while i < n {
    if arr[i].eq(target) {
      return Some(i);
    }
    i = i + 1;
  }
  return None;
}

/// Binary search -- O(log n). Requires a sorted array (non-decreasing).
/// Classic divide-and-conquer: repeatedly narrows the range by comparing
/// the middle element against the target.
/// Returns Some(index) if found, or None if not present.
pub fn binary_search[T: Ord](arr: &Vec[T], target: &T) -> Option[Int] {
  var n = arr.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi {
    var mid = lo + (hi - lo) / 2;
    var cmp = arr[mid].compare(target);
    if cmp == 0 {
      return Some(mid);
    } elif cmp < 0 {
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return None;
}

/// Interpolation search -- O(log log n) average on uniformly distributed
/// sorted Int arrays, O(n) worst. Analogous to how one searches a phone book:
/// estimates position based on value range.
/// Returns Some(index) if found, or None if not present.
pub fn interpolation_search(arr: &Vec[Int], target: Int) -> Option[Int] {
  var n = arr.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi && target >= arr[lo] && target <= arr[hi] {
    if lo == hi {
      if arr[lo] == target { return Some(lo); }
      return None;
    }
    // estimate position: proportion of (target - arr[lo]) / (arr[hi] - arr[lo])
    var denom = arr[hi] - arr[lo];
    var pos = lo;
    if denom != 0 {
      pos = lo + ((target - arr[lo]) * (hi - lo)) / denom;
    }
    if pos < lo { pos = lo; }
    if pos > hi { pos = hi; }
    if arr[pos] == target {
      return Some(pos);
    }
    if arr[pos] < target {
      lo = pos + 1;
    } else {
      hi = pos - 1;
    }
  }
  return None;
}

// ---------------------------------------------------------------------------
// Exponential (galloping) search -- O(log i) where i is the target index.
// Best for unbounded/infinite arrays or when the target is near the start.
// First finds a range [2^(k-1), 2^k] where target lies, then binary searches.
// Requires sorted array.
// ---------------------------------------------------------------------------

fn exp_binary_search[T: Ord](arr: &Vec[T], target: &T, lo: Int, hi: Int) -> Option[Int] {
  var left = lo;
  var right = hi;
  while left <= right {
    var mid = left + (right - left) / 2;
    var cmp = arr[mid].compare(target);
    if cmp == 0 {
      return Some(mid);
    } elif cmp < 0 {
      left = mid + 1;
    } else {
      right = mid - 1;
    }
  }
  return None;
}

pub fn exponential_search[T: Ord](arr: &Vec[T], target: &T) -> Option[Int] {
  var n = arr.len();
  if n == 0 { return None; }
  if arr[0].compare(target) == 0 {
    return Some(0);
  }
  var bound = 1;
  while bound < n && arr[bound].compare(target) < 0 {
    bound = bound * 2;
  }
  var hi = bound;
  if hi >= n { hi = n - 1; }
  var lo = bound / 2;
  return exp_binary_search(arr, target, lo, hi);
}

// ---------------------------------------------------------------------------
// Jump search -- O(sqrtn). Requires sorted array.
// Jumps ahead by fixed step size (sqrtn) until the element at the jump position
// exceeds the target, then linear-searches the previous block.
// ---------------------------------------------------------------------------

fn jump_sqrt(n: Int) -> Int {
  var step = 0;
  while step * step <= n {
    step = step + 1;
  }
  return step - 1;
}

pub fn jump_search[T: Ord](arr: &Vec[T], target: &T) -> Option[Int] {
  var n = arr.len();
  if n == 0 { return None; }
  var step = jump_sqrt(n);
  var prev = 0;
  var curr = step;
  if curr > n - 1 { curr = n - 1; }
  while curr < n && arr[curr].compare(target) < 0 {
    prev = curr;
    curr = curr + step;
    if curr > n - 1 { curr = n - 1; }
    if prev >= n { return None; }
  }
  // linear search within [prev, min(curr, n-1)]
  var i = prev;
  var end = curr;
  if end >= n { end = n - 1; }
  while i <= end {
    if arr[i].compare(target) == 0 {
      return Some(i);
    }
    i = i + 1;
  }
  return None;
}

/// lower_bound -- O(log n). Returns the index of the first element >= target.
/// If all elements are < target, returns arr.len().
/// Requires sorted array.
pub fn lower_bound[T: Ord](arr: &Vec[T], target: &T) -> Int {
  var n = arr.len();
  var lo = 0;
  var hi = n;
  while lo < hi {
    var mid = lo + (hi - lo) / 2;
    if arr[mid].compare(target) < 0 {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// upper_bound -- O(log n). Returns the index of the first element > target.
/// If all elements are <= target, returns arr.len().
/// Requires sorted array.
pub fn upper_bound[T: Ord](arr: &Vec[T], target: &T) -> Int {
  var n = arr.len();
  var lo = 0;
  var hi = n;
  while lo < hi {
    var mid = lo + (hi - lo) / 2;
    if arr[mid].compare(target) <= 0 {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// binary_search_range -- O(log n). Returns (lower_bound, upper_bound) as a
/// tuple: [lo, hi) of all indices where arr[i] == target.
/// If target is not found, lo == hi (empty range).
/// Requires sorted array.
pub fn binary_search_range[T: Ord](arr: &Vec[T], target: &T) -> (Int, Int) {
  var lo = lower_bound(arr, target);
  if lo == arr.len() || arr[lo].compare(target) != 0 {
    return (lo, lo);
  }
  var hi = upper_bound(arr, target);
  return (lo, hi);
}
