// XIOM - Math: Matrices
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.matrices

// Depends on: xiom.math

// ============================================================================
// Fixed-size 2x2/3x3/4x4 matrices plus generic dynamic matrices and 4x4
// transforms.
//
// The fixed-size structs (Mat2/Mat3/Mat4, column-major) are declared here;
// geom.xi carries semantically identical fixed-size matrix code, but nominal
// struct types make qualified delegation impossible without conversions, so
// the arithmetic is implemented directly. The dynamic mat_* functions use
// row-major Vec[Vec[Float64]] storage. Every dynamic entry validates its
// inputs in the body and returns a documented sentinel (empty matrix or NaN)
// on dimension/degeneracy errors -- requires/ensures would trap at runtime.
// ============================================================================

use xiom.math;

// 2x2 column-major matrix.
pub type Mat2 = { m00: Float64; m01: Float64; m10: Float64; m11: Float64; }

// 3x3 column-major matrix.
pub type Mat3 = {
  m00: Float64; m01: Float64; m02: Float64;
  m10: Float64; m11: Float64; m12: Float64;
  m20: Float64; m21: Float64; m22: Float64;
}

// 4x4 column-major matrix.
pub type Mat4 = {
  m00: Float64; m01: Float64; m02: Float64; m03: Float64;
  m10: Float64; m11: Float64; m12: Float64; m13: Float64;
  m20: Float64; m21: Float64; m22: Float64; m23: Float64;
  m30: Float64; m31: Float64; m32: Float64; m33: Float64;
}

// ============================================================================
// Mat2
// ============================================================================

// Construct a 2x2 matrix from elements in row-major reading order
// (a11 a12 / a21 a22) stored column-major. O(1).
pub fn mat2_new(a11: Float64, a12: Float64, a21: Float64, a22: Float64) -> Mat2 {
  return Mat2{ m00: a11; m01: a12; m10: a21; m11: a22; };
}

// Matrix product a * b (2x2). O(8) ops.
pub fn mat2_mul(a: Mat2, b: Mat2) -> Mat2 {
  return Mat2{
    m00: a.m00 * b.m00 + a.m01 * b.m10;
    m01: a.m00 * b.m01 + a.m01 * b.m11;
    m10: a.m10 * b.m00 + a.m11 * b.m10;
    m11: a.m10 * b.m01 + a.m11 * b.m11;
  };
}

// Determinant of a 2x2 matrix: m00*m11 - m01*m10. O(1).
pub fn mat2_det(m: Mat2) -> Float64 {
  return m.m00 * m.m11 - m.m01 * m.m10;
}

// Inverse of a 2x2 matrix via the adjugate formula. Returns None when the
// determinant is near zero (|det| < 1e-12, documented singularity cutoff).
// O(1).
pub fn mat2_inv(m: Mat2) -> Option[Mat2] {
  var det = m.m00 * m.m11 - m.m01 * m.m10;
  if math.abs_float(det) < 1e-12 { return None; }
  var inv_det = 1.0 / det;
  return Some(Mat2{
    m00: m.m11 * inv_det;
    m01: -m.m01 * inv_det;
    m10: -m.m10 * inv_det;
    m11: m.m00 * inv_det;
  });
}

// Transpose of a 2x2 matrix. O(1).
pub fn mat2_transpose(m: Mat2) -> Mat2 {
  return Mat2{
    m00: m.m00; m01: m.m10;
    m10: m.m01; m11: m.m11;
  };
}

// ============================================================================
// Mat3
// ============================================================================

// Construct a 3x3 matrix from elements in row-major reading order (three
// rows) stored column-major. O(1).
pub fn mat3_new(a11: Float64, a12: Float64, a13: Float64,
                a21: Float64, a22: Float64, a23: Float64,
                a31: Float64, a32: Float64, a33: Float64) -> Mat3 {
  return Mat3{
    m00: a11; m01: a12; m02: a13;
    m10: a21; m11: a22; m12: a23;
    m20: a31; m21: a32; m22: a33;
  };
}

