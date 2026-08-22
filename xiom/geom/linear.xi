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
//
// IMPORTANT (compiler): by-ref nested float Vec element reads (BUG 26 #1) and
// module-returned nested float Vecs (BUG 23 #1) cannot be trusted for element
// access. All reads of `&Vec[Vec[Float64]]` parameters are therefore copied
// into a local Vec[Vec[Float64]] with single-level row copies (sound), all
// working matrices are built with fresh row allocations, and element access
// always uses direct double indexing on those local matrices.
// ============================================================================

use xiom.math;

// Matrix product a * b (rows of a, columns of b). Returns an empty matrix when
// the inner dimensions do not match. O(n^3).
fn _mat_mul(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
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

// Transpose of a. Empty matrix for a ragged input. O(n*m).
fn _mat_transpose(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var r = mc.len();
  if r == 0 { return out; }
  var c = mc[0].len();
  var j = 0;
  while j < c {
    var col = Vec[Float64].new();
    i = 0;
    while i < r {
      col.push(mc[i][j]);
      i = i + 1;
    }
    out.push(col);
    j = j + 1;
  }
  return out;
}

// n x n identity matrix. O(n^2).
fn _mat_identity(n: Int) -> Vec[Vec[Float64]] {
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

// Trace (sum of the main diagonal) of a square matrix. NaN for non-square. O(n).
fn _mat_trace(m: &Vec[Vec[Float64]]) -> Float64 {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return 0.0; }
  if mc[0].len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  i = 0;
  while i < n {
    s = s + mc[i][i];
    i = i + 1;
  }
  return s;
}

// Inverse of a square matrix via Gauss-Jordan elimination with partial
// pivoting. Returns an empty matrix when the matrix is singular. O(n^3).
fn _mat_inverse(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return out; }
  if mc[0].len() != n { return out; }
  var aug = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(mc[i][j]);
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
  return out;
}

// Dot product of two equal-length dynamic vectors. NaN on length mismatch. O(n).
fn _vec_dot(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var n = a.len();
  if b.len() != n { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + a[i] * b[i];
    i = i + 1;
  }
  return s;
}

// Euclidean length of a dynamic vector. O(n).
fn _vec_norm(v: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < v.len() {
    s = s + v[i] * v[i];
    i = i + 1;
  }
  return math.sqrt(s);
}

