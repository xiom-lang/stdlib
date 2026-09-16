// XIOM - Array: Fixed
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.array.fixed

// Depends on: none

// ============================================================================
// Fixed-size array ([N]Int) helpers: access, transform, reverse, fill.
// Implemented as concrete Int specializations of the frozen generic API
// (compiler generic-trait-dispatch codegen bug - docs/STDLIB_GENERICS.md).
// ============================================================================

/// Compile-time length N of a fixed-size array. O(1).
pub fn array_len[const N: Int](a: &[N]Int) -> Int {
  N
}

/// Element at idx, or None if out of bounds. O(1). Returns a value copy.
pub fn array_get[const N: Int](a: &[N]Int, idx: Int) -> Option[Int] {
  if idx < 0 || idx >= N { return None; }
  Some(a[idx])
}

// fn array_set[T](a: &mut [N]T, idx, value) - write value at idx if in bounds.
// fn array_swap[T](a: &mut [N]T, i, j) - swap elements at i and j in place.
// NOT IMPLEMENTED: `&mut [N]Int` parameters to functions do not propagate
// mutations back to the caller with the current compiler (codegen emits
// "invalid getelementptr indices" or silently copies; the same bug breaks
// array.fill/swap/reverse in array.xi and smoke_array_fill_swap.xi). Revisit
// when mutable fixed-array parameters are supported.
/// First element, or None if N == 0. O(1).
pub fn array_first[const N: Int](a: &[N]Int) -> Option[Int] {
  if N == 0 { return None; }
  Some(a[0])
}

/// Last element, or None if N == 0. O(1).
pub fn array_last[const N: Int](a: &[N]Int) -> Option[Int] {
  if N == 0 { return None; }
  Some(a[N - 1])
}

/// Copy of a[start..end) as a Vec[Int]. Bounds are clamped to [0, N]. O(n).
pub fn array_slice[const N: Int](a: &[N]Int, start: Int, end: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  var s = start;
  var e = end;
  if s < 0 { s = 0; }
  if e > N { e = N; }
  var i = s;
  while i < e {
    out.push(a[i]);
    i = i + 1;
  }
  out
}

// fn array_map[T, U](a, f) -> Vec[U] - apply f to every element.
// NOT IMPLEMENTED: combining a const-generic array parameter with a fn-pointer
// parameter triggers the generic+fn-pointer codegen bug ("use of undefined
// value" at codegen - see docs/STDLIB_GENERICS.md). Revisit when the compiler
// can monomorphize const-generic functions that take fn pointers.

/// (a[i], b[i]) pairs, truncated to the shorter array. O(min(N, M)).
/// Returns Vec[(Int, Int)].
pub fn array_zip[const N: Int, const M: Int](a: &[N]Int, b: &[M]Int) -> Vec[(Int, Int)] {
  var out = Vec[(Int, Int)].new();
  var count = N;
  if M < count { count = M; }
  var i = 0;
  while i < count {
    out.push((a[i], b[i]));
    i = i + 1;
  }
  out
}

// fn array_reverse[T](a) -> [N]T - new array with elements in reverse order.
// fn array_fill[T](value: T, n) -> [N]T - new length-n array filled with value.
// NOT IMPLEMENTED: the current compiler cannot monomorphize const-generic
// functions that RETURN a fixed array `[N]Int` ("defined with type i64 but
// expected [N x i64]" at codegen - the same bug breaks array.map in array.xi
// and smoke_array_map.xi). Revisit when fixed-array returns are supported.


