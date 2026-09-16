// XIOM - Sorting: Merge Sort
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.sort.merge

// Depends on: none

// ============================================================================
// Merge sort family: stable divide-and-conquer using O(n) auxiliary space.
// ============================================================================

/// Merge the sorted sub-ranges [lo..mid] and [mid+1..hi] of v using tmp as
/// scratch storage. Internal helper. O(n).
fn merge_merge(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, mid: Int, hi: Int) {
  var i = lo;
  while i <= hi {
    tmp[i - lo] = v[i];
    i = i + 1;
  }
  var li = 0;
  var ri = mid - lo + 1;
  var end_l = mid - lo;
  var end_r = hi - lo;
  var k = lo;
  while li <= end_l && ri <= end_r {
    if tmp[li] <= tmp[ri] {
      v[k] = tmp[li];
      li = li + 1;
    } else {
      v[k] = tmp[ri];
      ri = ri + 1;
    }
    k = k + 1;
  }
  while li <= end_l {
    v[k] = tmp[li];
    li = li + 1;
    k = k + 1;
  }
  while ri <= end_r {
    v[k] = tmp[ri];
    ri = ri + 1;
    k = k + 1;
  }
}

/// Merge sort the inclusive range v[lo..=hi]. Internal helper. O(n log n).
fn merge_sort_range(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  merge_sort_range(v, tmp, lo, mid);
  merge_sort_range(v, tmp, mid + 1, hi);
  merge_merge(v, tmp, lo, mid, hi);
}

/// Stable in-place merge sort of an Int vector. O(n log n) always, O(n) space.
pub fn merge_sort(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  var tmp = Vec[Int].new();
  var i = 0;
  while i < n {
    tmp.push(v[i]);
    i = i + 1;
  }
  merge_sort_range(v, &mut tmp, 0, n - 1);
}

/// Merge two sorted vectors into one sorted vector. O(a.len() + b.len()).
/// Both inputs must already be sorted in non-decreasing order.
pub fn merge(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  var j = 0;
  var an = a.len();
  var bn = b.len();
  while i < an && j < bn {
    if a[i] <= b[j] {
      out.push(a[i]);
      i = i + 1;
    } else {
      out.push(b[j]);
      j = j + 1;
    }
  }
  while i < an {
    out.push(a[i]);
    i = i + 1;
  }
  while j < bn {
    out.push(b[j]);
    j = j + 1;
  }
  out
}

/// Stable merge sort with a custom comparator. O(n log n), O(n) space.
/// The comparator must be a named function returning -1/0/1.
pub fn merge_sort_stable(v: &mut Vec[Int], compare: fn(&Int, &Int) -> Int) {
  var n = v.len();
  if n <= 1 { return; }
  var tmp = Vec[Int].new();
  var i = 0;
  while i < n {
    tmp.push(v[i]);
    i = i + 1;
  }
  merge_stable_range(v, &mut tmp, compare, 0, n - 1);
}

/// Comparator-based stable merge over the inclusive range. Internal helper.
fn merge_stable_range(v: &mut Vec[Int], tmp: &mut Vec[Int], compare: fn(&Int, &Int) -> Int, lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  merge_stable_range(v, tmp, compare, lo, mid);
  merge_stable_range(v, tmp, compare, mid + 1, hi);
  merge_stable_merge(v, tmp, compare, lo, mid, hi);
}

/// Comparator-based merge step. Internal helper.
fn merge_stable_merge(v: &mut Vec[Int], tmp: &mut Vec[Int], compare: fn(&Int, &Int) -> Int, lo: Int, mid: Int, hi: Int) {
  var i = lo;
  while i <= hi {
    tmp[i - lo] = v[i];
    i = i + 1;
  }
  var li = 0;
  var ri = mid - lo + 1;
  var end_l = mid - lo;
  var end_r = hi - lo;
  var k = lo;
  while li <= end_l && ri <= end_r {
    if compare(&tmp[li], &tmp[ri]) <= 0 {
      v[k] = tmp[li];
      li = li + 1;
    } else {
      v[k] = tmp[ri];
      ri = ri + 1;
    }
    k = k + 1;
  }
  while li <= end_l {
    v[k] = tmp[li];
    li = li + 1;
    k = k + 1;
  }
  while ri <= end_r {
    v[k] = tmp[ri];
    ri = ri + 1;
    k = k + 1;
  }
}

/// Natural merge sort: merge sort that exploits existing sorted runs.
/// O(n log n) worst case, O(n) when v is already sorted, O(n) space.
/// Stable.
pub fn natural_merge_sort(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  var tmp = Vec[Int].new();
  var i = 0;
  while i < n {
    tmp.push(v[i]);
    i = i + 1;
  }
  var width = 1;
  while width < n {
    var lo = 0;
    while lo < n {
      var mid = lo + width - 1;
      if mid >= n - 1 {
        lo = n;
      } else {
        var hi = mid + width;
        if hi > n - 1 { hi = n - 1; }
        merge_merge(v, &mut tmp, lo, mid, hi);
        lo = hi + 1;
      }
    }
    width = width * 2;
  }
}
