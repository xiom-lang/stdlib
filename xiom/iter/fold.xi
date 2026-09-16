// XIOM - Iterator: Fold
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.fold

// Depends on: none

// ============================================================================
// Consumption and reshaping: scan, find, chunks, windows, compare, sort.
// Function parameters must be passed as NAMED functions (inline lambdas
// crash the runtime - see docs/STDLIB_GENERICS.md). Implemented as concrete
// Int specializations of the frozen generic API (compiler fn-ptr / generic
// trait-dispatch codegen bug).
// ============================================================================

/// Fold without a seed using the first element, or None if v is empty. O(n).
/// f(acc, element) returns the next accumulator.
pub fn iter_fold1(v: &Vec[Int], f: fn(&Int, &Int) -> Int) -> Option[Int]
  ensures: v.len() == 0 => result is None
  ensures: result is Some => v.len() > 0
{
  if v.len() == 0 { return None; }
  var acc = v[0];
  var i = 1;
  while i < v.len() {
    var x = v[i];
    acc = f(&acc, &x);
    i = i + 1;
  }
  Some(acc)
}

/// Running-accumulator fold emitting every intermediate state. O(n).
/// The result starts with init, followed by each new accumulator, so it
/// always has v.len() + 1 elements.
pub fn iter_scan(v: &Vec[Int], init: Int, f: fn(Int, &Int) -> Int) -> Vec[Int]
  ensures: result.len() == v.len() + 1
{
  var out = Vec[Int].new();
  out.push(init);
  var acc = init;
  var i = 0;
  while i < v.len() {
    var x = v[i];
    acc = f(acc, &x);
    out.push(acc);
    i = i + 1;
  }
  out
}

/// First element satisfying pred, or None. O(n). Short-circuits.
pub fn iter_find(v: &Vec[Int], pred: fn(&Int) -> Bool) -> Option[Int] {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    if pred(&x) { return Some(x); }
    i = i + 1;
  }
  None
}

/// First Some value produced by f over the elements, or None. O(n).
/// Short-circuits on the first Some result.
pub fn iter_find_map(v: &Vec[Int], f: fn(&Int) -> Option[Int]) -> Option[Int] {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    var r = f(&x);
    match r {
      Some(val) => { return Some(val); },
      None => {},
    }
    i = i + 1;
  }
  None
}

/// True if item occurs in v. O(n).
pub fn iter_contains(v: &Vec[Int], item: Int) -> Bool {
  var i = 0;
  while i < v.len() {
    if v[i] == item { return true; }
    i = i + 1;
  }
  false
}

/// Index of the first occurrence of item, or None. O(n).
pub fn iter_position_of(v: &Vec[Int], item: Int) -> Option[Int] {
  var i = 0;
  while i < v.len() {
    if v[i] == item { return Some(i); }
    i = i + 1;
  }
  None
}

/// Contiguous non-overlapping chunks of size n; the last chunk may be short.
/// O(n). n <= 0 yields an empty vector. Returns Vec[Vec[Int]]; nested element
/// access is unreliable in the current compiler - treat as opaque.
pub fn iter_chunks(v: &Vec[Int], n: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  if n <= 0 { return out; }
  var len = v.len();
  var start = 0;
  while start < len {
    var chunk = Vec[Int].new();
    var end = start + n;
    if end > len { end = len; }
    var i = start;
    while i < end {
      chunk.push(v[i]);
      i = i + 1;
    }
    out.push(chunk);
    start = end;
  }
  out
}

/// All contiguous length-n slices of v. O(n * w). Returns Vec[Vec[Int]];
/// nested element access is unreliable in the current compiler.
/// An empty result means n <= 0 or n > v.len().
pub fn iter_windows(v: &Vec[Int], n: Int) -> Vec[Vec[Int]] {
  var out = Vec[Vec[Int]].new();
  var len = v.len();
  if n <= 0 || n > len { return out; }
  var start = 0;
  while start + n <= len {
    var win = Vec[Int].new();
    var i = start;
    while i < start + n {
      win.push(v[i]);
      i = i + 1;
    }
    out.push(win);
    start = start + 1;
  }
  out
}

/// v repeated n times concatenated. O(n * v.len()). n <= 0 yields empty.
pub fn iter_cycle(v: &Vec[Int], n: Int) -> Vec[Int]
  ensures: n >= 0 => result.len() == v.len() * n
  ensures: n < 0 => result.len() == 0
{
  var out = Vec[Int].new();
  if n <= 0 || v.len() == 0 { return out; }
  var rep = 0;
  while rep < n {
    var i = 0;
    while i < v.len() {
      out.push(v[i]);
      i = i + 1;
    }
    rep = rep + 1;
  }
  out
}

/// item repeated n times. O(n). n <= 0 yields an empty vector.
pub fn iter_repeat(item: Int, n: Int) -> Vec[Int]
  ensures: n >= 0 => result.len() == n
  ensures: n < 0 => result.len() == 0
{
  var out = Vec[Int].new();
  var i = 0;
  while i < n {
    out.push(item);
    i = i + 1;
  }
  out
}

/// Elements of v in reverse order. O(n).
pub fn iter_reverse(v: &Vec[Int]) -> Vec[Int]
  ensures: result.len() == v.len()
{
  var out = Vec[Int].new();
  var i = v.len() - 1;
  while i >= 0 {
    out.push(v[i]);
    i = i - 1;
  }
  out
}

/// Internal merge helper for the stable sort.
fn fold_merge_into(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, mid: Int, hi: Int) {
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

/// Internal merge sort over the inclusive range [lo, hi].
fn fold_sort_range(v: &mut Vec[Int], tmp: &mut Vec[Int], lo: Int, hi: Int) {
  if lo >= hi { return; }
  var mid = lo + (hi - lo) / 2;
  fold_sort_range(v, tmp, lo, mid);
  fold_sort_range(v, tmp, mid + 1, hi);
  fold_merge_into(v, tmp, lo, mid, hi);
}

/// Sorted copy of v. O(n log n), stable.
pub fn iter_sort(v: &Vec[Int]) -> Vec[Int]
  ensures: result.len() == v.len()
{
  var out = Vec[Int].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  if out.len() <= 1 { return out; }
  var tmp = Vec[Int].new();
  var j = 0;
  while j < out.len() {
    tmp.push(out[j]);
    j = j + 1;
  }
  fold_sort_range(&mut out, &mut tmp, 0, out.len() - 1);
  out
}

/// Apply f to each element for side effects. O(n).
pub fn iter_for_each(v: &Vec[Int], f: fn(&Int)) {
  var i = 0;
  while i < v.len() {
    var x = v[i];
    f(&x);
    i = i + 1;
  }
}

/// Lexicographic comparison of a and b: -1, 0, or 1. O(min(len)).
/// A prefix of the other compares smaller.
pub fn iter_cmp(a: &Vec[Int], b: &Vec[Int]) -> Int {
  var i = 0;
  var alen = a.len();
  var blen = b.len();
  while i < alen && i < blen {
    if a[i] < b[i] { return -1; }
    if a[i] > b[i] { return 1; }
    i = i + 1;
  }
  if alen < blen { return -1; }
  if alen > blen { return 1; }
  0
}

/// Element-wise equality of a and b (lengths must match). O(n).
pub fn iter_eq(a: &Vec[Int], b: &Vec[Int]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  true
}
