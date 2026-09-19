// XIOM - Geom: Matrix
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.geom.matrix

// Depends on: xiom.geom

// ============================================================================
// Fixed and dynamic matrix types, factorizations, and linear solvers. NOTE:
// current implementation lives in geom.xi REAL + math/matrices.xi stub - move
// the functions here during the implementation phase. TODO(compiler): implement.
//
// IMPORTANT (compiler): by-ref nested float Vec element reads (BUG 26 #1)
// return garbage, so every `&Vec[Vec[Float64]]` parameter is copied into a
// local matrix with single-level row copies first, and element access uses
// direct double indexing on that local copy. All returned matrices are built
// with fresh row allocations. Eigen-based decompositions are implemented for
// 2x2 matrices (analytic); larger sizes return empty results (documented).
// ============================================================================

use xiom.math;

/// 2x2 column-major matrix.
pub type Mat2 = { m00: Float64; m01: Float64; m10: Float64; m11: Float64; }

/// 3x3 column-major matrix.
pub type Mat3 = {
  m00: Float64; m01: Float64; m02: Float64;
  m10: Float64; m11: Float64; m12: Float64;
  m20: Float64; m21: Float64; m22: Float64;
}

/// 4x4 column-major matrix.
pub type Mat4 = {
  m00: Float64; m01: Float64; m02: Float64; m03: Float64;
  m10: Float64; m11: Float64; m12: Float64; m13: Float64;
  m20: Float64; m21: Float64; m22: Float64; m23: Float64;
  m30: Float64; m31: Float64; m32: Float64; m33: Float64;
}

/// Dynamic m x n matrix stored row-major.
pub type MatMN = { rows: Int; cols: Int; data: Vec[Float64]; }

/// Construct a 2x2 matrix. O(1).
pub fn mat2_new(a: Float64, b: Float64, c: Float64, d: Float64) -> Mat2 {
  return Mat2{ m00: a; m01: b; m10: c; m11: d; };
}

/// Construct a 3x3 matrix. O(1).
pub fn mat3_new(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64, g: Float64, h: Float64, i: Float64) -> Mat3 {
  return Mat3{
    m00: a; m01: b; m02: c;
    m10: d; m11: e; m12: f;
    m20: g; m21: h; m22: i;
  };
}

/// Construct a 4x4 matrix. O(1).
pub fn mat4_new(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64, g: Float64, h: Float64, i: Float64, j: Float64, k: Float64, l: Float64, m: Float64, n: Float64, o: Float64, p: Float64) -> Mat4 {
  return Mat4{
    m00: a; m01: b; m02: c; m03: d;
    m10: e; m11: f; m12: g; m13: h;
    m20: i; m21: j; m22: k; m23: l;
    m30: m; m31: n; m32: o; m33: p;
  };
}

