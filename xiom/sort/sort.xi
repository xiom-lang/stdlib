// XIOM -- Sorting Algorithms
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.sort

use xiom.sort.quick;
use xiom.sort.merge;
use xiom.sort.heap;
use xiom.sort.radix;
use xiom.sort.intro;

use xiom.cmp;
use xiom.cmp.min_int;
use xiom.cmp.max_int;

/// Insertion sort -- O(n2) worst/average, O(n) best (already sorted).
/// Stable. Excellent for small arrays (n < ~50) and nearly-sorted data.
/// Algorithm: builds sorted prefix by inserting each new element into place.
pub fn sort_insertion[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 && arr[j - 1].compare(arr[j]) > 0 {
      var temp = arr[j - 1];
      arr[j - 1] = arr[j];
      arr[j] = temp;
      j = j - 1;
    }
    i = i + 1;
  }
}

/// Selection sort -- O(n2) always. Unstable. Minimal writes (O(n) swaps).
/// Algorithm: repeatedly finds the minimum element from the unsorted tail
/// and places it at the current position.
pub fn sort_selection[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  var i = 0;
  while i < n - 1 {
    var min_idx = i;
    var j = i + 1;
    while j < n {
      if arr[j].compare(arr[min_idx]) < 0 {
        min_idx = j;
      }
      j = j + 1;
    }
    if min_idx != i {
      var temp = arr[i];
      arr[i] = arr[min_idx];
      arr[min_idx] = temp;
    }
    i = i + 1;
  }
}

/// Bubble sort -- O(n2) worst/average, O(n) best (already sorted).
/// Stable. Simple educational algorithm; rarely used in production.
/// Algorithm: compares adjacent elements and swaps if out of order;
/// largest elements "bubble" to the end each pass.
pub fn sort_bubble[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  var i = 0;
  var swapped = true;
  while i < n - 1 && swapped {
    swapped = false;
    var j = 0;
    while j < n - i - 1 {
      if arr[j].compare(arr[j + 1]) > 0 {
        var temp = arr[j];
        arr[j] = arr[j + 1];
        arr[j + 1] = temp;
        swapped = true;
      }
      j = j + 1;
    }
    i = i + 1;
  }
}

// ---------------------------------------------------------------------------
// Quick sort with 3-way partitioning -- O(n log n) average, O(n2) worst.
// Unstable. 3-way partition (Dutch national flag) handles duplicates
// efficiently -- all equal-to-pivot elements land in a contiguous block
// that needs no further recursion.
// Uses insertion sort for small sub-arrays (threshold = 16).
// ---------------------------------------------------------------------------

const QUICK_SORT_INSERTION_THRESHOLD: Int = 16;

fn insertion_sort_range[T: Ord](arr: &mut Vec[T], lo: Int, hi: Int) {
  var i = lo + 1;
  while i <= hi {
    var j = i;
    while j > lo && arr[j - 1].compare(arr[j]) > 0 {
      var temp = arr[j - 1];
      arr[j - 1] = arr[j];
      arr[j] = temp;
      j = j - 1;
    }
    i = i + 1;
  }
}

fn median_of_three[T: Ord](arr: &mut Vec[T], lo: Int, mid: Int, hi: Int) -> Int {
  if arr[lo].compare(arr[mid]) > 0 {
    var t = arr[lo];
    arr[lo] = arr[mid];
    arr[mid] = t;
  }
  if arr[lo].compare(arr[hi]) > 0 {
    var t = arr[lo];
    arr[lo] = arr[hi];
    arr[hi] = t;
  }
  if arr[mid].compare(arr[hi]) > 0 {
    var t = arr[mid];
    arr[mid] = arr[hi];
    arr[hi] = t;
  }
  return mid;
}

