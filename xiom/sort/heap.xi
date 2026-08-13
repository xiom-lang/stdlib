// XIOM - Sorting: Heap Sort
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sort.heap

// Depends on: none

// ============================================================================
// Heap sort family: in-place selection via a binary max-heap, O(1) space.
// ============================================================================

/// Sift the element at `start` down the max-heap while positions remain in
/// [start, end]. Internal helper. O(log n).
fn sift_down(v: &mut Vec[Int], start: Int, end: Int) {
  var root = start;
  loop {
    var child = 2 * root + 1;
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

/// Build a max-heap from the vector in place. O(n).
pub fn heapify(v: &mut Vec[Int]) {
  var n = v.len();
  var i = n / 2;
  while i >= 0 {
    sift_down(v, i, n - 1);
    i = i - 1;
  }
}

/// In-place heap sort of an Int vector. O(n log n), unstable, O(1) space.
pub fn heap_sort(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  heapify(v);
  var end = n - 1;
  while end > 0 {
    var temp = v[0];
    v[0] = v[end];
    v[end] = temp;
    end = end - 1;
    sift_down(v, 0, end);
  }
}

/// Heap sort with a custom comparator. O(n log n), unstable, O(1) space.
/// The comparator must be a named function returning -1/0/1.
pub fn heap_sort_by(v: &mut Vec[Int], compare: fn(&Int, &Int) -> Int) {
  var n = v.len();
  if n <= 1 { return; }
  var i = n / 2;
  while i >= 0 {
    heap_sift_down_by(v, compare, i, n - 1);
    i = i - 1;
  }
  var end = n - 1;
  while end > 0 {
    var temp = v[0];
    v[0] = v[end];
    v[end] = temp;
    end = end - 1;
    heap_sift_down_by(v, compare, 0, end);
  }
}

/// Comparator-based sift-down. Internal helper. O(log n).
fn heap_sift_down_by(v: &mut Vec[Int], compare: fn(&Int, &Int) -> Int, start: Int, end: Int) {
  var root = start;
  loop {
    var child = 2 * root + 1;
    if child > end { break; }
    if child + 1 <= end && compare(&v[child], &v[child + 1]) < 0 {
      child = child + 1;
    }
    if compare(&v[root], &v[child]) < 0 {
      var temp = v[root];
      v[root] = v[child];
      v[child] = temp;
      root = child;
    } else {
      break;
    }
  }
}
