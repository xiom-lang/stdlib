// XIOM - Geom: Mat
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the matrix domain; the canonical Mat2/3/4
// types and operations live in geom.xi.

module xiom.geom.mat

// Depends on: xiom.geom

// ============================================================================
// Matrix operations split from geom.xi: identity, products, determinants,
// inverses, and 4x4 affine/projection transforms. TODO(compiler): implement.
// ============================================================================

// fn mat_identity(n: Int) -> Vec[Vec[Float64]] - n x n identity matrix.
// fn mat_mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - matrix product.
// fn mat_det(m: &Vec[Vec[Float64]]) -> Float64 - determinant of a square matrix.
// fn mat_inv(m: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] - inverse; None when singular.
// fn mat_transpose(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - transpose.
// fn mat_translate(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] - compose m with a translation.
// fn mat_rotate(m: &Vec[Vec[Float64]], angle: Float64, axis: &Vec[Float64]) -> Vec[Vec[Float64]] - compose m with a rotation about axis.
// fn mat_scale(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] - compose m with a scale.
// fn mat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Vec[Vec[Float64]] - right-handed view matrix.
// fn mat_perspective(fovy: Float64, aspect: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] - perspective projection matrix.
// fn mat_ortho(left: Float64, right: Float64, bottom: Float64, top: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] - orthographic projection matrix.
// fn mat_transform_point(m: &Vec[Vec[Float64]], p: &Vec[Float64]) -> Vec[Float64] - transform point p by m with perspective divide.
