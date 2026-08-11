// XIOM - Iterator: Chain
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.chain

// Depends on: none

// ============================================================================
// Reduction and aggregation: fold, reduce, sum, quantifiers, grouping.
// NOTE: current implementation lives in iter.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn iter_fold[T](v: &Vec[T], init: T, f: fn(T, &T) -> T) -> T - left fold with seed init. TODO(compiler): implement.
// fn iter_fold_right[T](v, init, f) -> T - right fold with seed init. TODO(compiler): implement.
// fn iter_reduce[T](v: &Vec[T], f: fn(&T, &T) -> T) -> Option[T] - fold using the first element as seed, or None if empty. TODO(compiler): implement.
// fn iter_sum(v: &Vec[Int]) -> Int - sum of all elements. TODO(compiler): implement.
// fn iter_product(v: &Vec[Int]) -> Int - product of all elements. TODO(compiler): implement.
// fn iter_any[T](v, pred) -> Bool - true if any element satisfies pred. TODO(compiler): implement.
// fn iter_all[T](v, pred) -> Bool - true if every element satisfies pred. TODO(compiler): implement.
// fn iter_count[T](v) -> Int - number of elements. TODO(compiler): implement.
// fn iter_count_if[T](v, pred) -> Int - number of elements satisfying pred. TODO(compiler): implement.
// fn iter_nth[T](v, n) -> Option[T] - element at index n, or None if out of bounds. TODO(compiler): implement.
// fn iter_last[T](v) -> Option[T] - last element, or None if empty. TODO(compiler): implement.
// fn iter_position[T](v, pred) -> Option[Int] - index of first element satisfying pred, or None. TODO(compiler): implement.
// fn iter_max(v: &Vec[Int]) -> Option[Int] - maximum element, or None if empty. TODO(compiler): implement.
// fn iter_min(v: &Vec[Int]) -> Option[Int] - minimum element, or None if empty. TODO(compiler): implement.
// fn iter_partition[T](v, pred) -> (Vec[T], Vec[T]) - (matching, non-matching) tuple split by pred. TODO(compiler): implement.
// fn iter_group_by[T](v, key: fn(&T) -> Int) -> Vec[Vec[T]] - contiguous groups sharing an equal key value. TODO(compiler): implement.
