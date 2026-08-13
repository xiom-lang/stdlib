// XIOM - Sorting: Radix Sort
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.sort.radix

// Depends on: none

// ============================================================================
// Radix/counting/bucket sort family: linear-time integer sorts, no comparisons.
// ============================================================================

/// Stable counting-sort pass over one byte-digit. Internal helper. O(n + 256).
fn radix_pass(v: &mut Vec[Int], exp: Int, n: Int) {
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
    var digit = v[i] / exp % 256;
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
    var digit = v[i] / exp % 256;
    if digit < 0 { digit = digit + 256; }
    counts[digit] = counts[digit] - 1;
    output[counts[digit]] = v[i];
    i = i - 1;
  }
  i = 0;
  while i < n {
    v[i] = output[i];
    i = i + 1;
  }
}

/// LSD radix sort of non-negative Int values. O(n * d) where d is the number
/// of bytes needed for the maximum value. Stable. In-place, O(n) space.
/// NOTE: negative values are NOT supported; if any element is negative the
/// vector is left unchanged (documented contract of the frozen API).
pub fn radix_sort(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  var max_val = 0;
  var i = 0;
  while i < n {
    if v[i] < 0 { return; }
    if v[i] > max_val { max_val = v[i]; }
    i = i + 1;
  }
  var exp = 1;
  while max_val / exp > 0 {
    radix_pass(v, exp, n);
    exp = exp * 256;
  }
}

/// Radix sort of UInt64 values. O(n * d), stable, in-place, O(n) space.
pub fn radix_sort_u64(v: &mut Vec[UInt64]) {
  var n = v.len();
  if n <= 1 { return; }
  var max_val: UInt64 = 0;
  var i = 0;
  while i < n {
    if v[i] > max_val { max_val = v[i]; }
    i = i + 1;
  }
  var exp: UInt64 = 1;
  while max_val / exp > 0 {
    radix_pass_u64(v, exp, n);
    exp = exp * 256;
  }
}

/// Stable counting-sort pass over UInt64 byte-digits. Internal helper.
fn radix_pass_u64(v: &mut Vec[UInt64], exp: UInt64, n: Int) {
  var counts = Vec[Int].new();
  var j = 0;
  while j < 256 {
    counts.push(0);
    j = j + 1;
  }
  var output = Vec[UInt64].new();
  j = 0;
  while j < n {
    output.push(0 as UInt64);
    j = j + 1;
  }
  var i = 0;
  while i < n {
    var digit = (v[i] / exp % 256) as Int;
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
    var digit = (v[i] / exp % 256) as Int;
    counts[digit] = counts[digit] - 1;
    output[counts[digit]] = v[i];
    i = i - 1;
  }
  i = 0;
  while i < n {
    v[i] = output[i];
    i = i + 1;
  }
}

/// Radix sort over raw byte digits (4 passes of 8 bits). Stable.
/// Handles the same input domain as radix_sort: non-negative values only;
/// negative values are left unchanged (documented contract).
pub fn radix_sort_by_bytes(v: &mut Vec[Int]) {
  var n = v.len();
  if n <= 1 { return; }
  var i = 0;
  while i < n {
    if v[i] < 0 { return; }
    i = i + 1;
  }
  var exp = 1;
  var pass = 0;
  while pass < 4 {
    radix_pass(v, exp, n);
    exp = exp * 256;
    pass = pass + 1;
  }
}

/// Stable counting sort for values in [0, max_val]. O(n + k), stable, O(n+k)
/// space. If max_val < 0, or if any element lies outside [0, max_val], the
/// vector is left unchanged (documented contract).
pub fn counting_sort(v: &mut Vec[Int], max_val: Int) {
  var n = v.len();
  if n <= 1 || max_val < 0 { return; }
  var counts = Vec[Int].new();
  var j = 0;
  while j <= max_val {
    counts.push(0);
    j = j + 1;
  }
  var i = 0;
  while i < n {
    var val = v[i];
    if val >= 0 && val <= max_val {
      counts[val] = counts[val] + 1;
    } else {
      return;
    }
    i = i + 1;
  }
  j = 1;
  while j <= max_val {
    counts[j] = counts[j] + counts[j - 1];
    j = j + 1;
  }
  var output = Vec[Int].new();
  j = 0;
  while j < n {
    output.push(0);
    j = j + 1;
  }
  i = n - 1;
  while i >= 0 {
    var val = v[i];
    counts[val] = counts[val] - 1;
    output[counts[val]] = val;
    i = i - 1;
  }
  i = 0;
  while i < n {
    v[i] = output[i];
    i = i + 1;
  }
}

// fn bucket_sort(v: &mut Vec[Int], buckets: Int) - distribute elements into
// buckets and sort each.
// NOT IMPLEMENTED: bucket sort requires reading/writing elements of a nested
// Vec[Vec[Int]], which the current compiler does not handle reliably
// (see docs/STDLIB_GENERICS.md and collections/graph.xi). Revisit when nested
// Vec element access is supported.

