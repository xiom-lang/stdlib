// XIOM - Math: Matrices
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.matrices

// Depends on: xiom.math

// ============================================================================
// Fixed-size 2x2/3x3/4x4 matrices plus generic dynamic matrices and 4x4 transforms.
// TODO(compiler): implement.
// ============================================================================

// type Mat2 - 2x2 matrix; struct { m00; m01; m10; m11 } in column-major order.
// fn mat2_new(a11: Float64, a12: Float64, a21: Float64, a22: Float64) -> Mat2 - construct from four elements.
// fn mat2_mul(a: Mat2, b: Mat2) -> Mat2 - matrix product a * b.
// fn mat2_det(m: Mat2) -> Float64 - determinant.
// fn mat2_inv(m: Mat2) -> Option[Mat2] - inverse; None when singular.
// fn mat2_transpose(m: Mat2) -> Mat2 - transpose.
// type Mat3 - 3x3 matrix; struct of nine m** elements in column-major order.
// fn mat3_new(a11: Float64, a12: Float64, a13: Float64, a21: Float64, a22: Float64, a23: Float64, a31: Float64, a32: Float64, a33: Float64) -> Mat3 - construct from nine elements.
// fn mat3_mul(a: Mat3, b: Mat3) -> Mat3 - matrix product a * b.
// fn mat3_det(m: Mat3) -> Float64 - determinant by cofactor expansion.
// fn mat3_inv(m: Mat3) -> Option[Mat3] - inverse; None when singular.
// fn mat3_transpose(m: Mat3) -> Mat3 - transpose.
// type Mat4 - 4x4 matrix; struct of sixteen m** elements in column-major order.
// fn mat4_new(a11: Float64, a12: Float64, a13: Float64, a14: Float64, a21: Float64, a22: Float64, a23: Float64, a24: Float64, a31: Float64, a32: Float64, a33: Float64, a34: Float64, a41: Float64, a42: Float64, a43: Float64, a44: Float64) -> Mat4 - construct from sixteen elements.
// fn mat4_mul(a: Mat4, b: Mat4) -> Mat4 - matrix product a * b.
// fn mat4_det(m: Mat4) -> Float64 - determinant by cofactor expansion.
// fn mat4_inv(m: Mat4) -> Option[Mat4] - inverse via adjugate; None when singular.
// fn mat4_transpose(m: Mat4) -> Mat4 - transpose.
// fn mat_identity(n: Int) -> Vec[Vec[Float64]] - n x n identity matrix.
// fn mat_mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - dynamic matrix product.
// fn mat_det(m: &Vec[Vec[Float64]]) -> Float64 - determinant of a dynamic square matrix.
// fn mat_inv(m: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] - inverse; None when singular.
// fn mat_translate(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] - apply a translation to m.
// fn mat_rotate(m: &Vec[Vec[Float64]], angle: Float64, axis: &Vec[Float64]) -> Vec[Vec[Float64]] - rotate m about axis by angle radians.
// fn mat_scale(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] - apply a scale to m.
// fn mat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Vec[Vec[Float64]] - right-handed view matrix.
// fn mat_perspective(fovy: Float64, aspect: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] - perspective projection matrix.
// fn mat_ortho(left: Float64, right: Float64, bottom: Float64, top: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] - orthographic projection matrix.