// Matrix product a * b (3x3). O(27) ops.
pub fn mat3_mul(a: Mat3, b: Mat3) -> Mat3 {
  return Mat3{
    m00: a.m00 * b.m00 + a.m01 * b.m10 + a.m02 * b.m20;
    m01: a.m00 * b.m01 + a.m01 * b.m11 + a.m02 * b.m21;
    m02: a.m00 * b.m02 + a.m01 * b.m12 + a.m02 * b.m22;
    m10: a.m10 * b.m00 + a.m11 * b.m10 + a.m12 * b.m20;
    m11: a.m10 * b.m01 + a.m11 * b.m11 + a.m12 * b.m21;
    m12: a.m10 * b.m02 + a.m11 * b.m12 + a.m12 * b.m22;
    m20: a.m20 * b.m00 + a.m21 * b.m10 + a.m22 * b.m20;
    m21: a.m20 * b.m01 + a.m21 * b.m11 + a.m22 * b.m21;
    m22: a.m20 * b.m02 + a.m21 * b.m12 + a.m22 * b.m22;
  };
}

// Determinant of a 3x3 matrix by cofactor expansion. O(9) ops.
pub fn mat3_det(m: Mat3) -> Float64 {
  return m.m00 * (m.m11 * m.m22 - m.m12 * m.m21)
       - m.m01 * (m.m10 * m.m22 - m.m12 * m.m20)
       + m.m02 * (m.m10 * m.m21 - m.m11 * m.m20);
}

// Inverse of a 3x3 matrix via the adjugate formula. Returns None when the
// determinant is near zero (|det| < 1e-12, documented singularity cutoff).
// O(27) ops.
pub fn mat3_inv(m: Mat3) -> Option[Mat3] {
  var det = mat3_det(m);
  if math.abs_float(det) < 1e-12 { return None; }
  var inv_det = 1.0 / det;
  return Some(Mat3{
    m00: (m.m11 * m.m22 - m.m12 * m.m21) * inv_det;
    m01: (m.m02 * m.m21 - m.m01 * m.m22) * inv_det;
    m02: (m.m01 * m.m12 - m.m02 * m.m11) * inv_det;
    m10: (m.m12 * m.m20 - m.m10 * m.m22) * inv_det;
    m11: (m.m00 * m.m22 - m.m02 * m.m20) * inv_det;
    m12: (m.m02 * m.m10 - m.m00 * m.m12) * inv_det;
    m20: (m.m10 * m.m21 - m.m11 * m.m20) * inv_det;
    m21: (m.m01 * m.m20 - m.m00 * m.m21) * inv_det;
    m22: (m.m00 * m.m11 - m.m01 * m.m10) * inv_det;
  });
}

// Transpose of a 3x3 matrix. O(1).
pub fn mat3_transpose(m: Mat3) -> Mat3 {
  return Mat3{
    m00: m.m00; m01: m.m10; m02: m.m20;
    m10: m.m01; m11: m.m11; m12: m.m21;
    m20: m.m02; m21: m.m12; m22: m.m22;
  };
}

// ============================================================================
// Mat4
// ============================================================================

// Construct a 4x4 matrix from elements in row-major reading order (four
// rows) stored column-major. O(1).
pub fn mat4_new(a11: Float64, a12: Float64, a13: Float64, a14: Float64,
                a21: Float64, a22: Float64, a23: Float64, a24: Float64,
                a31: Float64, a32: Float64, a33: Float64, a34: Float64,
                a41: Float64, a42: Float64, a43: Float64, a44: Float64) -> Mat4 {
  return Mat4{
    m00: a11; m01: a12; m02: a13; m03: a14;
    m10: a21; m11: a22; m12: a23; m13: a24;
    m20: a31; m21: a32; m22: a33; m23: a34;
    m30: a41; m31: a42; m32: a43; m33: a44;
  };
}

