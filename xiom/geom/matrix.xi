// XIOM - Geom: Matrix
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.geom.matrix

// Depends on: xiom.geom

// ============================================================================
// Fixed and dynamic matrix types, factorizations, and linear solvers. NOTE:
// current implementation lives in geom.xi REAL + math/matrices.xi stub - move
// the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// type Mat2 - 2x2 matrix; struct { m00; m01; m10; m11 } in column-major order.
// type Mat3 - 3x3 matrix; struct of nine m** elements in column-major order.
// type Mat4 - 4x4 matrix; struct of sixteen m** elements in column-major order.
// type MatMN - dynamic matrix; struct { rows: Int; cols: Int; data: Vec[Float64] }.
// fn mat2_new(a: Float64, b: Float64, c: Float64, d: Float64) -> Mat2 - construct a 2x2 matrix. TODO(compiler): implement.
// fn mat3_new(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64, g: Float64, h: Float64, i: Float64) -> Mat3 - construct a 3x3 matrix. TODO(compiler): implement.
// fn mat4_new(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64, g: Float64, h: Float64, i: Float64, j: Float64, k: Float64, l: Float64, m: Float64, n: Float64, o: Float64, p: Float64) -> Mat4 - construct a 4x4 matrix. TODO(compiler): implement.
// fn identity(n: Int) -> Vec[Vec[Float64]] - n x n identity matrix. TODO(compiler): implement.
// fn zero(rows: Int, cols: Int) -> Vec[Vec[Float64]] - all-zero matrix. TODO(compiler): implement.
// fn one(rows: Int, cols: Int) -> Vec[Vec[Float64]] - all-ones matrix. TODO(compiler): implement.
// fn add(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - element-wise addition. TODO(compiler): implement.
// fn sub(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - element-wise subtraction. TODO(compiler): implement.
// fn mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - matrix product. TODO(compiler): implement.
// fn scalar_mul(a: &Vec[Vec[Float64]], s: Float64) -> Vec[Vec[Float64]] - scale every element. TODO(compiler): implement.
// fn transpose(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - matrix transpose. TODO(compiler): implement.
// fn det(a: &Vec[Vec[Float64]]) -> Float64 - determinant of a square matrix. TODO(compiler): implement.
// fn inverse(a: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] - inverse; None when singular. TODO(compiler): implement.
// fn adjugate(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - adjugate (classical) matrix. TODO(compiler): implement.
// fn cofactor(a: &Vec[Vec[Float64]], row: Int, col: Int) -> Float64 - signed minor at (row, col). TODO(compiler): implement.
// fn minor(a: &Vec[Vec[Float64]], row: Int, col: Int) -> Float64 - determinant of the submatrix at (row, col). TODO(compiler): implement.
// fn trace(a: &Vec[Vec[Float64]]) -> Float64 - sum of the main diagonal. TODO(compiler): implement.
// fn rank(a: &Vec[Vec[Float64]]) -> Int - rank of the matrix. TODO(compiler): implement.
// fn nullity(a: &Vec[Vec[Float64]]) -> Int - number of columns minus rank. TODO(compiler): implement.
// fn eigenvalues(a: &Vec[Vec[Float64]]) -> Vec[Float64] - eigenvalues of a square matrix. TODO(compiler): implement.
// fn eigenvectors(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - eigenvectors of a square matrix. TODO(compiler): implement.
// fn diagonal(a: &Vec[Vec[Float64]]) -> Vec[Float64] - main diagonal entries. TODO(compiler): implement.
// fn diag_mul(a: &Vec[Vec[Float64]], d: &Vec[Float64]) -> Vec[Vec[Float64]] - multiply a by a diagonal matrix. TODO(compiler): implement.
// fn hadamard(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - element-wise product. TODO(compiler): implement.
// fn kronecker(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - Kronecker product. TODO(compiler): implement.
// fn lu_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]]) - LU factorization (L, U). TODO(compiler): implement.
// fn qr_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]]) - QR factorization (Q, R). TODO(compiler): implement.
// fn svd_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Float64], Vec[Vec[Float64]]) - SVD (U, s, V). TODO(compiler): implement.
// fn cholesky(a: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] - Cholesky factor; None if not SPD. TODO(compiler): implement.
// fn solve_linear(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - solve A*x = b. TODO(compiler): implement.
// fn least_squares(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - least-squares solution. TODO(compiler): implement.
// fn condition_number(a: &Vec[Vec[Float64]]) -> Float64 - ratio of largest to smallest singular value. TODO(compiler): implement.
