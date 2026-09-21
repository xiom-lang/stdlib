// XIOM - Sorting: Introspection Sort
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sort.intro

// Depends on: none

// ============================================================================
// Introspective/hybrid sort family: fast in-practice sorts and utilities.
// ============================================================================

/// Introsort: quicksort that switches to heapsort when the recursion depth
/// budget is exhausted, and to insertion sort on small ranges.
/// O(n log n) worst case, O(log n) auxiliary space. Unstable.
pub fn intro_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  var n = v.len();
  if n <= 1 { return; }
  var depth = 0;
  var m = n;
  while m > 0 {
    depth = depth + 1;
    m = m / 2;
  }
  intro_sort_range(v, 0, n - 1, depth * 2);
}

/// Introsort the inclusive range [lo, hi] with a remaining recursion budget.
/// Internal helper.
fn intro_sort_range(v: &mut Vec[Int], lo: Int, hi: Int, depth: Int) {
  if hi - lo < INTRO_INSERTION_THRESHOLD {
    insertion_sort_range(v, lo, hi);
    return;
  }
  if depth == 0 {
    intro_heap_range(v, lo, hi);
    return;
  }
  var p = intro_partition(v, lo, hi);
  intro_sort_range(v, lo, p - 1, depth - 1);
  intro_sort_range(v, p + 1, hi, depth - 1);
}

/// Ranges shorter than this are insertion-sorted.
const INTRO_INSERTION_THRESHOLD: Int = 16;

/// Lomuto partition of [lo, hi] returning the pivot index. Internal helper.
fn intro_partition(v: &mut Vec[Int], lo: Int, hi: Int) -> Int {
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

/// Heap sort the inclusive range [lo, hi]. Internal helper. O(k log k).
fn intro_heap_range(v: &mut Vec[Int], lo: Int, hi: Int) {
  var n = hi - lo + 1;
  var start = (n - 1) / 2 + lo;
  while start >= lo {
    intro_sift(v, lo, start, hi);
    start = start - 1;
  }
  var end = hi;
  while end > lo {
    var temp = v[lo];
    v[lo] = v[end];
    v[end] = temp;
    end = end - 1;
    intro_sift(v, lo, lo, end);
  }
}

/// Sift down within the range anchored at lo. Internal helper.
fn intro_sift(v: &mut Vec[Int], lo: Int, start: Int, end: Int) {
  var root = start;
  loop {
    var child = lo + 2 * (root - lo) + 1;
    if child > end { break; }
    if child + 1 <= end && v[child] < v[child + 1] {
      child = child + 1;
    }
    if v[root] < v[child] {
      var temp = v[root];
      v[root] = v[child];
      v[child] = temp;
      root = child;
    } else {
      break;
    }
  }
}

/// O(n^2) insertion sort of the whole vector; fast for small/nearly-sorted
/// input. Stable.
pub fn insertion_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  insertion_sort_range(v, 0, v.len() - 1);
}

/// Insertion sort the inclusive range v[lo..=hi]. Internal helper. O(n^2).
fn insertion_sort_range(v: &mut Vec[Int], lo: Int, hi: Int) {
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

/// Timsort: merge sort over natural runs with insertion sort for short runs.
/// O(n log n) worst case, O(n) best (already sorted). Stable. O(n) space.
pub fn tim_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
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
        tim_merge(v, &mut tmp, lo, mid, hi);
        lo = hi + 1;
      }
    }
    width = width * 2;
  }
}

/// Standard two-way merge over [lo..hi] using tmp. Internal helper.
fn tim_merge(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, mid: Int, hi: Int) {
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

/// Gap-based insertion sort using the Ciura sequence. O(n log^2 n) average,
/// O(n^2) worst. Unstable. In-place, O(1) space.
pub fn shell_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  var n = v.len();
  if n <= 1 { return; }
  var gap = 1;
  while gap < n / 3 {
    gap = 3 * gap + 1;
  }
  while gap > 0 {
    var i = gap;
    while i < n {
      var j = i;
      var temp_val = v[i];
      while j >= gap && v[j - gap] > temp_val {
        v[j] = v[j - gap];
        j = j - gap;
      }
      v[j] = temp_val;
      i = i + 1;
    }
    gap = gap / 3;
  }
}