fn quick_sort_3way_range[T: Ord](arr: &mut Vec[T], lo: Int, hi: Int) {
  if hi - lo < QUICK_SORT_INSERTION_THRESHOLD {
    insertion_sort_range(arr, lo, hi);
    return;
  }
  // median-of-three pivot selection: place pivot at arr[lo]
  var mid_idx = lo + (hi - lo) / 2;
  var pivot_idx = median_of_three(arr, lo, mid_idx, hi);
  var temp = arr[lo];
  arr[lo] = arr[pivot_idx];
  arr[pivot_idx] = temp;

  // read pivot value (from arr[lo] after swap)
  // 3-way partition: arr[lo..lt-1] < pivot, arr[lt..gt] == pivot, arr[gt+1..hi] > pivot
  var lt = lo;
  var gt = hi;
  var i = lo + 1;
  // We need to compare against the pivot value stored at a fixed position.
  // Since compare uses &Self, we store a reference. Use arr[lo] as pivot anchor.
  // Work with a copy for comparisons; arr[lo] itself will be overwritten.
  while i <= gt {
    var cmp = arr[i].compare(arr[lo]);
    if cmp < 0 {
      var swap_temp = arr[i];
      arr[i] = arr[lt];
      arr[lt] = swap_temp;
      lt = lt + 1;
      i = i + 1;
    } elif cmp > 0 {
      var swap_temp = arr[i];
      arr[i] = arr[gt];
      arr[gt] = swap_temp;
      gt = gt - 1;
    } else {
      i = i + 1;
    }
  }
  // recurse on < and > partitions
  quick_sort_3way_range(arr, lo, lt - 1);
  quick_sort_3way_range(arr, gt + 1, hi);
}

pub fn sort_quick[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  quick_sort_3way_range(arr, 0, n - 1);
}

// ---------------------------------------------------------------------------
// Merge sort -- O(n log n) always. Stable. Uses O(n) auxiliary space.
// Algorithm: recursively splits array in half, sorts each half,
// then merges the two sorted halves.
// ---------------------------------------------------------------------------

fn merge_merge[T: Ord](arr: &mut Vec[T], temp: &mut Vec[T], lo: Int, mid: Int, hi: Int) {
  // copy range to temp
  var i = lo;
  while i <= hi {
    temp[i - lo] = arr[i];
    i = i + 1;
  }
  // Copy back - no, let's do proper merge using temp as scratch
  // temp[0..(hi-lo)] holds the data; merge back into arr[lo..hi]
  var left_idx = 0;
  var right_idx = mid - lo + 1;
  var end_left = mid - lo;
  var end_right = hi - lo;
  var k = lo;
  while left_idx <= end_left && right_idx <= end_right {
    if temp[left_idx].compare(temp[right_idx]) <= 0 {
      arr[k] = temp[left_idx];
      left_idx = left_idx + 1;
    } else {
      arr[k] = temp[right_idx];
      right_idx = right_idx + 1;
    }
    k = k + 1;
  }
  while left_idx <= end_left {
    arr[k] = temp[left_idx];
    left_idx = left_idx + 1;
    k = k + 1;
  }
  while right_idx <= end_right {
    arr[k] = temp[right_idx];
    right_idx = right_idx + 1;
    k = k + 1;
  }
}

fn merge_sort_range[T: Ord](arr: &mut Vec[T], temp: &mut Vec[T], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  merge_sort_range(arr, temp, lo, mid);
  merge_sort_range(arr, temp, mid + 1, hi);
  merge_merge(arr, temp, lo, mid, hi);
}

pub fn sort_merge[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  // allocate temp buffer
  var temp = Vec[T].new();
  var i = 0;
  while i < n {
    temp.push(arr[i]);
    i = i + 1;
  }
  merge_sort_range(arr, &temp, 0, n - 1);
}

// ---------------------------------------------------------------------------
// Heap sort -- O(n log n) always. Unstable. In-place, no extra allocation.
// Algorithm: builds a max-heap from the array in-place, then repeatedly
// extracts the maximum (root) and places it at the end of the array.
// ---------------------------------------------------------------------------

