// XIOM -- Fixed-Size Array Operations
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.array

use xiom.array.fixed;
use xiom.array.dynamic;

use xiom.cmp;

pub fn len[T, const N: Int](arr: &[N]T) -> Int {
  N
}

pub fn is_empty[T, const N: Int](arr: &[N]T) -> Bool {
  N == 0
}

pub fn first[T, const N: Int](arr: &[N]T) -> Option[T]
  ensures: N == 0 => result is None {
  if N == 0 {
    return None;
  }
  Some(arr[0])
}

pub fn last[T, const N: Int](arr: &[N]T) -> Option[T]
  ensures: N == 0 => result is None {
  if N == 0 {
    return None;
  }
  Some(arr[N - 1])
}

pub fn get[T, const N: Int](arr: &[N]T, index: Int) -> Option[T]
  ensures: index < 0 || index >= N => result is None {
  if index < 0 || index >= N {
    return None;
  }
  Some(arr[index])
}

// Value-returning read (like Vec.get). The Option<&T> reference form is
// not representable on this compiler: the mono'd body boxes the element
// VALUE into the Option payload while call sites auto-deref the payload
// as a pointer (inttoptr of the value -> AV). All consumers must use
// the value form.
/// Value-returning read (like Vec.get). The Option<&T> reference form is
/// not representable on this compiler: the mono'd body boxes the element
/// VALUE into the Option payload while call sites auto-deref the payload
/// as a pointer (inttoptr of the value -> AV). All consumers must use
/// the value form.
pub fn get_mut[T, const N: Int](arr: &mut [N]T, index: Int) -> Option[T]
  ensures: index < 0 || index >= N => result is None {
  if index < 0 || index >= N {
    return None;
  }
  Some(arr[index])
}

pub fn map[T, U, const N: Int](arr: [N]T, f: fn(T) -> U) -> [N]U {
  var result: [N]U;
  var i = 0;
  while i < N {
    result[i] = f(arr[i]);
    i = i + 1;
  }
  return result;
}

pub fn zip[T, U, const N: Int](a: [N]T, b: [N]U) -> [N](T, U) {
  var result: [N](T, U);
  var i = 0;
  while i < N {
    result[i] = (a[i], b[i]);
    i = i + 1;
  }
  return result;
}

pub fn fold[T, B, const N: Int](arr: [N]T, init: B, f: fn(B, T) -> B) -> B {
  var acc = init;
  var i = 0;
  while i < N {
    acc = f(acc, arr[i]);
    i = i + 1;
  }
  return acc;
}

pub fn as_slice[T, const N: Int](arr: &[N]T) -> Slice[T]
  requires: N > 0
  ensures: result.len == N {
  Slice { data: &arr[0] as *T, len: N }
}

pub fn as_mut_slice[T, const N: Int](arr: &mut [N]T) -> Slice[T]
  requires: N > 0
  ensures: result.len == N {
  Slice { data: &mut arr[0] as *T, len: N }
}

pub fn each_ref[T, const N: Int](arr: &[N]T) -> [N]&T {
  var result: [N]&T;
  var i = 0;
  while i < N {
    result[i] = &arr[i];
    i = i + 1;
  }
  return result;
}

pub fn each_mut[T, const N: Int](arr: &mut [N]T) -> [N]&mut T {
  var result: [N]&mut T;
  var i = 0;
  while i < N {
    result[i] = &mut arr[i];
    i = i + 1;
  }
  return result;
}

pub fn fill[T: Clone, const N: Int](arr: &mut [N]T, value: T)
  ensures: true {
  var i = 0;
  while i < N {
    arr[i] = value.clone();
    i = i + 1;
  }
}

pub fn swap[T, const N: Int](arr: &mut [N]T, a: Int, b: Int)
  requires: a >= 0 && a < N
  requires: b >= 0 && b < N {
  var temp = arr[a];
  arr[a] = arr[b];
  arr[b] = temp;
}

fn reverse_range[T, const N: Int](arr: &mut [N]T, start: Int, count: Int)
  requires: start >= 0
  requires: start + count <= N {
  var i = start;
  var j = start + count - 1;
  while i < j {
    var temp = arr[i];
    arr[i] = arr[j];
    arr[j] = temp;
    i = i + 1;
    j = j - 1;
  }
}

pub fn reverse[T, const N: Int](arr: &mut [N]T)
  ensures: true {
  reverse_range(arr, 0, N);
}