// Matrix product a * b (4x4). O(64) ops.
pub fn mat4_mul(a: Mat4, b: Mat4) -> Mat4 {
  return Mat4{
    m00: a.m00 * b.m00 + a.m01 * b.m10 + a.m02 * b.m20 + a.m03 * b.m30;
    m01: a.m00 * b.m01 + a.m01 * b.m11 + a.m02 * b.m21 + a.m03 * b.m31;
    m02: a.m00 * b.m02 + a.m01 * b.m12 + a.m02 * b.m22 + a.m03 * b.m32;
    m03: a.m00 * b.m03 + a.m01 * b.m13 + a.m02 * b.m23 + a.m03 * b.m33;
    m10: a.m10 * b.m00 + a.m11 * b.m10 + a.m12 * b.m20 + a.m13 * b.m30;
    m11: a.m10 * b.m01 + a.m11 * b.m11 + a.m12 * b.m21 + a.m13 * b.m31;
    m12: a.m10 * b.m02 + a.m11 * b.m12 + a.m12 * b.m22 + a.m13 * b.m32;
    m13: a.m10 * b.m03 + a.m11 * b.m13 + a.m12 * b.m23 + a.m13 * b.m33;
    m20: a.m20 * b.m00 + a.m21 * b.m10 + a.m22 * b.m20 + a.m23 * b.m30;
    m21: a.m20 * b.m01 + a.m21 * b.m11 + a.m22 * b.m21 + a.m23 * b.m31;
    m22: a.m20 * b.m02 + a.m21 * b.m12 + a.m22 * b.m22 + a.m23 * b.m32;
    m23: a.m20 * b.m03 + a.m21 * b.m13 + a.m22 * b.m23 + a.m23 * b.m33;
    m30: a.m30 * b.m00 + a.m31 * b.m10 + a.m32 * b.m20 + a.m33 * b.m30;
    m31: a.m30 * b.m01 + a.m31 * b.m11 + a.m32 * b.m21 + a.m33 * b.m31;
    m32: a.m30 * b.m02 + a.m31 * b.m12 + a.m32 * b.m22 + a.m33 * b.m32;
    m33: a.m30 * b.m03 + a.m31 * b.m13 + a.m32 * b.m23 + a.m33 * b.m33;
  };
}

// Determinant of a 4x4 matrix by cofactor expansion along the first row
// (3x3 sub-determinants of the lower rows). O(48) ops.
pub fn mat4_det(m: Mat4) -> Float64 {
  var m00 = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
  var m01 = m.m10 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m32 - m.m22 * m.m30);
  var m02 = m.m10 * (m.m21 * m.m33 - m.m23 * m.m31)
          - m.m11 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m31 - m.m21 * m.m30);
  var m03 = m.m10 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m11 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m12 * (m.m20 * m.m31 - m.m21 * m.m30);
  return m.m00 * m00 - m.m01 * m01 + m.m02 * m02 - m.m03 * m03;
}

