// XIOM - Array: Fixed
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.array.fixed

// Depends on: none

// ============================================================================
// Fixed-size array (T[N]) helpers: access, transform, reverse, fill.
// NOTE: current implementation lives in array.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn array_len[T](a: &[N]T) -> Int - compile-time length N of a fixed-size array (N is a const generic). TODO(compiler): implement.
// fn array_get[T](a, idx) -> Option[T] - element at idx, or None if out of bounds. TODO(compiler): implement.
// fn array_set[T](a: &mut [N]T, idx, value) - write value at idx if in bounds. TODO(compiler): implement.
// fn array_first[T](a) -> Option[T] - first element, or None if N == 0. TODO(compiler): implement.
// fn array_last[T](a) -> Option[T] - last element, or None if N == 0. TODO(compiler): implement.
// fn array_slice[T](a, start, end) -> Vec[T] - copy of a[start..end). TODO(compiler): implement.
// fn array_map[T, U](a, f) -> Vec[U] - apply f to every element. TODO(compiler): implement.
// fn array_zip[T, U](a, b) -> Vec[(T, U)] - (a[i], b[i]) tuple pairs, truncated to the shorter array. TODO(compiler): implement.
// fn array_reverse[T](a) -> [N]T - new array with elements in reverse order. TODO(compiler): implement.
// fn array_swap[T](a: &mut [N]T, i, j) - swap elements at i and j in place. TODO(compiler): implement.
// fn array_fill[T](value: T, n) -> [N]T - new length-n array filled with value. TODO(compiler): implement.
