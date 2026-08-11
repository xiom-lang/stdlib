// XIOM - Iterator: Fold
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.fold

// Depends on: none

// ============================================================================
// Consumption and reshaping: scan, find, chunks, windows, compare, sort.
// NOTE: current implementation lives in iter.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn iter_fold1[T](v: &Vec[T], f) -> Option[T] - fold without a seed using the first element, or None if empty. TODO(compiler): implement.
// fn iter_scan[T, U](v, init, f) -> Vec[U] - running-accumulator fold emitting every intermediate state. TODO(compiler): implement.
// fn iter_find[T](v, pred) -> Option[T] - first element satisfying pred, or None. TODO(compiler): implement.
// fn iter_find_map[T, U](v, f) -> Option[U] - first Some value produced by f, or None. TODO(compiler): implement.
// fn iter_contains[T](v, item) -> Bool - true if item occurs in v. TODO(compiler): implement.
// fn iter_position_of[T](v, item) -> Option[Int] - index of the first occurrence of item, or None. TODO(compiler): implement.
// fn iter_chunks[T](v, n) -> Vec[Vec[T]] - contiguous non-overlapping chunks of size n (last may be short). TODO(compiler): implement.
// fn iter_windows[T](v, n) -> Vec[Vec[T]] - all contiguous length-n slices of v. TODO(compiler): implement.
// fn iter_cycle[T](v, n) -> Vec[T] - repeat v n times concatenated. TODO(compiler): implement.
// fn iter_repeat[T](item: T, n) -> Vec[T] - item repeated n times. TODO(compiler): implement.
// fn iter_reverse[T](v) -> Vec[T] - elements of v in reverse order. TODO(compiler): implement.
// fn iter_sort[T](v) -> Vec[T] - sorted copy of v. TODO(compiler): implement.
// fn iter_for_each[T](v, f: fn(&T)) - apply f to each element for side effects. TODO(compiler): implement.
// fn iter_cmp[T](a, b) -> Int - lexicographic comparison: -1, 0, or 1. TODO(compiler): implement.
// fn iter_eq[T](a, b) -> Bool - element-wise equality of a and b. TODO(compiler): implement.
