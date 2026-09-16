// XIOM - Array: Dynamic
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.array.dynamic

// Depends on: none

// ============================================================================
// Dynamic vector (Vec[Int]) helpers: mutation, concatenation, search.
// Implemented as concrete Int specializations of the frozen generic API
// (compiler generic-trait-dispatch codegen bug - docs/STDLIB_GENERICS.md).
// ============================================================================

/// Append value to the end of a. O(1) amortized.
pub fn array_push(a: &mut Vec[Int], value: Int) {
  a.push(value);
}

/// Remove and return the last element, or None if a is empty. O(1).
pub fn array_pop(a: &mut Vec[Int]) -> Option[Int] {
  a.pop()
}

/// Insert value at idx, shifting later elements right. O(n).
/// No-op when idx is outside [0, len].
pub fn array_insert(a: &mut Vec[Int], idx: Int, value: Int) {
  var len = a.len();
  if idx < 0 || idx > len { return; }
  a.insert(idx, value);
}

/// Remove and return the element at idx, or None if out of bounds. O(n).
pub fn array_remove(a: &mut Vec[Int], idx: Int) -> Option[Int] {
  var len = a.len();
  if idx < 0 || idx >= len { return None; }
  a.remove(idx)
}

/// Resize a to n elements, padding new slots with fill. O(n).
/// Negative n is a no-op; shrinking drops trailing elements.
pub fn array_resize(a: &mut Vec[Int], n: Int, fill: Int) {
  if n < 0 { return; }
  while a.len() > n {
    a.pop();
  }
  while a.len() < n {
    a.push(fill);
  }
}

/// New vector with a followed by b. O(a.len() + b.len()).
pub fn array_concat(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < a.len() {
    out.push(a[i]);
    i = i + 1;
  }
  i = 0;
  while i < b.len() {
    out.push(b[i]);
    i = i + 1;
  }
  out
}

/// Append all elements of b to a. O(b.len()).
pub fn array_extend(a: &mut Vec[Int], b: &Vec[Int]) {
  var i = 0;
  while i < b.len() {
    a.push(b[i]);
    i = i + 1;
  }
}

/// Internal merge helper for the in-place sort.
fn arr_merge(a: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, mid: Int, hi: Int) {
  var i = lo;
  while i <= hi {
    tmp[i - lo] = a[i];
    i = i + 1;
  }
  var li = 0;
  var ri = mid - lo + 1;
  var end_l = mid - lo;
  var end_r = hi - lo;
  var k = lo;
  while li <= end_l && ri <= end_r {
    if tmp[li] <= tmp[ri] {
      a[k] = tmp[li];
      li = li + 1;
    } else {
      a[k] = tmp[ri];
      ri = ri + 1;
    }
    k = k + 1;
  }
  while li <= end_l {
    a[k] = tmp[li];
    li = li + 1;
    k = k + 1;
  }
  while ri <= end_r {
    a[k] = tmp[ri];
    ri = ri + 1;
    k = k + 1;
  }
}

/// Internal merge sort over the inclusive range.
fn arr_sort_range(a: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  arr_sort_range(a, tmp, lo, mid);
  arr_sort_range(a, tmp, mid + 1, hi);
  arr_merge(a, tmp, lo, mid, hi);
}

/// Sort a in place. O(n log n), stable, O(n) space.
pub fn array_sort(a: &mut Vec[Int]) {
  var n = a.len();
  if n <= 1 { return; }
  var tmp = Vec[Int].new();
  var i = 0;
  while i < n {
    tmp.push(a[i]);
    i = i + 1;
  }
  arr_sort_range(a, &mut tmp, 0, n - 1);
}

/// Index of the first occurrence of item, or None. O(n).
pub fn array_search(a: &Vec[Int], item: Int) -> Option[Int] {
  var i = 0;
  while i < a.len() {
    if a[i] == item { return Some(i); }
    i = i + 1;
  }
  None
}

/// True if the vector has no elements. O(1).
pub fn array_is_empty(a: &Vec[Int]) -> Bool {
  a.len() == 0
}