/// n x n identity matrix. O(n^2).
pub fn identity(n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// rows x cols zero matrix. O(n*m).
pub fn zero(rows: Int, cols: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < rows {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cols {
      row.push(0.0);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// rows x cols all-ones matrix. O(n*m).
pub fn one(rows: Int, cols: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < rows {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cols {
      row.push(1.0);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Element-wise addition of two same-shape matrices. Empty matrix on shape
/// mismatch. O(n*m).
pub fn add(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var r = ac.len();
  if bc.len() != r { return out; }
  if r == 0 { return out; }
  var c = ac[0].len();
  if bc[0].len() != c { return out; }
  i = 0;
  while i < r {
    var row = Vec[Float64].new();
    var j = 0;
    while j < c {
      row.push(ac[i][j] + bc[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Element-wise subtraction of two same-shape matrices. Empty matrix on shape
/// mismatch. O(n*m).
pub fn sub(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var r = ac.len();
  if bc.len() != r { return out; }
  if r == 0 { return out; }
  var c = ac[0].len();
  if bc[0].len() != c { return out; }
  i = 0;
  while i < r {
    var row = Vec[Float64].new();
    var j = 0;
    while j < c {
      row.push(ac[i][j] - bc[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Matrix product a * b. Empty matrix on inner-dimension mismatch. O(n^3).
pub fn mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var ra = ac.len();
  if ra == 0 { return out; }
  var ca = ac[0].len();
  var rb = bc.len();
  if rb == 0 { return out; }
  var cb = bc[0].len();
  if ca != rb { return out; }
  i = 0;
  while i < ra {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cb {
      var s = 0.0;
      var k = 0;
      while k < ca {
        s = s + ac[i][k] * bc[k][j];
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

/// Scale every element of a by s. O(n*m).
pub fn scalar_mul(a: &Vec[Vec[Float64]], s: Float64) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  i = 0;
  while i < ac.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < ac[i].len() {
      row.push(ac[i][j] * s);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Matrix transpose. Empty matrix for a ragged input. O(n*m).
pub fn transpose(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var r = ac.len();
  if r == 0 { return out; }
  var c = ac[0].len();
  var j = 0;
  while j < c {
    var col = Vec[Float64].new();
    i = 0;
    while i < r {
      col.push(ac[i][j]);
      i = i + 1;
    }
    out.push(col);
    j = j + 1;
  }
  return out;
}

/// Determinant of a square matrix via Gaussian elimination with partial
/// pivoting. NaN for non-square input. O(n^3).
pub fn det(a: &Vec[Vec[Float64]]) -> Float64 {
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    sc.push(a[i]);
    i = i + 1;
  }
  var ac = Vec[Vec[Float64]].new();
  i = 0;
  while i < sc.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < sc[i].len() {
      row.push(sc[i][j]);
      j = j + 1;
    }
    ac.push(row);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return 0.0; }
  if ac[0].len() != n { return 0.0 / 0.0; }
  var d = 1.0;
  var sign = 1.0;
  var k = 0;
  while k < n {
    var p = k;
    var pk = math.abs_float(ac[k][k]);
    var t = k + 1;
    while t < n {
      var av = math.abs_float(ac[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return 0.0;
    }
    if p != k {
      var jj = 0;
      while jj < n {
        var tv = ac[p][jj];
        ac[p][jj] = ac[k][jj];
        ac[k][jj] = tv;
        jj = jj + 1;
      }
      sign = -sign;
    }
    var piv = ac[k][k];
    var r = k + 1;
    while r < n {
      var f = ac[r][k] / piv;
      var j = k + 1;
      while j < n {
        ac[r][j] = ac[r][j] - f * ac[k][j];
        j = j + 1;
      }
      r = r + 1;
    }
    d = d * piv;
    k = k + 1;
  }
  return d * sign;
}

/// Inverse of a square matrix via Gauss-Jordan elimination with partial
/// pivoting. None when singular or non-square. O(n^3).
pub fn inverse(a: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] {
  var sc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    sc.push(a[i]);
    i = i + 1;
  }
  var ac = Vec[Vec[Float64]].new();
  i = 0;
  while i < sc.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < sc[i].len() {
      row.push(sc[i][j]);
      j = j + 1;
    }
    ac.push(row);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return None; }
  if ac[0].len() != n { return None; }
  var aug = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(ac[i][j]);
      j = j + 1;
    }
    j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    aug.push(row);
    i = i + 1;
  }
  var k = 0;
  while k < n {
    var p = k;
    var pk = math.abs_float(aug[k][k]);
    var t = k + 1;
    while t < n {
      var av = math.abs_float(aug[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return None;
    }
    if p != k {
      var jj = 0;
      while jj < 2 * n {
        var tv = aug[p][jj];
        aug[p][jj] = aug[k][jj];
        aug[k][jj] = tv;
        jj = jj + 1;
      }
    }
    var piv = aug[k][k];
    var j = 0;
    while j < 2 * n {
      aug[k][j] = aug[k][j] / piv;
      j = j + 1;
    }
    var r = 0;
    while r < n {
      if r != k {
        var f = aug[r][k];
        if f != 0.0 {
          var jj = 0;
          while jj < 2 * n {
            aug[r][jj] = aug[r][jj] - f * aug[k][jj];
            jj = jj + 1;
          }
        }
      }
      r = r + 1;
    }
    k = k + 1;
  }
  var out = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(aug[i][n + j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return Some(out);
}

/// Determinant of the submatrix obtained by deleting row and col. NaN for
/// non-square input or out-of-range indices. O(n^3).
pub fn minor(a: &Vec[Vec[Float64]], row: Int, col: Int) -> Float64 {
  var sc = Vec[Vec[Float64]].new();
  var ci = 0;
  while ci < a.len() {
    sc.push(a[ci]);
    ci = ci + 1;
  }
  var ac = Vec[Vec[Float64]].new();
  ci = 0;
  while ci < sc.len() {
    var rowv = Vec[Float64].new();
    var cj = 0;
    while cj < sc[ci].len() {
      rowv.push(sc[ci][cj]);
      cj = cj + 1;
    }
    ac.push(rowv);
    ci = ci + 1;
  }
  var n = ac.len();
  if n == 0 { return 0.0; }
  if ac[0].len() != n { return 0.0 / 0.0; }
  if row < 0 || row >= n || col < 0 || col >= n { return 0.0 / 0.0; }
  var sm = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    if i == row { i = i + 1; }
    if i >= n { break; }
    var r = Vec[Float64].new();
    var j = 0;
    while j < n {
      if j != col {
        r.push(ac[i][j]);
      }
      j = j + 1;
    }
    sm.push(r);
    i = i + 1;
  }
  var m = sm.len();
  if m == 0 { return 1.0; }
  var d = 1.0;
  var sign = 1.0;
  var k = 0;
  while k < m {
    var p = k;
    var pk = math.abs_float(sm[k][k]);
    var t = k + 1;
    while t < m {
      var av = math.abs_float(sm[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return 0.0;
    }
    if p != k {
      var jj = 0;
      while jj < m {
        var tv = sm[p][jj];
        sm[p][jj] = sm[k][jj];
        sm[k][jj] = tv;
        jj = jj + 1;
      }
      sign = -sign;
    }
    var piv = sm[k][k];
    var r2 = k + 1;
    while r2 < m {
      var f = sm[r2][k] / piv;
      var j2 = k + 1;
      while j2 < m {
        sm[r2][j2] = sm[r2][j2] - f * sm[k][j2];
        j2 = j2 + 1;
      }
      r2 = r2 + 1;
    }
    d = d * piv;
    k = k + 1;
  }
  return d * sign;
}

/// Signed minor (cofactor) at (row, col): (-1)^(row+col) * det of the deleted
/// submatrix. NaN for non-square or out-of-range input. O(n^3).
pub fn cofactor(a: &Vec[Vec[Float64]], row: Int, col: Int) -> Float64 {
  var m = minor(a, row, col);
  if m != m { return m; }
  if (row + col) % 2 == 1 { return -m; }
  return m;
}

/// Adjugate (classical) matrix: the transpose of the cofactor matrix. Empty
/// matrix for non-square input. O(n^4).
pub fn adjugate(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return out; }
  if ac[0].len() != n { return out; }
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      var c = cofactor(a, i, j);
      row.push(c);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return transpose(&out);
}

/// Trace (sum of the main diagonal) of a square matrix. NaN for non-square. O(n).
pub fn trace(a: &Vec[Vec[Float64]]) -> Float64 {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return 0.0; }
  if ac[0].len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  i = 0;
  while i < n {
    s = s + ac[i][i];
    i = i + 1;
  }
  return s;
}

/// Rank of a matrix via Gaussian elimination with partial pivoting. O(n^3).
pub fn rank(a: &Vec[Vec[Float64]]) -> Int {
  var sc = Vec[Vec[Float64]].new();
  var ci = 0;
  while ci < a.len() {
    sc.push(a[ci]);
    ci = ci + 1;
  }
  var ac = Vec[Vec[Float64]].new();
  ci = 0;
  while ci < sc.len() {
    var rowv = Vec[Float64].new();
    var cj = 0;
    while cj < sc[ci].len() {
      rowv.push(sc[ci][cj]);
      cj = cj + 1;
    }
    ac.push(rowv);
    ci = ci + 1;
  }
  var r = ac.len();
  if r == 0 { return 0; }
  var c = ac[0].len();
  var rank_val = 0;
  var row = 0;
  var col = 0;
  while row < r && col < c {
    var p = row;
    var pk = math.abs_float(ac[row][col]);
    var t = row + 1;
    while t < r {
      var av = math.abs_float(ac[t][col]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      col = col + 1;
    } else {
      if p != row {
        var jj = 0;
        while jj < c {
          var tv = ac[p][jj];
          ac[p][jj] = ac[row][jj];
          ac[row][jj] = tv;
          jj = jj + 1;
        }
      }
      var piv = ac[row][col];
      var rr = 0;
      while rr < r {
        if rr != row {
          var f = ac[rr][col] / piv;
          var j = col;
          while j < c {
            ac[rr][j] = ac[rr][j] - f * ac[row][j];
            j = j + 1;
          }
        }
        rr = rr + 1;
      }
      rank_val = rank_val + 1;
      row = row + 1;
      col = col + 1;
    }
  }
  return rank_val;
}

/// Nullity of a matrix: number of columns minus the rank. O(n^3).
pub fn nullity(a: &Vec[Vec[Float64]]) -> Int {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var cols = 0;
  if ac.len() > 0 {
    cols = ac[0].len();
  }
  return cols - rank(a);
}

/// Eigenvalues of a square matrix. Implemented analytically for 2x2 matrices;
/// returns the empty vector for any other size (documented). O(1).
pub fn eigenvalues(a: &Vec[Vec[Float64]]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n != 2 { return out; }
  if ac[0].len() != 2 { return out; }
  var tr = ac[0][0] + ac[1][1];
  var de = ac[0][0] * ac[1][1] - ac[0][1] * ac[1][0];
  var disc = tr * tr - 4.0 * de;
  var sq = 0.0;
  if disc < 0.0 {
    sq = math.sqrt(-disc);
    out.push(tr * 0.5);
    out.push(sq * 0.5);
    return out;
  }
  sq = math.sqrt(disc);
  out.push((tr + sq) * 0.5);
  out.push((tr - sq) * 0.5);
  return out;
}

/// Eigenvectors of a square matrix (each row is a unit eigenvector, in the same
/// order as eigenvalues). Implemented analytically for 2x2 matrices; returns
/// the empty matrix for any other size (documented). O(1).
pub fn eigenvectors(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n != 2 { return out; }
  if ac[0].len() != 2 { return out; }
  var tr = ac[0][0] + ac[1][1];
  var de = ac[0][0] * ac[1][1] - ac[0][1] * ac[1][0];
  var disc = tr * tr - 4.0 * de;
  if disc < 0.0 { return out; }
  var sq = math.sqrt(disc);
  var l1 = (tr + sq) * 0.5;
  var l2 = (tr - sq) * 0.5;
  var v1 = _eigvec_2x2(ac[0][0], ac[0][1], ac[1][0], ac[1][1], l1);
  var v2 = _eigvec_2x2(ac[0][0], ac[0][1], ac[1][0], ac[1][1], l2);
  out.push(v1);
  out.push(v2);
  return out;
}

// Unit eigenvector of a 2x2 matrix (given by its four components) for
// eigenvalue lam, or the empty vector when the system is degenerate. O(1).
fn _eigvec_2x2(a11: Float64, a12: Float64, a21: Float64, a22: Float64, lam: Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var x = a12;
  var y = lam - a11;
  if x == 0.0 && y == 0.0 {
    x = lam - a22;
    y = a21;
  }
  if x == 0.0 && y == 0.0 {
    x = 1.0;
    y = 0.0;
  }
  var len = math.sqrt(x * x + y * y);
  out.push(x / len);
  out.push(y / len);
  return out;
}

/// Main diagonal entries of a matrix. Empty vector for a ragged input. O(n).
pub fn diagonal(a: &Vec[Vec[Float64]]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return out; }
  var c = ac[0].len();
  if c < n { n = c; }
  i = 0;
  while i < n {
    out.push(ac[i][i]);
    i = i + 1;
  }
  return out;
}

/// Right-multiply a by the diagonal matrix diag(d): result[i][j] = a[i][j]*d[j].
/// Empty matrix on size mismatch. O(n*m).
pub fn diag_mul(a: &Vec[Vec[Float64]], d: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  if ac.len() == 0 { return out; }
  var c = ac[0].len();
  if d.len() != c { return out; }
  i = 0;
  while i < ac.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < c {
      row.push(ac[i][j] * d[j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Element-wise (Hadamard) product of two same-shape matrices. Empty matrix on
/// shape mismatch. O(n*m).
pub fn hadamard(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var r = ac.len();
  if bc.len() != r { return out; }
  if r == 0 { return out; }
  var c = ac[0].len();
  if bc[0].len() != c { return out; }
  i = 0;
  while i < r {
    var row = Vec[Float64].new();
    var j = 0;
    while j < c {
      row.push(ac[i][j] * bc[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Kronecker product of a (r x c) and b (p x q): an (r*p) x (c*q) matrix.
/// Empty matrix for empty input. O(r*p*c*q).
pub fn kronecker(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var bc = Vec[Vec[Float64]].new();
  i = 0;
  while i < b.len() {
    bc.push(b[i]);
    i = i + 1;
  }
  var r = ac.len();
  if r == 0 || bc.len() == 0 { return out; }
  var c = ac[0].len();
  var q = bc[0].len();
  i = 0;
  while i < r {
    var k = 0;
    while k < bc.len() {
      var row = Vec[Float64].new();
      var j = 0;
      while j < c {
        var p2 = 0;
        while p2 < q {
          row.push(ac[i][j] * bc[k][p2]);
          p2 = p2 + 1;
        }
        j = j + 1;
      }
      out.push(row);
      k = k + 1;
    }
    i = i + 1;
  }
  return out;
}

/// LU factorization of a square matrix (Doolittle, no pivoting): (L, U) with
/// L unit lower triangular and A = L*U. Returns empty matrices on failure
/// (non-square or zero pivot). O(n^3).
pub fn lu_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]]) {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  var empty_l = Vec[Vec[Float64]].new();
  var empty_u = Vec[Vec[Float64]].new();
  if n == 0 { return (empty_l, empty_u); }
  if ac[0].len() != n { return (empty_l, empty_u); }
  var l = Vec[Vec[Float64]].new();
  var u = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var lrow = Vec[Float64].new();
    var urow = Vec[Float64].new();
    var j = 0;
    while j < n {
      lrow.push(0.0);
      urow.push(0.0);
      j = j + 1;
    }
    l.push(lrow);
    u.push(urow);
    i = i + 1;
  }
  i = 0;
  while i < n {
    l[i][i] = 1.0;
    var j = i;
    while j < n {
      var s = ac[i][j];
      var k = 0;
      while k < i {
        s = s - l[i][k] * u[k][j];
        k = k + 1;
      }
      u[i][j] = s;
      j = j + 1;
    }
    var j2 = i + 1;
    while j2 < n {
      var s2 = ac[j2][i];
      var k2 = 0;
      while k2 < i {
        s2 = s2 - l[j2][k2] * u[k2][i];
        k2 = k2 + 1;
      }
      if math.abs_float(u[i][i]) < 0.000000000001 {
        return (empty_l, empty_u);
      }
      l[j2][i] = s2 / u[i][i];
      j2 = j2 + 1;
    }
    i = i + 1;
  }
  return (l, u);
}

/// QR factorization of a square matrix via Gram-Schmidt on the columns:
/// (Q, R) with Q orthogonal and A = Q*R. Empty matrices on failure. O(n^3).
pub fn qr_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Vec[Float64]]) {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  var empty_q = Vec[Vec[Float64]].new();
  var empty_r = Vec[Vec[Float64]].new();
  if n == 0 { return (empty_q, empty_r); }
  if ac[0].len() != n { return (empty_q, empty_r); }
  var q = Vec[Vec[Float64]].new();
  var r = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var qrow = Vec[Float64].new();
    var rrow = Vec[Float64].new();
    var j = 0;
    while j < n {
      qrow.push(0.0);
      rrow.push(0.0);
      j = j + 1;
    }
    q.push(qrow);
    r.push(rrow);
    i = i + 1;
  }
  var cols = Vec[Vec[Float64]].new();
  var j = 0;
  while j < n {
    var col = Vec[Float64].new();
    var i2 = 0;
    while i2 < n {
      col.push(ac[i2][j]);
      i2 = i2 + 1;
    }
    cols.push(col);
    j = j + 1;
  }
  var orth = Vec[Vec[Float64]].new();
  var k = 0;
  while k < n {
    var v = Vec[Float64].new();
    var i2 = 0;
    while i2 < n {
      v.push(cols[k][i2]);
      i2 = i2 + 1;
    }
    var t = 0;
    while t < k {
      var dot_r = 0.0;
      var i3 = 0;
      while i3 < n {
        dot_r = dot_r + cols[k][i3] * orth[t][i3];
        i3 = i3 + 1;
      }
      r[t][k] = dot_r;
      var i4 = 0;
      while i4 < n {
        v[i4] = v[i4] - dot_r * orth[t][i4];
        i4 = i4 + 1;
      }
      t = t + 1;
    }
    var len = 0.0;
    var i5 = 0;
    while i5 < n {
      len = len + v[i5] * v[i5];
      i5 = i5 + 1;
    }
    len = math.sqrt(len);
    if len < 0.000000000001 {
      return (empty_q, empty_r);
    }
    r[k][k] = len;
    var inv = 1.0 / len;
    var i6 = 0;
    while i6 < n {
      v[i6] = v[i6] * inv;
      i6 = i6 + 1;
    }
    orth.push(v);
    k = k + 1;
  }
  var jj = 0;
  while jj < n {
    var i7 = 0;
    while i7 < n {
      q[i7][jj] = orth[jj][i7];
      i7 = i7 + 1;
    }
    jj = jj + 1;
  }
  return (q, r);
}

/// SVD of a 2x2 symmetric matrix (U, s, V) via its eigendecomposition with
/// s holding the eigenvalues in descending order. Empty values for any other
/// input (documented). O(1).
pub fn svd_decompose(a: &Vec[Vec[Float64]]) -> (Vec[Vec[Float64]], Vec[Float64], Vec[Vec[Float64]]) {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var empty_u = Vec[Vec[Float64]].new();
  var empty_s = Vec[Float64].new();
  var empty_v = Vec[Vec[Float64]].new();
  var n = ac.len();
  if n != 2 { return (empty_u, empty_s, empty_v); }
  if ac[0].len() != 2 { return (empty_u, empty_s, empty_v); }
  var tr = ac[0][0] + ac[1][1];
  var de = ac[0][0] * ac[1][1] - ac[0][1] * ac[1][0];
  var disc = tr * tr - 4.0 * de;
  if disc < 0.0 { return (empty_u, empty_s, empty_v); }
  var sq = math.sqrt(disc);
  var l1 = (tr + sq) * 0.5;
  var l2 = (tr - sq) * 0.5;
  var v1 = _eigvec_2x2(ac[0][0], ac[0][1], ac[1][0], ac[1][1], l1);
  var v2 = _eigvec_2x2(ac[0][0], ac[0][1], ac[1][0], ac[1][1], l2);
  var s = Vec[Float64].new();
  s.push(l1);
  s.push(l2);
  var u = Vec[Vec[Float64]].new();
  u.push(v1);
  u.push(v2);
  return (u, s, u);
}

/// Cholesky factor L (lower triangular) of a symmetric positive definite
/// matrix such that A = L*L^T. None when not SPD or non-square. O(n^3).
pub fn cholesky(a: &Vec[Vec[Float64]]) -> Option[Vec[Vec[Float64]]] {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n == 0 { return None; }
  if ac[0].len() != n { return None; }
  var l = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(0.0);
      j = j + 1;
    }
    l.push(row);
    i = i + 1;
  }
  i = 0;
  while i < n {
    var j = 0;
    while j <= i {
      var s = ac[i][j];
      var k = 0;
      while k < j {
        s = s - l[i][k] * l[j][k];
        k = k + 1;
      }
      if i == j {
        if s <= 0.0 { return None; }
        l[i][j] = math.sqrt(s);
      } else {
        if math.abs_float(l[j][j]) < 0.000000000001 { return None; }
        l[i][j] = s / l[j][j];
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return Some(l);
}

/// Solve the square linear system A*x = b via Gauss-Jordan elimination with
/// partial pivoting. Returns the empty vector when A is singular or the shapes
/// do not match. O(n^3).
pub fn solve_linear(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var sc = Vec[Vec[Float64]].new();
  var ci = 0;
  while ci < a.len() {
    sc.push(a[ci]);
    ci = ci + 1;
  }
  var ac = Vec[Vec[Float64]].new();
  ci = 0;
  while ci < sc.len() {
    var rowv = Vec[Float64].new();
    var cj = 0;
    while cj < sc[ci].len() {
      rowv.push(sc[ci][cj]);
      cj = cj + 1;
    }
    ac.push(rowv);
    ci = ci + 1;
  }
  var n = ac.len();
  if n == 0 { return out; }
  if ac[0].len() != n { return out; }
  if b.len() != n { return out; }
  var aug = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(ac[i][j]);
      j = j + 1;
    }
    row.push(b[i]);
    aug.push(row);
    i = i + 1;
  }
  var k = 0;
  while k < n {
    var p = k;
    var pk = math.abs_float(aug[k][k]);
    var t = k + 1;
    while t < n {
      var av = math.abs_float(aug[t][k]);
      if av > pk { pk = av; p = t; }
      t = t + 1;
    }
    if pk < 0.000000000001 {
      return out;
    }
    if p != k {
      var jj = 0;
      while jj < 2 * n {
        var tv = aug[p][jj];
        aug[p][jj] = aug[k][jj];
        aug[k][jj] = tv;
        jj = jj + 1;
      }
    }
    var piv = aug[k][k];
    var j = 0;
    while j < n + 1 {
      aug[k][j] = aug[k][j] / piv;
      j = j + 1;
    }
    var r = 0;
    while r < n {
      if r != k {
        var f = aug[r][k];
        if f != 0.0 {
          var jj = 0;
          while jj < n + 1 {
            aug[r][jj] = aug[r][jj] - f * aug[k][jj];
            jj = jj + 1;
          }
        }
      }
      r = r + 1;
    }
    k = k + 1;
  }
  i = 0;
  while i < n {
    out.push(aug[i][n]);
    i = i + 1;
  }
  return out;
}

/// Least-squares solution of the overdetermined system A*x = b via the normal
/// equations A^T*A*x = A^T*b. Returns the empty vector on shape mismatch or a
/// singular normal matrix. O(m*n^2 + n^3).
pub fn least_squares(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var m = ac.len();
  if m == 0 || b.len() != m { return out; }
  var n = ac[0].len();
  if n == 0 { return out; }
  var ata = Vec[Vec[Float64]].new();
  var atb = Vec[Float64].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      var s = 0.0;
      var k = 0;
      while k < m {
        s = s + ac[k][i] * ac[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    ata.push(row);
    var rhs = 0.0;
    var k2 = 0;
    while k2 < m {
      rhs = rhs + ac[k2][i] * b[k2];
      k2 = k2 + 1;
    }
    atb.push(rhs);
    i = i + 1;
  }
  return solve_linear(&ata, &atb);
}

/// Condition number of a 2x2 matrix: the ratio of the largest to the smallest
/// singular value (singular values of A^T*A square-rooted). Returns NaN for
/// non-2x2 input or a singular matrix (documented). O(1).
pub fn condition_number(a: &Vec[Vec[Float64]]) -> Float64 {
  var ac = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    ac.push(a[i]);
    i = i + 1;
  }
  var n = ac.len();
  if n != 2 { return 0.0 / 0.0; }
  if ac[0].len() != 2 { return 0.0 / 0.0; }
  var a11 = ac[0][0] * ac[0][0] + ac[1][0] * ac[1][0];
  var a12 = ac[0][0] * ac[0][1] + ac[1][0] * ac[1][1];
  var a22 = ac[0][1] * ac[0][1] + ac[1][1] * ac[1][1];
  var tr = a11 + a22;
  var de = a11 * a22 - a12 * a12;
  if de <= 0.0 { return 0.0 / 0.0; }
  var disc = tr * tr - 4.0 * de;
  if disc < 0.0 { disc = 0.0; }
  var sq = math.sqrt(disc);
  var l1 = (tr + sq) * 0.5;
  var l2 = (tr - sq) * 0.5;
  if l2 <= 0.0 { return 0.0 / 0.0; }
  return math.sqrt(l1 / l2);
}