pub fn rotate_left[T, const N: Int](arr: &mut [N]T, mid: Int)
  requires: mid >= 0
  requires: mid <= N {
  if N <= 1 || mid <= 0 || mid >= N {
    return;
  }
  reverse_range(arr, 0, mid);
  reverse_range(arr, mid, N - mid);
  reverse_range(arr, 0, N);
}

pub fn rotate_right[T, const N: Int](arr: &mut [N]T, k: Int)
  requires: k >= 0 {
  if N <= 1 {
    return;
  }
  var mid = N - (k % N);
  if mid == N {
    return;
  }
  reverse_range(arr, 0, mid);
  reverse_range(arr, mid, N - mid);
  reverse_range(arr, 0, N);
}

pub fn sort[T: Ord, const N: Int](arr: &mut [N]T)
  ensures: arr.is_sorted() {
  var i = 1;
  while i < N {
    var j = i;
    while j > 0 {
      if arr[j - 1].compare(arr[j]) <= 0 {
        j = 0;
      } else {
        var temp = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = temp;
        j = j - 1;
      }
    }
    i = i + 1;
  }
}

pub fn sort_by[T, const N: Int](arr: &mut [N]T, compare: fn(&T, &T) -> Ordering)
  ensures: arr.is_sorted_by(compare) {
  var i = 1;
  while i < N {
    var j = i;
    while j > 0 {
      if compare(&arr[j - 1], &arr[j]) != Greater {
        j = 0;
      } else {
        var temp = arr[j - 1];
        arr[j - 1] = arr[j];
        arr[j] = temp;
        j = j - 1;
      }
    }
    i = i + 1;
  }
}

pub fn binary_search[T: Ord, const N: Int](arr: &[N]T, x: &T) -> Result[Int, Int]
  requires: N >= 0
  requires: arr.is_sorted() {
  var low = 0;
  var high = N;
  while low < high {
    var mid = low + (high - low) / 2;
    var cmp = arr[mid].compare(x);
    if cmp < 0 {
      low = mid + 1;
    } elif cmp > 0 {
      high = mid;
    } else {
      return Ok(mid);
    }
  }
  Err(low)
}

pub fn contains[T: Eq, const N: Int](arr: &[N]T, x: &T) -> Bool
  ensures: result == true => arr.contains(x) {
  var i = 0;
  while i < N {
    if arr[i].eq(x) {
      return true;
    }
    i = i + 1;
  }
  false
}

// -- Array Aggregation -------------------------------------------------------

/// Sum of all elements in an integer array. O(N).
pub fn array_sum[const N: Int](arr: &[N]Int) -> Int {
  var total = 0;
  var i = 0;
  while i < N {
    total = total + arr[i];
    i = i + 1;
  }
  total
}

/// Maximum element in an array, or None if N == 0. O(N).
pub fn array_max[T: Ord, const N: Int](arr: &[N]T) -> Option[T] {
  if N == 0 { return None; }
  var max_val = arr[0];
  var i = 1;
  while i < N {
    if arr[i].compare(max_val) > 0 { max_val = arr[i]; }
    i = i + 1;
  }
  Some(max_val)
}

/// Minimum element in an array, or None if N == 0. O(N).
pub fn array_min[T: Ord, const N: Int](arr: &[N]T) -> Option[T] {
  if N == 0 { return None; }
  var min_val = arr[0];
  var i = 1;
  while i < N {
    if arr[i].compare(min_val) < 0 { min_val = arr[i]; }
    i = i + 1;
  }
  Some(min_val)
}

/// Count occurrences of `value` in the array. O(N).
pub fn array_count[T: Eq, const N: Int](arr: &[N]T, value: T) -> Int {
  var count = 0;
  var i = 0;
  while i < N {
    if arr[i].eq(value) { count = count + 1; }
    i = i + 1;
  }
  count
}

/// Find the index of the first occurrence of `value`, or None. O(N).
pub fn array_find[T: Eq, const N: Int](arr: &[N]T, value: T) -> Option[Int] {
  var i = 0;
  while i < N {
    if arr[i].eq(value) { return Some(i); }
    i = i + 1;
  }
  None
}

/// Deep equality check between two arrays. O(N).
pub fn array_equal[T: Eq, const N: Int](a: &[N]T, b: &[N]T) -> Bool {
  var i = 0;
  while i < N {
    if !(a[i].eq(b[i])) { return false; }
    i = i + 1;
  }
  true
}
