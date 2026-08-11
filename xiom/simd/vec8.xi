// XIOM - SIMD: 8-lane Vectors
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.vec8

// Depends on: none

// ============================================================================
// 8-lane single-precision and 32-bit integer SIMD vector arithmetic, loads
// and stores. NOTE: current implementation lives in simd.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type F32x8 - an 8-lane single-precision SIMD vector.
// type I32x8 - an 8-lane 32-bit integer SIMD vector.
// fn f32x8_new(v: &[8]Float32) -> F32x8 - build a vector from a fixed 8-element array. TODO(compiler): implement.
// fn f32x8_add(x, y) -> F32x8 - lane-wise addition. TODO(compiler): implement.
// fn f32x8_sub(x, y) -> F32x8 - lane-wise subtraction. TODO(compiler): implement.
// fn f32x8_mul(x, y) -> F32x8 - lane-wise multiplication. TODO(compiler): implement.
// fn f32x8_div(x, y) -> F32x8 - lane-wise division. TODO(compiler): implement.
// fn f32x8_sqrt(x) -> F32x8 - lane-wise square root. TODO(compiler): implement.
// fn f32x8_min(x, y) -> F32x8 - lane-wise minimum. TODO(compiler): implement.
// fn f32x8_max(x, y) -> F32x8 - lane-wise maximum. TODO(compiler): implement.
// fn f32x8_splat(v) -> F32x8 - fill every lane with v. TODO(compiler): implement.
// fn f32x8_extract(x, i) -> Float32 - read lane i. TODO(compiler): implement.
// fn f32x8_insert(x, i, v) - write lane i and return the vector. TODO(compiler): implement.
// fn f32x8_sum(x) -> Float32 - the sum of all lanes. TODO(compiler): implement.
// fn f32x8_load(ptr) -> F32x8 - load a vector from aligned memory. TODO(compiler): implement.
// fn f32x8_store(ptr, x) - store a vector to aligned memory. TODO(compiler): implement.
// fn i32x8_new(v: &[8]Int) -> I32x8 - build a vector from a fixed 8-element array. TODO(compiler): implement.
// fn i32x8_add(x, y) -> I32x8 - lane-wise addition. TODO(compiler): implement.
// fn i32x8_sub(x, y) -> I32x8 - lane-wise subtraction. TODO(compiler): implement.
// fn i32x8_mul(x, y) -> I32x8 - lane-wise multiplication. TODO(compiler): implement.
// fn i32x8_splat(v) -> I32x8 - fill every lane with v. TODO(compiler): implement.
// fn i32x8_extract(x, i) -> Int - read lane i. TODO(compiler): implement.
