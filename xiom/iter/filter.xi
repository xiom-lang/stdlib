// XIOM - Iterator: Filter
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.filter

// Depends on: none

// ============================================================================
// Selection adapters: filter, take, skip, dedup, unique.
// NOTE: current implementation lives in iter.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn iter_filter[T](v: &Vec[T], pred: fn(&T) -> Bool) -> Vec[T] - keep elements satisfying pred. TODO(compiler): implement.
// fn iter_filter_mut[T](v: &mut Vec[T], pred) - remove in place elements not satisfying pred. TODO(compiler): implement.
// fn iter_take[T](v: &Vec[T], n: Int) -> Vec[T] - first n elements (or fewer). TODO(compiler): implement.
// fn iter_skip[T](v: &Vec[T], n: Int) -> Vec[T] - all elements after the first n. TODO(compiler): implement.
// fn iter_take_while[T](v, pred) -> Vec[T] - leading elements while pred holds. TODO(compiler): implement.
// fn iter_skip_while[T](v, pred) -> Vec[T] - elements after the leading run satisfying pred. TODO(compiler): implement.
// fn iter_dedup[T](v: &Vec[T]) -> Vec[T] - drop consecutive equal elements. TODO(compiler): implement.
// fn iter_unique[T](v: &Vec[T]) -> Vec[T] - keep first occurrence of each value, drop later duplicates. TODO(compiler): implement.
