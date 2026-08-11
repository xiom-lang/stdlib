// XIOM - SIMD: 4-lane Vectors
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.simd.vec4

// Depends on: none

// ============================================================================
// 4-lane single-precision and 32-bit integer SIMD vector arithmetic, loads
// and stores. NOTE: current implementation lives in simd.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type F32x4 - a 4-lane single-precision SIMD vector.
// type I32x4 - a 4-lane 32-bit integer SIMD vector.
// fn f32x4_new(a, b, c, d) -> F32x4 - build a vector from four lanes. TODO(compiler): implement.
// fn f32x4_add(x, y) -> F32x4 - lane-wise addition. TODO(compiler): implement.
// fn f32x4_sub(x, y) -> F32x4 - lane-wise subtraction. TODO(compiler): implement.
// fn f32x4_mul(x, y) -> F32x4 - lane-wise multiplication. TODO(compiler): implement.
// fn f32x4_div(x, y) -> F32x4 - lane-wise division. TODO(compiler): implement.
// fn f32x4_sqrt(x) -> F32x4 - lane-wise square root. TODO(compiler): implement.
// fn f32x4_min(x, y) -> F32x4 - lane-wise minimum. TODO(compiler): implement.
// fn f32x4_max(x, y) -> F32x4 - lane-wise maximum. TODO(compiler): implement.
// fn f32x4_dot(x, y) -> Float32 - the dot product of two vectors. TODO(compiler): implement.
// fn f32x4_load(ptr: Int) -> F32x4 - load a vector from aligned memory. TODO(compiler): implement.
// fn f32x4_store(ptr: Int, x) - store a vector to aligned memory. TODO(compiler): implement.
// fn f32x4_splat(v: Float32) -> F32x4 - fill every lane with v. TODO(compiler): implement.
// fn f32x4_extract(x, i: Int) -> Float32 - read lane i. TODO(compiler): implement.
// fn f32x4_insert(x, i, v) - write lane i and return the vector. TODO(compiler): implement.
// fn f32x4_sum(x) -> Float32 - the sum of all lanes. TODO(compiler): implement.
// fn i32x4_new(a, b, c, d) -> I32x4 - build a vector from four lanes. TODO(compiler): implement.
// fn i32x4_add(x, y) -> I32x4 - lane-wise addition. TODO(compiler): implement.
// fn i32x4_sub(x, y) -> I32x4 - lane-wise subtraction. TODO(compiler): implement.
// fn i32x4_mul(x, y) -> I32x4 - lane-wise multiplication. TODO(compiler): implement.
// fn i32x4_min(x, y) -> I32x4 - lane-wise minimum. TODO(compiler): implement.
// fn i32x4_max(x, y) -> I32x4 - lane-wise maximum. TODO(compiler): implement.
// fn i32x4_splat(v) -> I32x4 - fill every lane with v. TODO(compiler): implement.
// fn i32x4_extract(x, i) -> Int - read lane i. TODO(compiler): implement.