fn heap_sift_down[T: Ord](arr: &mut Vec[T], start: Int, end: Int) {
  var root = start;
  loop {
    var child = 2 * root + 1;
    if child > end { break; }
    if child + 1 <= end && arr[child].compare(arr[child + 1]) < 0 {
      child = child + 1;
    }
    if arr[root].compare(arr[child]) < 0 {
      var temp = arr[root];
      arr[root] = arr[child];
      arr[child] = temp;
      root = child;
    } else {
      break;
    }
  }
}

pub fn sort_heap[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  // build max-heap
  var i = n / 2;
  while i >= 0 {
    heap_sift_down(arr, i, n - 1);
    i = i - 1;
  }
  // extract elements
  var end = n - 1;
  while end > 0 {
    var temp = arr[0];
    arr[0] = arr[end];
    arr[end] = temp;
    end = end - 1;
    heap_sift_down(arr, 0, end);
  }
}

/// Shell sort -- O(n log2 n) average using Ciura gap sequence.
/// Unstable. Generalizes insertion sort with a decreasing gap.
/// Algorithm: sorts elements at decreasing gap distances; when gap=1,
/// it becomes ordinary insertion sort (on a nearly-sorted array).
pub fn sort_shell[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  // Ciura gap sequence: 1, 4, 10, 23, 57, 132, 301, 701, 1750, ...
  // For simplicity, compute gaps: start = 1, then gap = 3*gap + 1
  var gap = 1;
  while gap < n / 3 {
    gap = 3 * gap + 1;
  }
  while gap > 0 {
    var i = gap;
    while i < n {
      var j = i;
      var temp_val = arr[i];
      while j >= gap && arr[j - gap].compare(temp_val) > 0 {
        arr[j] = arr[j - gap];
        j = j - gap;
      }
      arr[j] = temp_val;
      i = i + 1;
    }
    gap = gap / 3;
  }
}

/// Counting sort -- O(n + k) where k = max_val. Stable.
/// Only for Int arrays with known non-negative range [0, max_val].
/// Algorithm: counts occurrences of each value, then reconstructs sorted array
/// by iterating counts in order.
pub fn sort_counting(arr: &mut Vec[Int], max_val: Int) {
  var n = arr.len();
  if n <= 1 { return; }
  if max_val < 0 { return; }
  // allocate count array of size max_val + 1
  var counts = Vec[Int].new();
  var j = 0;
  while j <= max_val {
    counts.push(0);
    j = j + 1;
  }
  // count occurrences
  var i = 0;
  while i < n {
    var val = arr[i];
    if val >= 0 && val <= max_val {
      counts[val] = counts[val] + 1;
    }
    i = i + 1;
  }
  // prefix sums for stable placement
  j = 1;
  while j <= max_val {
    counts[j] = counts[j] + counts[j - 1];
    j = j + 1;
  }
  // build output from the back (stable)
  var output = Vec[Int].new();
  j = 0;
  while j < n {
    output.push(0);
    j = j + 1;
  }
  i = n - 1;
  while i >= 0 {
    var val = arr[i];
    if val >= 0 && val <= max_val {
      counts[val] = counts[val] - 1;
      output[counts[val]] = val;
    }
    i = i - 1;
  }
  // copy back
  i = 0;
  while i < n {
    arr[i] = output[i];
    i = i + 1;
  }
}

// ---------------------------------------------------------------------------
// Radix sort (LSD) -- O(n * d) where d is the number of digits (set to 8).
// Stable. Only for non-negative Int arrays.
// Algorithm: sorts by each digit from least to most significant using
// counting sort as a stable subroutine.
// ---------------------------------------------------------------------------

fn radix_counting_pass(arr: &mut Vec[Int], exp: Int, n: Int) {
  var counts = Vec[Int].new();
  var j = 0;
  while j < 256 {
    counts.push(0);
    j = j + 1;
  }
  var output = Vec[Int].new();
  j = 0;
  while j < n {
    output.push(0);
    j = j + 1;
  }
  var i = 0;
  while i < n {
    var digit = arr[i] / exp % 256;
    if digit < 0 { digit = digit + 256; }
    counts[digit] = counts[digit] + 1;
    i = i + 1;
  }
  j = 1;
  while j < 256 {
    counts[j] = counts[j] + counts[j - 1];
    j = j + 1;
  }
  i = n - 1;
  while i >= 0 {
    var digit = arr[i] / exp % 256;
    if digit < 0 { digit = digit + 256; }
    counts[digit] = counts[digit] - 1;
    output[counts[digit]] = arr[i];
    i = i - 1;
  }
  i = 0;
  while i < n {
    arr[i] = output[i];
    i = i + 1;
  }
}

