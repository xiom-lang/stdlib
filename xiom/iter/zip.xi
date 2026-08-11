// XIOM - Iterator: Zip
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.iter.zip

// Depends on: none

// ============================================================================
// Combination adapters: zip_longest, chain, cartesian, interleave.
// NOTE: current implementation lives in iter.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn iter_zip_longest[T, U](a, b, fill: T) -> Vec[(T, U)] - (a[i], b[i]) tuple pairs padded with fill on the shorter input. TODO(compiler): implement.
// fn iter_chain[T](a: &Vec[T], b: &Vec[T]) -> Vec[T] - concatenate a followed by b. TODO(compiler): implement.
// fn iter_chain_many(parts: &Vec[Vec[T]]) -> Vec[T] - concatenate a list of vectors in order. TODO(compiler): implement.
// fn iter_cartesian_product[T, U](a, b) -> Vec[(T, U)] - all (a[i], b[j]) tuple combinations. TODO(compiler): implement.
// fn iter_interleave[T](a, b) -> Vec[T] - alternate elements of a and b. TODO(compiler): implement.
