// XIOM - Geom: Linear
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.linear

// Depends on: xiom.geom

// ============================================================================
// Linear algebra helpers: orthogonalization, matrix predicates, matrix
// functions, and skew-symmetric conversions. NOTE: new sublib - no existing
// home; implement the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn gram_schmidt(vectors: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - orthonormalize a set of vectors. TODO(compiler): implement.
// fn orthogonalize(vectors: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - orthogonalize without normalizing. TODO(compiler): implement.
// fn normalize_columns(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - unit-length columns. TODO(compiler): implement.
// fn normalize_rows(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - unit-length rows. TODO(compiler): implement.
// fn is_orthogonal(m: &Vec[Vec[Float64]]) -> Bool - true if m * m^T is identity. TODO(compiler): implement.
// fn is_symmetric(m: &Vec[Vec[Float64]]) -> Bool - true if m equals its transpose. TODO(compiler): implement.
// fn is_skew_symmetric(m: &Vec[Vec[Float64]]) -> Bool - true if m equals minus its transpose. TODO(compiler): implement.
// fn is_positive_definite(m: &Vec[Vec[Float64]]) -> Bool - true if m is symmetric positive definite. TODO(compiler): implement.
// fn is_diagonal_dominant(m: &Vec[Vec[Float64]]) -> Bool - true if |m[i][i]| >= sum of off-diagonals. TODO(compiler): implement.
// fn matrix_exponential(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - matrix exponential via series. TODO(compiler): implement.
// fn matrix_logarithm(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - principal matrix logarithm. TODO(compiler): implement.
// fn matrix_sqrt(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - principal matrix square root. TODO(compiler): implement.
// fn matrix_power(m: &Vec[Vec[Float64]], p: Int) -> Vec[Vec[Float64]] - m raised to the integer power p. TODO(compiler): implement.
// fn vec_to_skew(v: &Vec[Float64]) -> Vec[Vec[Float64]] - skew-symmetric matrix of a 3-vector. TODO(compiler): implement.
// fn skew_to_vec(m: &Vec[Vec[Float64]]) -> Vec[Float64] - 3-vector from a skew-symmetric matrix. TODO(compiler): implement.