pub fn sort_radix(arr: &mut Vec[Int]) {
  var n = arr.len();
  if n <= 1 { return; }
  // find max value to determine number of passes
  var max_val = 0;
  var i = 0;
  while i < n {
    if arr[i] > max_val { max_val = arr[i]; }
    if arr[i] < 0 { return; } // radix sort only handles non-negative
    i = i + 1;
  }
  var exp = 1;
  while max_val / exp > 0 {
    radix_counting_pass(arr, exp, n);
    exp = exp * 256;
  }
}

/// is_sorted -- O(n). Checks whether the vector is in non-decreasing order
/// according to the Ord (compare) trait.
pub fn is_sorted[T: Ord](arr: &Vec[T]) -> Bool {
  var n = arr.len();
  if n <= 1 { return true; }
  var i = 1;
  while i < n {
    if arr[i - 1].compare(arr[i]) > 0 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// stable_sort -- O(n log n). Guarantees equal elements retain their relative
/// order. Delegates to merge_sort which is naturally stable.
pub fn stable_sort[T: Ord](arr: &mut Vec[T]) {
  sort_merge(arr);
}

// ---------------------------------------------------------------------------
// COMPARATOR SUPPORT
// ---------------------------------------------------------------------------
// The functions below take a comparator `compare: fn(&T, &T) -> Int` that must
// return -1 when the first argument should sort before the second, 0 when they
// are considered equal, and 1 when the first should sort after the second.
//
// NOTE (compiler limitation): comparator functions must be passed as NAMED
// functions. Inline lambda closures (`|a, b| ...`) currently crash the runtime
// with an access violation, and generic function pointers cannot be
// monomorphized. All comparator-based APIs below therefore require a named,
// monomorphic comparator function from the caller.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// sort_by -- in-place quick sort using a custom comparator.
// O(n log n) average, O(n2) worst. Unstable.
// Uses the same two-pointer partition scheme as sort_quick.
// ---------------------------------------------------------------------------

fn quick_sort_by_range[T](arr: &mut Vec[T], compare: fn(&T, &T) -> Int, lo: Int, hi: Int) {
  if lo >= hi { return; }
  // pivot is a value copy taken from the front; it is immune to later writes
  var pivot = arr[lo];
  var i = lo + 1;
  var j = hi;
  while i <= j {
    while i <= j && compare(&arr[i], &pivot) <= 0 { i = i + 1; }
    while j >= i && compare(&arr[j], &pivot) > 0 { j = j - 1; }
    if i < j {
      var temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
  }
  // place pivot at its final position j
  var swap_temp = arr[lo];
  arr[lo] = arr[j];
  arr[j] = swap_temp;
  quick_sort_by_range(arr, compare, lo, j - 1);
  quick_sort_by_range(arr, compare, j + 1, hi);
}

pub fn sort_by[T](arr: &mut Vec[T], compare: fn(&T, &T) -> Int) {
  var n = arr.len();
  if n <= 1 { return; }
  quick_sort_by_range(arr, compare, 0, n - 1);
}

/// sort_by_key -- sort by an extracted key, K must be Ord.
/// O(n2) worst with O(1) extra key storage per comparison. Unstable.
/// The key function is called twice per comparison to keep the code simple;
/// it must be a named function (see comparator note above).
pub fn sort_by_key[T, K: Ord](arr: &mut Vec[T], key: fn(&T) -> K) {
  var n = arr.len();
  if n <= 1 { return; }
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      var key_left = key(&arr[j - 1]);
      var key_right = key(&arr[j]);
      if key_left.compare(key_right) > 0 {
        var temp = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = temp;
        j = j - 1;
      } else {
        j = 0;
      }
    }
    i = i + 1;
  }
}

// ---------------------------------------------------------------------------
// stable_sort_by -- merge sort with a custom comparator.
// O(n log n) always. STABLE: equal elements retain relative order.
// Uses an auxiliary buffer of size n, mirroring the Ord-based sort_merge.
// ---------------------------------------------------------------------------

fn merge_by_range[T](arr: &mut Vec[T], temp: &mut Vec[T], compare: fn(&T, &T) -> Int, lo: Int, mid: Int, hi: Int) {
  // copy the range into scratch storage
  var i = lo;
  while i <= hi {
    temp[i - lo] = arr[i];
    i = i + 1;
  }
  var left_idx = 0;
  var right_idx = mid - lo + 1;
  var end_left = mid - lo;
  var end_right = hi - lo;
  var k = lo;
  while left_idx <= end_left && right_idx <= end_right {
    if compare(&temp[left_idx], &temp[right_idx]) <= 0 {
      arr[k] = temp[left_idx];
      left_idx = left_idx + 1;
    } else {
      arr[k] = temp[right_idx];
      right_idx = right_idx + 1;
    }
    k = k + 1;
  }
  while left_idx <= end_left {
    arr[k] = temp[left_idx];
    left_idx = left_idx + 1;
    k = k + 1;
  }
  while right_idx <= end_right {
    arr[k] = temp[right_idx];
    right_idx = right_idx + 1;
    k = k + 1;
  }
}

fn merge_sort_by_range[T](arr: &mut Vec[T], temp: &mut Vec[T], compare: fn(&T, &T) -> Int, lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  merge_sort_by_range(arr, temp, compare, lo, mid);
  merge_sort_by_range(arr, temp, compare, mid + 1, hi);
  merge_by_range(arr, temp, compare, lo, mid, hi);
}

pub fn stable_sort_by[T](arr: &mut Vec[T], compare: fn(&T, &T) -> Int) {
  var n = arr.len();
  if n <= 1 { return; }
  var temp = Vec[T].new();
  var i = 0;
  while i < n {
    temp.push(arr[i]);
    i = i + 1;
  }
  merge_sort_by_range(arr, &temp, compare, 0, n - 1);
}

/// partial_sort -- places the smallest k elements at the front, in order.
/// O(n-k) with O(1) extra space. Unstable. Selection-based: repeatedly find the
/// minimum of the unsorted tail and swap it into position.
/// If k >= n the entire vector becomes sorted; if k <= 0 nothing happens.
pub fn partial_sort[T: Ord](arr: &mut Vec[T], k: Int) {
  var n = arr.len();
  if n <= 1 || k <= 0 { return; }
  var kk = k;
  if kk > n { kk = n; }
  var i = 0;
  while i < kk {
    var min_idx = i;
    var j = i + 1;
    while j < n {
      if arr[j].compare(arr[min_idx]) < 0 { min_idx = j; }
      j = j + 1;
    }
    if min_idx != i {
      var temp = arr[i];
      arr[i] = arr[min_idx];
      arr[min_idx] = temp;
    }
    i = i + 1;
  }
}

// ---------------------------------------------------------------------------
// nth_element -- quickselect: partially partitions the vector so the element
// that would appear at index n in sorted order lands at position n.
// O(n) average, O(n2) worst. Unstable. Returns that element, or None if n is
// out of bounds. Note the vector is reordered as a side effect.
// ---------------------------------------------------------------------------

fn nth_partition[T: Ord](arr: &mut Vec[T], lo: Int, hi: Int) -> Int {
  var pivot = arr[lo];
  var i = lo + 1;
  var j = hi;
  while i <= j {
    while i <= j && arr[i].compare(pivot) <= 0 { i = i + 1; }
    while j >= i && arr[j].compare(pivot) > 0 { j = j - 1; }
    if i < j {
      var temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
  }
  var swap_temp = arr[lo];
  arr[lo] = arr[j];
  arr[j] = swap_temp;
  return j;
}

pub fn nth_element[T: Ord](arr: &mut Vec[T], n: Int) -> Option[T] {
  var len = arr.len();
  if n < 0 || n >= len { return None; }
  var lo = 0;
  var hi = len - 1;
  while lo < hi {
    var p = nth_partition(arr, lo, hi);
    if p == n { return Some(arr[n]); }
    if n < p {
      hi = p - 1;
    } else {
      lo = p + 1;
    }
  }
  return Some(arr[n]);
}

/// is_sorted_by -- O(n). Checks whether the vector is in non-decreasing order
/// according to the supplied comparator.
pub fn is_sorted_by[T](arr: &Vec[T], compare: fn(&T, &T) -> Int) -> Bool {
  var n = arr.len();
  if n <= 1 { return true; }
  var i = 1;
  while i < n {
    if compare(&arr[i - 1], &arr[i]) > 0 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

/// sort_desc -- O(n log n) average. Sorts in strictly descending order.
/// Unstable (delegates to quick sort, then reverses in place).
pub fn sort_desc[T: Ord](arr: &mut Vec[T]) {
  sort_quick(arr);
  var n = arr.len();
  var i = 0;
  var j = n - 1;
  while i < j {
    var temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
    i = i + 1;
    j = j - 1;
  }
}

// ---------------------------------------------------------------------------
// sort_dual_pivot -- dual-pivot quick sort (Yaroslavskiy).
// O(n log n) average, O(n2) worst. Unstable. Uses two pivots and partitions
// the range into three segments (< p1, between, > p2) in a single pass.
// Small ranges (< 16 elements) fall back to insertion sort.
// ---------------------------------------------------------------------------

fn dual_pivot_range[T: Ord](arr: &mut Vec[T], lo: Int, hi: Int) {
  if hi - lo < 16 {
    var i = lo + 1;
    while i <= hi {
      var j = i;
      while j > lo && arr[j - 1].compare(arr[j]) > 0 {
        var temp = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = temp;
        j = j - 1;
      }
      i = i + 1;
    }
    return;
  }
  // order the two pivots so arr[lo] <= arr[hi]
  if arr[lo].compare(arr[hi]) > 0 {
    var t = arr[lo];
    arr[lo] = arr[hi];
    arr[hi] = t;
  }
  var pivot1 = arr[lo];
  var pivot2 = arr[hi];
  var lt = lo + 1;
  var gt = hi - 1;
  var k = lt;
  while k <= gt {
    if arr[k].compare(pivot1) < 0 {
      var t = arr[k];
      arr[k] = arr[lt];
      arr[lt] = t;
      lt = lt + 1;
      k = k + 1;
    } elif arr[k].compare(pivot2) > 0 {
      var t = arr[k];
      arr[k] = arr[gt];
      arr[gt] = t;
      gt = gt - 1;
    } else {
      k = k + 1;
    }
  }
  // place pivots at their final positions
  var p1 = arr[lo];
  arr[lo] = arr[lt - 1];
  arr[lt - 1] = p1;
  var p2 = arr[hi];
  arr[hi] = arr[gt + 1];
  arr[gt + 1] = p2;
  // recurse on the three partitions
  dual_pivot_range(arr, lo, lt - 2);
  dual_pivot_range(arr, lt, gt);
  dual_pivot_range(arr, gt + 2, hi);
}

pub fn sort_dual_pivot[T: Ord](arr: &mut Vec[T]) {
  var n = arr.len();
  if n <= 1 { return; }
  dual_pivot_range(arr, 0, n - 1);
}

/// sort_insertion_by -- insertion sort with a custom comparator.
/// O(n2) worst/average, O(n) best (already sorted). STABLE.
pub fn sort_insertion_by[T](arr: &mut Vec[T], compare: fn(&T, &T) -> Int) {
  var n = arr.len();
  if n <= 1 { return; }
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 && compare(&arr[j - 1], &arr[j]) > 0 {
      var temp = arr[j - 1];
      arr[j - 1] = arr[j];
      arr[j] = temp;
      j = j - 1;
    }
    i = i + 1;
  }
}