// Inverse of a 4x4 matrix via the adjugate (cofactor-transpose / det).
// Returns None when |det| < 1e-12 (documented singularity cutoff). O(150).
pub fn mat4_inv(m: Mat4) -> Option[Mat4] {
  var m00 = m.m11 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m21 * m.m33 - m.m23 * m.m31)
          + m.m13 * (m.m21 * m.m32 - m.m22 * m.m31);
  var m01 = m.m10 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m12 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m32 - m.m22 * m.m30);
  var m02 = m.m10 * (m.m21 * m.m33 - m.m23 * m.m31)
          - m.m11 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m13 * (m.m20 * m.m31 - m.m21 * m.m30);
  var m03 = m.m10 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m11 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m12 * (m.m20 * m.m31 - m.m21 * m.m30);
  var det = m.m00 * m00 - m.m01 * m01 + m.m02 * m02 - m.m03 * m03;
  if math.abs_float(det) < 1e-12 { return None; }
  var inv_det = 1.0 / det;
  var c00 = m00;
  var c01 = -m01;
  var c02 = m02;
  var c03 = -m03;
  var c10 = -(m.m01 * (m.m22 * m.m33 - m.m23 * m.m32)
             - m.m02 * (m.m21 * m.m33 - m.m23 * m.m31)
             + m.m03 * (m.m21 * m.m32 - m.m22 * m.m31));
  var c11 = m.m00 * (m.m22 * m.m33 - m.m23 * m.m32)
          - m.m02 * (m.m20 * m.m33 - m.m23 * m.m30)
          + m.m03 * (m.m20 * m.m32 - m.m22 * m.m30);
  var c12 = -(m.m00 * (m.m21 * m.m33 - m.m23 * m.m31)
             - m.m01 * (m.m20 * m.m33 - m.m23 * m.m30)
             + m.m03 * (m.m20 * m.m31 - m.m21 * m.m30));
  var c13 = m.m00 * (m.m21 * m.m32 - m.m22 * m.m31)
          - m.m01 * (m.m20 * m.m32 - m.m22 * m.m30)
          + m.m02 * (m.m20 * m.m31 - m.m21 * m.m30);
  var c20 = m.m01 * (m.m12 * m.m33 - m.m13 * m.m32)
          - m.m02 * (m.m11 * m.m33 - m.m13 * m.m31)
          + m.m03 * (m.m11 * m.m32 - m.m12 * m.m31);
  var c21 = -(m.m00 * (m.m12 * m.m33 - m.m13 * m.m32)
             - m.m02 * (m.m10 * m.m33 - m.m13 * m.m30)
             + m.m03 * (m.m10 * m.m32 - m.m12 * m.m30));
  var c22 = m.m00 * (m.m11 * m.m33 - m.m13 * m.m31)
          - m.m01 * (m.m10 * m.m33 - m.m13 * m.m30)
          + m.m03 * (m.m10 * m.m31 - m.m11 * m.m30);
  var c23 = -(m.m00 * (m.m11 * m.m32 - m.m12 * m.m31)
             - m.m01 * (m.m10 * m.m32 - m.m12 * m.m30)
             + m.m02 * (m.m10 * m.m31 - m.m11 * m.m30));
  var c30 = -(m.m01 * (m.m12 * m.m23 - m.m13 * m.m22)
             - m.m02 * (m.m11 * m.m23 - m.m13 * m.m21)
             + m.m03 * (m.m11 * m.m22 - m.m12 * m.m21));
  var c31 = m.m00 * (m.m12 * m.m23 - m.m13 * m.m22)
          - m.m02 * (m.m10 * m.m23 - m.m13 * m.m20)
          + m.m03 * (m.m10 * m.m22 - m.m12 * m.m20);
  var c32 = -(m.m00 * (m.m11 * m.m23 - m.m13 * m.m21)
             - m.m01 * (m.m10 * m.m23 - m.m13 * m.m20)
             + m.m03 * (m.m10 * m.m21 - m.m11 * m.m20));
  var c33 = m.m00 * (m.m11 * m.m22 - m.m12 * m.m21)
          - m.m01 * (m.m10 * m.m22 - m.m12 * m.m20)
          + m.m02 * (m.m10 * m.m21 - m.m11 * m.m20);
  return Some(Mat4{
    m00: c00 * inv_det;
    m01: c10 * inv_det;
    m02: c20 * inv_det;
    m03: c30 * inv_det;
    m10: c01 * inv_det;
    m11: c11 * inv_det;
    m12: c21 * inv_det;
    m13: c31 * inv_det;
    m20: c02 * inv_det;
    m21: c12 * inv_det;
    m22: c22 * inv_det;
    m23: c32 * inv_det;
    m30: c03 * inv_det;
    m31: c13 * inv_det;
    m32: c23 * inv_det;
    m33: c33 * inv_det;
  });
}

// Transpose of a 4x4 matrix. O(1).
pub fn mat4_transpose(m: Mat4) -> Mat4 {
  return Mat4{
    m00: m.m00; m01: m.m10; m02: m.m20; m03: m.m30;
    m10: m.m01; m11: m.m11; m12: m.m21; m13: m.m31;
    m20: m.m02; m21: m.m12; m22: m.m22; m23: m.m32;
    m30: m.m03; m31: m.m13; m32: m.m23; m33: m.m33;
  };
}

// ============================================================================
// Dynamic matrices (row-major Vec[Vec[Float64]])
// ============================================================================

