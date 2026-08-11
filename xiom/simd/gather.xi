// XIOM - SIMD: Gather/Scatter
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.gather

// Depends on: none

// ============================================================================
// Gather/scatter memory access, masked loads, compression and expansion
// helpers. NOTE: current implementation lives in simd.xi - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn gather_load[T](base: Int, indices: &Vec[Int]) -> Vec[T] - load T values from base + index for every index. TODO(compiler): implement.
// fn gather_load4[T](base: Int, i0, i1, i2, i3) -> (T, T, T, T) - load four T values; the tuple is the four gathered values. TODO(compiler): implement.
// fn scatter_store[T](base: Int, indices: &Vec[Int], values: &Vec[T]) - store values to base + index. TODO(compiler): implement.
// fn gather_mask[T](base: Int, indices: &Vec[Int], mask: Mask) -> Vec[T] - gather only the lanes where the mask is set. TODO(compiler): implement.
// fn gather_compress[T](values: &Vec[T], mask) -> Vec[T] - compact the set-lane values to the front. TODO(compiler): implement.
// fn gather_expand[T](values: &Vec[T], mask) -> Vec[T] - spread values back into set-lane positions. TODO(compiler): implement.
// fn gather_iota[T](base: Int, n: Int) -> Vec[T] - materialize the values base + 0 .. base + n-1. TODO(compiler): implement.