// Orthonormalise a set of vectors (each row is a vector) via the modified
// Gram-Schmidt process. Linearly dependent vectors collapse to the zero
// vector. O(k^2 * n).
pub fn gram_schmidt(vectors: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var vc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < vectors.len() {
    vc.push(vectors[i]);
    i = i + 1;
  }
  var k = vc.len();
  if k == 0 { return out; }
  var dim = vc[0].len();
  var basis = Vec[Vec[Float64]].new();
  i = 0;
  while i < k {
    var v = Vec[Float64].new();
    var j = 0;
    while j < dim {
      v.push(vc[i][j]);
      j = j + 1;
    }
    var u = 0;
    while u < basis.len() {
      var proj = _vec_dot(&v, &basis[u]);
      var jj = 0;
      while jj < dim {
        v[jj] = v[jj] - proj * basis[u][jj];
        jj = jj + 1;
      }
      u = u + 1;
    }
    var len = _vec_norm(&v);
    if len > 0.0 {
      var jj = 0;
      while jj < dim {
        v[jj] = v[jj] / len;
        jj = jj + 1;
      }
    }
    basis.push(v);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Orthogonalise a set of vectors (each row is a vector) without normalising
// the output. Linearly dependent vectors collapse to the zero vector. O(k^2 * n).
pub fn orthogonalize(vectors: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var vc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < vectors.len() {
    vc.push(vectors[i]);
    i = i + 1;
  }
  var k = vc.len();
  if k == 0 { return out; }
  var dim = vc[0].len();
  var basis = Vec[Vec[Float64]].new();
  i = 0;
  while i < k {
    var v = Vec[Float64].new();
    var j = 0;
    while j < dim {
      v.push(vc[i][j]);
      j = j + 1;
    }
    var u = 0;
    while u < basis.len() {
      var el = _vec_norm(&basis[u]);
      if el == 0.0 {
        u = u + 1;
        continue;
      }
      var inv = 1.0 / el;
      var proj = 0.0;
      var jj = 0;
      while jj < dim {
        proj = proj + v[jj] * (basis[u][jj] * inv);
        jj = jj + 1;
      }
      jj = 0;
      while jj < dim {
        v[jj] = v[jj] - proj * (basis[u][jj] * inv);
        jj = jj + 1;
      }
      u = u + 1;
    }
    basis.push(v);
    out.push(v);
    i = i + 1;
  }
  return out;
}

// Normalise every column of m to unit length. Columns with zero length are
// left as-is. Empty matrix for a ragged input. O(n*m).
pub fn normalize_columns(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var r = mc.len();
  if r == 0 { return out; }
  var c = mc[0].len();
  var j = 0;
  while j < c {
    var col = Vec[Float64].new();
    i = 0;
    while i < r {
      col.push(mc[i][j]);
      i = i + 1;
    }
    var len = _vec_norm(&col);
    if len > 0.0 {
      var inv = 1.0 / len;
      i = 0;
      while i < r {
        col[i] = col[i] * inv;
        i = i + 1;
      }
    }
    out.push(col);
    j = j + 1;
  }
  return _mat_transpose(&out);
}

// Normalise every row of m to unit length. Rows with zero length are left
// as-is. Empty matrix for a ragged input. O(n*m).
pub fn normalize_rows(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  i = 0;
  while i < mc.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < mc[i].len() {
      row.push(mc[i][j]);
      j = j + 1;
    }
    var len = _vec_norm(&row);
    if len > 0.0 {
      var inv = 1.0 / len;
      j = 0;
      while j < row.len() {
        row[j] = row[j] * inv;
        j = j + 1;
      }
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// True iff m is orthogonal: m * m^T is the identity (within 1e-9). Empty or
// non-square matrices are false. O(n^3).
pub fn is_orthogonal(m: &Vec[Vec[Float64]]) -> Bool {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return false; }
  if mc[0].len() != n { return false; }
  var t = _mat_transpose(&mc);
  var p = _mat_mul(&mc, &t);
  i = 0;
  while i < n {
    var j = 0;
    while j < n {
      var want = 0.0;
      if i == j { want = 1.0; }
      var pc = Vec[Vec[Float64]].new();
      var i2 = 0;
      while i2 < p.len() {
        pc.push(p[i2]);
        i2 = i2 + 1;
      }
      var d = pc[i][j] - want;
      if d < 0.0 { d = -d; }
      if d > 0.000000001 { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff m equals its transpose (exact component equality). O(n^2).
pub fn is_symmetric(m: &Vec[Vec[Float64]]) -> Bool {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var r = mc.len();
  if r == 0 { return true; }
  var c = mc[0].len();
  i = 0;
  while i < r {
    if mc[i].len() != c { return false; }
    var j = 0;
    while j < c {
      if mc[i][j] != mc[j][i] { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff m equals minus its transpose (exact component equality, diagonal
// must be zero). O(n^2).
pub fn is_skew_symmetric(m: &Vec[Vec[Float64]]) -> Bool {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var r = mc.len();
  if r == 0 { return true; }
  var c = mc[0].len();
  i = 0;
  while i < r {
    if mc[i].len() != c { return false; }
    var j = 0;
    while j < c {
      if mc[i][j] != -(mc[j][i]) { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff m is symmetric positive definite: symmetric and every leading
// principal minor is positive (checked via a Cholesky-style sweep). O(n^2).
pub fn is_positive_definite(m: &Vec[Vec[Float64]]) -> Bool {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return false; }
  if mc[0].len() != n { return false; }
  i = 0;
  while i < n {
    var j = 0;
    while j < n {
      if mc[i][j] != mc[j][i] { return false; }
      j = j + 1;
    }
    i = i + 1;
  }
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
      var s = mc[i][j];
      var k = 0;
      while k < j {
        s = s - l[i][k] * l[j][k];
        k = k + 1;
      }
      if i == j {
        if s <= 0.0 { return false; }
        l[i][j] = math.sqrt(s);
      } else {
        l[i][j] = s / l[j][j];
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return true;
}

// True iff m is diagonally dominant: |m[i][i]| >= sum of the absolute values
// of the off-diagonal entries in the same row, for every row. O(n^2).
pub fn is_diagonal_dominant(m: &Vec[Vec[Float64]]) -> Bool {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return true; }
  if mc[0].len() != n { return false; }
  i = 0;
  while i < n {
    var s = 0.0;
    var j = 0;
    while j < n {
      if i != j {
        var v = mc[i][j];
        if v < 0.0 { v = -v; }
        s = s + v;
      }
      j = j + 1;
    }
    var d = mc[i][i];
    if d < 0.0 { d = -d; }
    if d < s { return false; }
    i = i + 1;
  }
  return true;
}

// Matrix exponential of m via the Taylor series exp(M) = sum M^k / k!,
// iterated until the added term is negligible (or 60 terms). Empty matrix on
// non-square input. O(n^3 * terms).
pub fn matrix_exponential(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != n { return Vec[Vec[Float64]].new(); }
  var result = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    result.push(row);
    i = i + 1;
  }
  var term = result;
  var k = 1;
  while k <= 60 {
    var inv = 1.0 / k;
    var nt = _mat_mul(&mc, &term);
    term = nt;
    var tc = Vec[Vec[Float64]].new();
    var t2 = 0;
    while t2 < term.len() {
      tc.push(term[t2]);
      t2 = t2 + 1;
    }
    i = 0;
    while i < n {
      var j = 0;
      while j < n {
        result[i][j] = result[i][j] + tc[i][j] * inv;
        j = j + 1;
      }
      i = i + 1;
    }
    var max_el = 0.0;
    i = 0;
    while i < n {
      var j = 0;
      while j < n {
        var av = tc[i][j];
        if av < 0.0 { av = -av; }
        if av > max_el { max_el = av; }
        j = j + 1;
      }
      i = i + 1;
    }
    if max_el < 0.000000000001 {
      return result;
    }
    k = k + 1;
  }
  return result;
}

// Principal matrix logarithm of m via the series log(M) = sum (-1)^(k+1) (M-I)^k / k,
// which converges when M is close to the identity. Returns the zero matrix for
// the identity and an empty matrix for non-square input. O(n^3 * terms).
pub fn matrix_logarithm(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != n { return Vec[Vec[Float64]].new(); }
  var a = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      var want = 0.0;
      if i == j { want = 1.0; }
      row.push(mc[i][j] - want);
      j = j + 1;
    }
    a.push(row);
    i = i + 1;
  }
  var result = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(0.0);
      j = j + 1;
    }
    result.push(row);
    i = i + 1;
  }
  var term = a;
  var k = 1;
  while k <= 50 {
    var sign = 1.0;
    if (k + 1) % 2 == 0 { sign = -1.0; }
    var inv = sign / k;
    var i2 = 0;
    while i2 < n {
      var j2 = 0;
      while j2 < n {
        result[i2][j2] = result[i2][j2] + term[i2][j2] * inv;
        j2 = j2 + 1;
      }
      i2 = i2 + 1;
    }
    var nt = _mat_mul(&a, &term);
    var tc = Vec[Vec[Float64]].new();
    var t2 = 0;
    while t2 < nt.len() {
      tc.push(nt[t2]);
      t2 = t2 + 1;
    }
    term = tc;
    var max_el = 0.0;
    i2 = 0;
    while i2 < n {
      var j2 = 0;
      while j2 < n {
        var av = term[i2][j2];
        if av < 0.0 { av = -av; }
        if av > max_el { max_el = av; }
        j2 = j2 + 1;
      }
      i2 = i2 + 1;
    }
    if max_el < 0.000000000001 {
      return result;
    }
    k = k + 1;
  }
  return result;
}

// Principal matrix square root of m via Newton iteration
// X_{k+1} = (X_k + M * X_k^-1) / 2 (converges for well-conditioned SPD-like
// inputs). Empty matrix on non-square input. O(n^3 * iterations).
pub fn matrix_sqrt(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != n { return Vec[Vec[Float64]].new(); }
  var x = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    x.push(row);
    i = i + 1;
  }
  var it = 0;
  while it < 40 {
    var inv_x = _mat_inverse(&x);
    if inv_x.len() == 0 {
      return Vec[Vec[Float64]].new();
    }
    var prod = _mat_mul(&mc, &inv_x);
    var pc = Vec[Vec[Float64]].new();
    var p2 = 0;
    while p2 < prod.len() {
      pc.push(prod[p2]);
      p2 = p2 + 1;
    }
    i = 0;
    while i < n {
      var j = 0;
      while j < n {
        x[i][j] = (x[i][j] + pc[i][j]) * 0.5;
        j = j + 1;
      }
      i = i + 1;
    }
    var sq = _mat_mul(&x, &x);
    var sc = Vec[Vec[Float64]].new();
    var s2 = 0;
    while s2 < sq.len() {
      sc.push(sq[s2]);
      s2 = s2 + 1;
    }
    var max_err = 0.0;
    i = 0;
    while i < n {
      var j = 0;
      while j < n {
        var e = sc[i][j] - mc[i][j];
        if e < 0.0 { e = -e; }
        if e > max_err { max_err = e; }
        j = j + 1;
      }
      i = i + 1;
    }
    if max_err < 0.000000001 {
      return x;
    }
    it = it + 1;
  }
  return x;
}

// Integer matrix power m^p. p == 0 yields the identity, p < 0 inverts first,
// and repeated squaring keeps it to O(log |p|) multiplications. Empty matrix
// on non-square or singular input. O(n^3 * log |p|).
pub fn matrix_power(m: &Vec[Vec[Float64]], p: Int) -> Vec[Vec[Float64]] {
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  var n = mc.len();
  if n == 0 { return Vec[Vec[Float64]].new(); }
  if mc[0].len() != n { return Vec[Vec[Float64]].new(); }
  var base = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(mc[i][j]);
      j = j + 1;
    }
    base.push(row);
    i = i + 1;
  }
  if p < 0 {
    var inv = _mat_inverse(&mc);
    if inv.len() == 0 { return Vec[Vec[Float64]].new(); }
    base = inv;
  }
  var result = Vec[Vec[Float64]].new();
  i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j { row.push(1.0); } else { row.push(0.0); }
      j = j + 1;
    }
    result.push(row);
    i = i + 1;
  }
  var e = p;
  if e < 0 { e = -e; }
  while e > 0 {
    if e % 2 == 1 {
      var nr = _mat_mul(&result, &base);
      var rc = Vec[Vec[Float64]].new();
      var r2 = 0;
      while r2 < nr.len() {
        rc.push(nr[r2]);
        r2 = r2 + 1;
      }
      result = rc;
    }
    e = e / 2;
    if e > 0 {
      var nb = _mat_mul(&base, &base);
      var nc = Vec[Vec[Float64]].new();
      var n2 = 0;
      while n2 < nb.len() {
        nc.push(nb[n2]);
        n2 = n2 + 1;
      }
      base = nc;
    }
  }
  return result;
}

// Skew-symmetric matrix [v]_x of a 3-vector v. Empty matrix unless v has
// exactly 3 elements. O(1).
pub fn vec_to_skew(v: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if v.len() != 3 { return out; }
  var r0 = Vec[Float64].new();
  r0.push(0.0);
  r0.push(-(v[2]));
  r0.push(v[1]);
  out.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(v[2]);
  r1.push(0.0);
  r1.push(-(v[0]));
  out.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(-(v[1]));
  r2.push(v[0]);
  r2.push(0.0);
  out.push(r2);
  return out;
}

// The 3-vector v such that vec_to_skew(v) == m, extracted from a skew-symmetric
// matrix. Empty vector unless m is 3x3. O(1).
pub fn skew_to_vec(m: &Vec[Vec[Float64]]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var mc = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m.len() {
    mc.push(m[i]);
    i = i + 1;
  }
  if mc.len() != 3 { return out; }
  if mc[0].len() != 3 { return out; }
  out.push(mc[2][1]);
  out.push(mc[0][2]);
  out.push(mc[1][0]);
  return out;
}
