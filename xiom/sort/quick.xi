// XIOM - Sorting: Quick Sort
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sort.quick

// Depends on: none

// ============================================================================
// Quick sort family: divide-and-conquer with pivot partitioning.
// ============================================================================

/// Ranges shorter than this are sorted with insertion sort.
const QUICK_INSERTION_THRESHOLD: Int = 12;

/// Insertion sort over the inclusive range [lo, hi] of an Int vector. O(n^2).
/// Used for small ranges where it beats recursion.
fn insertion_range(v: &mut Vec[Int], lo: Int, hi: Int) {
  var i = lo + 1;
  while i <= hi {
    var j = i;
    while j > lo && v[j - 1] > v[j] {
      var temp = v[j - 1];
      v[j - 1] = v[j];
      v[j] = temp;
      j = j - 1;
    }
    i = i + 1;
  }
}

/// Quicksort the inclusive range v[lo..=hi] in place. Internal helper.
fn quick_sort_range(v: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  if hi - lo < QUICK_INSERTION_THRESHOLD {
    insertion_range(v, lo, hi);
    return;
  }
  var p = partition(v, lo, hi);
  quick_sort_range(v, lo, p - 1);
  quick_sort_range(v, p + 1, hi);
}

/// Lomuto partition of v[lo..=hi]; returns the final pivot index. Internal.
fn partition(v: &mut Vec[Int], lo: Int, hi: Int) -> Int {
  var pivot = v[hi];
  var i = lo;
  var j = lo;
  while j < hi {
    if v[j] <= pivot {
      var temp = v[i];
      v[i] = v[j];
      v[j] = temp;
      i = i + 1;
    }
    j = j + 1;
  }
  var swap_temp = v[i];
  v[i] = v[hi];
  v[hi] = swap_temp;
  i
}

/// In-place quicksort of an Int vector. O(n log n) average, O(n^2) worst.
/// Unstable. Small ranges use insertion sort for speed.
pub fn quick_sort(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  quick_sort_range(v, 0, n - 1);
}

/// Quicksort with a custom comparator. O(n log n) average, O(n^2) worst.
/// Unstable. The comparator must be a named function returning -1/0/1.
pub fn quick_sort_by(v: &mut Vec[Int], compare: fn(&Int, &Int) -> Int) {
  var n = v.len();
  if n <= 1 { return; }
  quick_sort_by_range(v, compare, 0, n - 1);
}

/// Internal quicksort range helper using a comparator.
fn quick_sort_by_range(v: &mut Vec[Int], compare: fn(&Int, &Int) -> Int, lo: Int, hi: Int) {
  if lo >= hi { return; }
  var pivot = v[lo];
  var i = lo + 1;
  var j = hi;
  while i <= j {
    while i <= j && compare(&v[i], &pivot) <= 0 { i = i + 1; }
    while j >= i && compare(&v[j], &pivot) > 0 { j = j - 1; }
    if i < j {
      var temp = v[i];
      v[i] = v[j];
      v[j] = temp;
    }
  }
  var swap_temp = v[lo];
  v[lo] = v[j];
  v[j] = swap_temp;
  quick_sort_by_range(v, compare, lo, j - 1);
  quick_sort_by_range(v, compare, j + 1, hi);
}

/// Quickselect: returns the k-th smallest element (0-based) of v, reordering v.
/// O(n) average, O(n^2) worst. Unstable. k is clamped into [0, len-1];
/// returns 0 for an empty vector.
pub fn quick_select(v: &mut Vec[Int], k: Int) -> Int {
  var n = v.len();
  if n == 0 { return 0; }
  var kk = k;
  if kk < 0 { kk = 0; }
  if kk >= n { kk = n - 1; }
  var lo = 0;
  var hi = n - 1;
  while lo < hi {
    var p = partition(v, lo, hi);
    if p == kk { return v[kk]; }
    if p < kk {
      lo = p + 1;
    } else {
      hi = p - 1;
    }
  }
  v[kk]
}

/// Quicksort with 3-way (Dutch national flag) partitioning.
/// O(n log n) average, O(n^2) worst. Unstable.
/// Handles vectors with many duplicate values efficiently.
pub fn quick_sort_3way(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  quick_sort_3way_range(v, 0, n - 1);
}

/// Internal 3-way partition range helper.
fn quick_sort_3way_range(v: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var pivot = v[lo];
  var lt = lo;
  var gt = hi;
  var i = lo + 1;
  while i <= gt {
    if v[i] < pivot {
      var temp = v[i];
      v[i] = v[lt];
      v[lt] = temp;
      lt = lt + 1;
      i = i + 1;
    } elif v[i] > pivot {
      var temp = v[i];
      v[i] = v[gt];
      v[gt] = temp;
      gt = gt - 1;
    } else {
      i = i + 1;
    }
  }
  quick_sort_3way_range(v, lo, lt - 1);
  quick_sort_3way_range(v, gt + 1, hi);
}
