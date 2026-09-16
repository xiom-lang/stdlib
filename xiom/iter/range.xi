// XIOM - Iterator: Range
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.iter.range

// Depends on: none

// ============================================================================
// Range construction: arithmetic sequences as materialized Vec values.
// ============================================================================

/// Integers in [start, end): start, start+1, ..., end-1. O(n).
/// An empty vector is returned when start >= end.
pub fn range(start: Int, end: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = start;
  while i < end {
    out.push(i);
    i = i + 1;
  }
  out
}

/// Integers in [start, end) advancing by step. O(n).
/// An empty vector is returned when step <= 0 or start >= end.
pub fn range_step(start: Int, end: Int, step: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if step <= 0 { return out; }
  var i = start;
  while i < end {
    out.push(i);
    i = i + step;
  }
  out
}

/// Integers in [start, end] inclusive of both endpoints. O(n).
/// An empty vector is returned when start > end.
pub fn range_inclusive(start: Int, end: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = start;
  while i <= end {
    out.push(i);
    i = i + 1;
  }
  out
}

/// Float64 values in [start, end) advancing by step. O(n).
/// An empty vector is returned when step <= 0 or start >= end.
/// NOTE (BUG 12): element READS of Vec[Float64] are corrupted by the current
/// compiler; consumers must not index the result until that bug is fixed.
pub fn range_float(start: Float64, end: Float64, step: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if step <= 0.0 { return out; }
  var i = start;
  while i < end {
    out.push(i);
    i = i + step;
  }
  out
}

/// Characters with code points in [start, end). O(n).
/// An empty vector is returned when start >= end.
pub fn range_char(start: Char, end: Char) -> Vec[Char] {
  var out = Vec[Char].new();
  var start_cp = start as Int;
  var end_cp = end as Int;
  var cp = start_cp;
  while cp < end_cp {
    out.push(cp as Char);
    cp = cp + 1;
  }
  out
}

/// Integers in [0, n). O(n). An empty vector is returned when n <= 0.
pub fn range_count(n: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < n {
    out.push(i);
    i = i + 1;
  }
  out
}

// fn range_inf(start) -> Iter - unbounded ascending iterator from start.
// NOT IMPLEMENTABLE: the declared return type `Iter` (a lazily-evaluated
// infinite sequence) does not exist anywhere in the stdlib, and there is no
// lazy/infinite sequence machinery to back it. Kept comment-only.
