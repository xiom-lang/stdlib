// XIOM - Iterator: Map
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.map

// Depends on: none

// ============================================================================
// Transform adapters: map, flat_map, filter_map, enumerate, zip.
// NOTE: current implementation lives in iter.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn iter_map[T, U](v: &Vec[T], f: fn(&T) -> U) -> Vec[U] - apply f to every element. TODO(compiler): implement.
// fn iter_flat_map[T, U](v: &Vec[T], f: fn(&T) -> Vec[U]) -> Vec[U] - apply f, then concatenate the results. TODO(compiler): implement.
// fn iter_filter_map[T, U](v, f: fn(&T) -> Option[U]) -> Vec[U] - keep and unwrap elements where f returns Some. TODO(compiler): implement.
// fn iter_enumerate[T](v: &Vec[T]) -> Vec[(Int, T)] - (index, value) tuple for each element. TODO(compiler): implement.
// fn iter_zip[T, U](a: &Vec[T], b: &Vec[U]) -> Vec[(T, U)] - (a[i], b[i]) tuple pairs, truncated to the shorter input. TODO(compiler): implement.