// n x n identity matrix. Returns an empty matrix for n <= 0 (documented).
// O(n^2).
pub fn mat_identity(n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j {
        row.push(1.0);
      } else {
        row.push(0.0);
      }
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Dynamic matrix product a * b. Returns an empty matrix when the inner
// dimensions disagree (a.cols != b.rows), or when either input is empty
// (documented; no silent garbage). O(rows * cols * inner).
pub fn mat_mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var ra = a.len();
  var ca = 0;
  if ra > 0 {
    ca = a[0].len();
  }
  var rb = b.len();
  var cb = 0;
  if rb > 0 {
    cb = b[0].len();
  }
  var out = Vec[Vec[Float64]].new();
  if ra == 0 || rb == 0 || ca != rb { return out; }
  var i = 0;
  while i < ra {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cb {
      var s = 0.0;
      var k = 0;
      while k < ca {
        s = s + a[i][k] * b[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Determinant of a dynamic square matrix via Laplace cofactor expansion.
// Returns NaN (0.0/0.0) for non-square or empty input (documented).
// O(n!).
pub fn mat_det(m: &Vec[Vec[Float64]]) -> Float64 {
  var n = m.len();
  if n == 0 { return 0.0 / 0.0; }
  var cols = m[0].len();
  if cols != n { return 0.0 / 0.0; }
  if n == 1 { return m[0][0]; }
  if n == 2 {
    return m[0][0] * m[1][1] - m[0][1] * m[1][0];
  }
  var s = 0.0;
  var j = 0;
  while j < n {
    var sub = Vec[Vec[Float64]].new();
    var i = 1;
    while i < n {
      var row = Vec[Float64].new();
      var c = 0;
      while c < n {
        if c != j {
          row.push(m[i][c]);
        }
        c = c + 1;
      }
      sub.push(row);
      i = i + 1;
    }
    var term = mat_det(&sub);
    if j % 2 == 0 {
      s = s + m[0][j] * term;
    } else {
      s = s - m[0][j] * term;
    }
    j = j + 1;
  }
  return s;
}

// Inverse of a dynamic square matrix via Gauss-Jordan elimination.
// Returns None for non-square, empty, or (numerically) singular input
// (documented; pivot tolerance 1e-12). O(n^3).
pub fn mat_inv(m: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] {
  var n = m.len();
  if n == 0 { return None; }
  var cols = m[0].len();
  if cols != n { return None; }
  // Build the augmented matrix [m | I] by appending identity columns.
  var aug = Vec[Vec[Float64]].new();
  var r = 0;
  while r < n {
    var row = Vec[Float64].new();
    var c = 0;
    while c < n {
      row.push(m[r][c]);
      c = c + 1;
    }
    var q = 0;
    while q < n {
      if r == q {
        row.push(1.0);
      } else {
        row.push(0.0);
      }
      q = q + 1;
    }
    aug.push(row);
    r = r + 1;
  }
  var p = 0;
  while p < n {
    var piv = aug[p][p];
    if math.abs_float(piv) < 1e-12 {
      // partial pivot: swap with a lower row carrying a larger pivot
      var s = p + 1;
      var swapped = false;
      while s < n {
        if math.abs_float(aug[s][p]) > math.abs_float(piv) {
          var t = 0;
          while t < 2 * n {
            var tmp = aug[p][t];
            aug[p][t] = aug[s][t];
            aug[s][t] = tmp;
            t = t + 1;
          }
          piv = aug[p][p];
          swapped = true;
          s = n;
        }
        s = s + 1;
      }
      if math.abs_float(aug[p][p]) < 1e-12 { return None; }
    }
    var inv_piv = 1.0 / aug[p][p];
    var c = 0;
    while c < 2 * n {
      aug[p][c] = aug[p][c] * inv_piv;
      c = c + 1;
    }
    var row = 0;
    while row < n {
      if row != p {
        var factor = aug[row][p];
        if factor != 0.0 {
          var col = 0;
          while col < 2 * n {
            aug[row][col] = aug[row][col] - factor * aug[p][col];
            col = col + 1;
          }
        }
      }
      row = row + 1;
    }
    p = p + 1;
  }
  var inv = Vec[Vec[Float64]].new();
  var ri = 0;
  while ri < n {
    var row = Vec[Float64].new();
    var ci = 0;
    while ci < n {
      row.push(aug[ri][n + ci]);
      ci = ci + 1;
    }
    inv.push(row);
    ri = ri + 1;
  }
  return Some(inv);
}

// m * T where T is the 4x4 translation matrix by (x, y, z). When m is not
// 4x4 the input is returned unchanged (documented). O(1).
pub fn mat_translate(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] {
  if m.len() != 4 { return clone_mat(m); }
  var t = _translation(x, y, z);
  return _mul4(m, &t);
}

// m * R where R is the 4x4 rotation by angle radians about axis
// (axis is normalised internally). A zero axis returns m unchanged
// (documented); a non-4x4 m is returned unchanged. O(1).
pub fn mat_rotate(m: &Vec[Vec[Float64]], angle: Float64, axis: &Vec[Float64]) -> Vec[Vec[Float64]] {
  if m.len() != 4 { return clone_mat(m); }
  if axis.len() != 3 { return clone_mat(m); }
  var ax = axis[0];
  var ay = axis[1];
  var az = axis[2];
  var nlen = math.sqrt(ax * ax + ay * ay + az * az);
  if nlen == 0.0 { return clone_mat(m); }
  var ux = ax / nlen;
  var uy = ay / nlen;
  var uz = az / nlen;
  var c = math.cos(angle);
  var s = math.sin(angle);
  var t = 1.0 - c;
  var r = Vec[Vec[Float64]].new();
  var row0 = Vec[Float64].new();
  row0.push(t * ux * ux + c);
  row0.push(t * ux * uy - s * uz);
  row0.push(t * ux * uz + s * uy);
  row0.push(0.0);
  var row1 = Vec[Float64].new();
  row1.push(t * ux * uy + s * uz);
  row1.push(t * uy * uy + c);
  row1.push(t * uy * uz - s * ux);
  row1.push(0.0);
  var row2 = Vec[Float64].new();
  row2.push(t * ux * uz - s * uy);
  row2.push(t * uy * uz + s * ux);
  row2.push(t * uz * uz + c);
  row2.push(0.0);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(0.0);
  row3.push(1.0);
  r.push(row0);
  r.push(row1);
  r.push(row2);
  r.push(row3);
  return _mul4(m, &r);
}

// m * S where S is the 4x4 scale matrix by (x, y, z). A non-4x4 m is
// returned unchanged (documented). O(1).
pub fn mat_scale(m: &Vec[Vec[Float64]], x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] {
  if m.len() != 4 { return clone_mat(m); }
  var s = Vec[Vec[Float64]].new();
  var row0 = Vec[Float64].new();
  row0.push(x);
  row0.push(0.0);
  row0.push(0.0);
  row0.push(0.0);
  var row1 = Vec[Float64].new();
  row1.push(0.0);
  row1.push(y);
  row1.push(0.0);
  row1.push(0.0);
  var row2 = Vec[Float64].new();
  row2.push(0.0);
  row2.push(0.0);
  row2.push(z);
  row2.push(0.0);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(0.0);
  row3.push(1.0);
  s.push(row0);
  s.push(row1);
  s.push(row2);
  s.push(row3);
  return _mul4(m, &s);
}

// Right-handed look-at view matrix: camera at eye looking at target with
// up vector. eye/target/up are length-3 dynamic vectors; vectors of any
// other length return an empty matrix (documented). O(1).
pub fn mat_look_at(eye: &Vec[Float64], target: &Vec[Float64], up: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if eye.len() != 3 || target.len() != 3 || up.len() != 3 { return out; }
  var fx = target[0] - eye[0];
  var fy = target[1] - eye[1];
  var fz = target[2] - eye[2];
  var fl = math.sqrt(fx * fx + fy * fy + fz * fz);
  if fl == 0.0 { return out; }
  fx = fx / fl;
  fy = fy / fl;
  fz = fz / fl;
  var ux = up[0];
  var uy = up[1];
  var uz = up[2];
  // right = f x up
  var rx = fy * uz - fz * uy;
  var ry = fz * ux - fx * uz;
  var rz = fx * uy - fy * ux;
  var rl = math.sqrt(rx * rx + ry * ry + rz * rz);
  if rl == 0.0 { return out; }
  rx = rx / rl;
  ry = ry / rl;
  rz = rz / rl;
  // u2 = right x f
  var vx = ry * fz - rz * fy;
  var vy = rz * fx - rx * fz;
  var vz = rx * fy - ry * fx;
  var row0 = Vec[Float64].new();
  row0.push(rx);
  row0.push(ry);
  row0.push(rz);
  row0.push(-(rx * eye[0] + ry * eye[1] + rz * eye[2]));
  var row1 = Vec[Float64].new();
  row1.push(vx);
  row1.push(vy);
  row1.push(vz);
  row1.push(-(vx * eye[0] + vy * eye[1] + vz * eye[2]));
  var row2 = Vec[Float64].new();
  row2.push(-fx);
  row2.push(-fy);
  row2.push(-fz);
  row2.push(fx * eye[0] + fy * eye[1] + fz * eye[2]);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(0.0);
  row3.push(1.0);
  out.push(row0);
  out.push(row1);
  out.push(row2);
  out.push(row3);
  return out;
}

// Perspective projection matrix (right-handed, standard OpenGL mapping to
// NDC [-1, 1]^3). Returns an empty matrix for fovy <= 0, aspect <= 0, or
// near == far (documented). O(1).
pub fn mat_perspective(fovy: Float64, aspect: Float64, near: Float64, far: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if fovy <= 0.0 || aspect <= 0.0 || near == far { return out; }
  var f = 1.0 / math.tan(fovy * 0.5);
  var nf = 1.0 / (near - far);
  var row0 = Vec[Float64].new();
  row0.push(f / aspect);
  row0.push(0.0);
  row0.push(0.0);
  row0.push(0.0);
  var row1 = Vec[Float64].new();
  row1.push(0.0);
  row1.push(f);
  row1.push(0.0);
  row1.push(0.0);
  var row2 = Vec[Float64].new();
  row2.push(0.0);
  row2.push(0.0);
  row2.push((far + near) * nf);
  row2.push((2.0 * far * near) * nf);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(-1.0);
  row3.push(0.0);
  out.push(row0);
  out.push(row1);
  out.push(row2);
  out.push(row3);
  return out;
}

// Orthographic projection matrix mapping [l, r] x [b, t] x [n, f] to NDC
// [-1, 1]^3. Returns an empty matrix when any two facing planes coincide
// (documented). O(1).
pub fn mat_ortho(left: Float64, right: Float64, bottom: Float64, top: Float64,
                 near: Float64, far: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var rl = right - left;
  var tb = top - bottom;
  var fd = far - near;
  if rl == 0.0 || tb == 0.0 || fd == 0.0 { return out; }
  var row0 = Vec[Float64].new();
  row0.push(2.0 / rl);
  row0.push(0.0);
  row0.push(0.0);
  row0.push(-(right + left) / rl);
  var row1 = Vec[Float64].new();
  row1.push(0.0);
  row1.push(2.0 / tb);
  row1.push(0.0);
  row1.push(-(top + bottom) / tb);
  var row2 = Vec[Float64].new();
  row2.push(0.0);
  row2.push(0.0);
  row2.push(-2.0 / fd);
  row2.push(-(far + near) / fd);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(0.0);
  row3.push(1.0);
  out.push(row0);
  out.push(row1);
  out.push(row2);
  out.push(row3);
  return out;
}

// ============================================================================
// Internal helpers
// ============================================================================

// 4x4 translation matrix in row-major storage.
fn _translation(x: Float64, y: Float64, z: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var row0 = Vec[Float64].new();
  row0.push(1.0);
  row0.push(0.0);
  row0.push(0.0);
  row0.push(x);
  var row1 = Vec[Float64].new();
  row1.push(0.0);
  row1.push(1.0);
  row1.push(0.0);
  row1.push(y);
  var row2 = Vec[Float64].new();
  row2.push(0.0);
  row2.push(0.0);
  row2.push(1.0);
  row2.push(z);
  var row3 = Vec[Float64].new();
  row3.push(0.0);
  row3.push(0.0);
  row3.push(0.0);
  row3.push(1.0);
  out.push(row0);
  out.push(row1);
  out.push(row2);
  out.push(row3);
  return out;
}

// 4x4 product of two row-major 4x4 matrices.
fn _mul4(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < 4 {
    var row = Vec[Float64].new();
    var j = 0;
    while j < 4 {
      var s = 0.0;
      var k = 0;
      while k < 4 {
        s = s + a[i][k] * b[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Shallow copy of a dynamic matrix.
fn clone_mat(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < m[i].len() {
      row.push(m[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}
