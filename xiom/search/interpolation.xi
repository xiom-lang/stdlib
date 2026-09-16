// XIOM - Search: Interpolation Search
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.search.interpolation

// Depends on: none

// ============================================================================
// Position-estimating and skip-step searches for sorted data.
// ============================================================================

/// Index of target via value-proportional probing. O(log log n) average on
/// uniformly distributed sorted Int arrays, O(n) worst. Returns Some(index)
/// or None. Safe on unsorted data (degrades to a probe sequence).
pub fn interpolation_search(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi && target >= v[lo] && target <= v[hi] {
    if lo == hi {
      if v[lo] == target { return Some(lo); }
      return None;
    }
    var denom = v[hi] - v[lo];
    var pos = lo;
    if denom != 0 {
      pos = lo + ((target - v[lo]) * (hi - lo)) / denom;
    }
    if pos < lo { pos = lo; }
    if pos > hi { pos = hi; }
    if v[pos] == target {
      return Some(pos);
    }
    if v[pos] < target {
      lo = pos + 1;
    } else {
      hi = pos - 1;
    }
  }
  None
}

/// Interpolation search assuming the input is already sorted. O(log log n)
/// average, O(n) worst. Identical probing logic to interpolation_search; the
/// separate entry point documents the sortedness precondition.
pub fn interpolation_search_sorted(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  var lo = 0;
  var hi = n - 1;
  while lo <= hi && target >= v[lo] && target <= v[hi] {
    if lo == hi {
      if v[lo] == target { return Some(lo); }
      return None;
    }
    var denom = v[hi] - v[lo];
    var pos = lo;
    if denom != 0 {
      pos = lo + ((target - v[lo]) * (hi - lo)) / denom;
    }
    if pos < lo { pos = lo; }
    if pos > hi { pos = hi; }
    if v[pos] == target {
      return Some(pos);
    }
    if v[pos] < target {
      lo = pos + 1;
    } else {
      hi = pos - 1;
    }
  }
  None
}

/// Internal binary search over [lo, hi] of a sorted vector.
fn exp_binary(v: &Vec[Int], target: Int, lo: Int, hi: Int) -> Option[Int] {
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

/// Exponential (galloping) search: finds a bounding range [2^(k-1), 2^k]
/// then binary-searches it. O(log i) where i is the target index. Requires a
/// sorted vector.
pub fn exponential_search(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  if v[0] == target {
    return Some(0);
  }
  var bound = 1;
  while bound < n && v[bound] < target {
    bound = bound * 2;
  }
  var hi = bound;
  if hi >= n { hi = n - 1; }
  var lo = bound / 2;
  exp_binary(v, target, lo, hi)
}

/// Internal integer sqrt helper for the jump step size.
fn jump_step(n: Int) -> Int {
  var step = 0;
  while step * step <= n {
    step = step + 1;
  }
  step - 1
}

/// Jump search: jumps ahead by sqrt(n) blocks then linearly scans the target
/// block. O(sqrt(n)). Requires a sorted vector.
pub fn jump_search(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  var step = jump_step(n);
  var prev = 0;
  var curr = step;
  if curr > n - 1 { curr = n - 1; }
  while curr < n && v[curr] < target {
    prev = curr;
    curr = curr + step;
    if curr > n - 1 { curr = n - 1; }
    if prev >= n { return None; }
  }
  var i = prev;
  var end = curr;
  if end >= n { end = n - 1; }
  while i <= end {
    if v[i] == target {
      return Some(i);
    }
    i = i + 1;
  }
  None
}

/// Ternary search over a unimodal f on [lo, hi]: returns the x maximizing f.
/// O(log n) iterations. f must be a named function; the curve must be
/// strictly unimodal over the range.
pub fn ternary_search(f: fn(Int) -> Int, lo: Int, hi: Int) -> Int {
  var left = lo;
  var right = hi;
  while right - left > 2 {
    var m1 = left + (right - left) / 3;
    var m2 = right - (right - left) / 3;
    if f(m1) < f(m2) {
      left = m1;
    } else {
      right = m2;
    }
  }
  var best = left;
  var best_val = f(left);
  var i = left + 1;
  while i <= right {
    var val = f(i);
    if val > best_val {
      best_val = val;
      best = i;
    }
    i = i + 1;
  }
  best
}

/// Fibonacci-number-stepped search of a sorted vector. O(log n).
pub fn fibonacci_search(v: &Vec[Int], target: Int) -> Option[Int] {
  var n = v.len();
  if n == 0 { return None; }
  var f2 = 0;
  var f1 = 1;
  var f = f2 + f1;
  while f < n {
    f2 = f1;
    f1 = f;
    f = f2 + f1;
  }
  var offset = -1;
  while f > 1 {
    var i = offset + f2;
    if i < 0 { i = 0; }
    if i >= n { i = n - 1; }
    if v[i] < target {
      f = f1;
      f1 = f2;
      f2 = f - f1;
      offset = i;
    } elif v[i] > target {
      f = f2;
      f1 = f1 - f2;
      f2 = f - f1;
    } else {
      return Some(i);
    }
  }
  var last = offset + 1;
  if last < 0 { last = 0; }
  if last < n && v[last] == target {
    return Some(last);
  }
  None
}