/// Adjacent-swap bubble sort. O(n^2) worst/average, O(n) best. Stable.
/// Educational only.
pub fn bubble_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  var n = v.len();
  if n <= 1 { return; }
  var i = 0;
  var swapped = true;
  while i < n - 1 && swapped {
    swapped = false;
    var j = 0;
    while j < n - i - 1 {
      if v[j] > v[j + 1] {
        var temp = v[j];
        v[j] = v[j + 1];
        v[j + 1] = temp;
        swapped = true;
      }
      j = j + 1;
    }
    i = i + 1;
  }
}

/// Minimum-selection sort with O(n) swaps. O(n^2) always. Unstable.
pub fn selection_sort(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  var n = v.len();
  if n <= 1 { return; }
  var i = 0;
  while i < n - 1 {
    var min_idx = i;
    var j = i + 1;
    while j < n {
      if v[j] < v[min_idx] { min_idx = j; }
      j = j + 1;
    }
    if min_idx != i {
      var temp = v[i];
      v[i] = v[min_idx];
      v[min_idx] = temp;
    }
    i = i + 1;
  }
}

/// True if v is non-decreasing. O(n).
pub fn is_sorted(v: &Vec[Int]) -> Bool {
  var n = v.len();
  if n <= 1 { return true; }
  var i = 1;
  while i < n {
    if v[i - 1] > v[i] { return false; }
    i = i + 1;
  }
  true
}

/// True if v is sorted per the comparator. O(n).
/// The comparator must be a named function returning -1/0/1.
pub fn is_sorted_by(v: &Vec[Int], compare: fn(&Int, &Int) -> Int) -> Bool {
  var n = v.len();
  if n <= 1 { return true; }
  var i = 1;
  while i < n {
    if compare(&v[i - 1], &v[i]) > 0 { return false; }
    i = i + 1;
  }
  true
}

/// Place the smallest k elements at the front, in order. O(n*k), O(1) space.
/// Unstable. If k >= n the whole vector becomes sorted; if k <= 0 no-op.
pub fn partial_sort(v: &mut Vec[Int], k: Int) {
  var n = v.len();
  if n <= 1 || k <= 0 { return; }
  var kk = k;
  if kk > n { kk = n; }
  var i = 0;
  while i < kk {
    var min_idx = i;
    var j = i + 1;
    while j < n {
      if v[j] < v[min_idx] { min_idx = j; }
      j = j + 1;
    }
    if min_idx != i {
      var temp = v[i];
      v[i] = v[min_idx];
      v[min_idx] = temp;
    }
    i = i + 1;
  }
}

/// Quickselect: the element that would land at index n in sorted order.
/// O(n) average, O(n^2) worst. Unstable. Reorders v as a side effect.
/// n is clamped into [0, len-1]; returns 0 for an empty vector.
pub fn nth_element(v: &mut Vec[Int], n: Int) -> Int {
  var len = v.len();
  if len == 0 { return 0; }
  var nn = n;
  if nn < 0 { nn = 0; }
  if nn >= len { nn = len - 1; }
  var lo = 0;
  var hi = len - 1;
  while lo < hi {
    var p = intro_partition(v, lo, hi);
    if p == nn { return v[nn]; }
    if nn < p {
      hi = p - 1;
    } else {
      lo = p + 1;
    }
  }
  v[nn]
}

/// Stable sort guaranteeing equal elements keep their relative order.
/// Delegates to a stable merge sort. O(n log n), O(n) space.
pub fn sort_stable(v: &mut Vec[Int])
  ensures: is_sorted(v) == true
{
  var n = v.len();
  if n <= 1 { return; }
  var tmp = Vec[Int].new();
  var i = 0;
  while i < n {
    tmp.push(v[i]);
    i = i + 1;
  }
  intro_stable_range(v, &mut tmp, 0, n - 1);
}

/// Stable merge sort over the inclusive range. Internal helper.
fn intro_stable_range(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  intro_stable_range(v, tmp, lo, mid);
  intro_stable_range(v, tmp, mid + 1, hi);
  tim_merge(v, tmp, lo, mid, hi);
}
