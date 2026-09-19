// XIOM - Math: Approximation Theory
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.approximation

// Depends on: xiom.math

// ============================================================================
// Function approximation and interpolation: polynomials, rationals, splines,
// and optimal minimax methods.
//
// interpolation delegates to the natural cubic spline in math.numerical
// (DRY); extrapolation, least-squares / rational / Fourier / exponential
// fits, Chebyshev and Pade approximants, the Remez minimax algorithm, and
// spline coefficient extraction are implemented here. All fallible inputs
// are validated in the bodies and return documented sentinels (NaN for
// scalar results, empty vectors for vector results) -- requires/ensures
// clauses are runtime-enforced and would trap. Every linear solve uses
// Gaussian elimination with partial pivoting.
// ============================================================================

use xiom.math;

/// Interpolated value at point through the data (x, y): a natural cubic
/// spline (the default smooth interpolant). Delegates to
/// math.numerical.interp_cubic. Returns NaN for empty, mismatched, or
/// fewer-than-2-points input. Complexity: O(n).
pub fn interpolation(x: &Vec[Float64], y: &Vec[Float64], point: Float64) -> Float64 {
  return math.numerical.interp_cubic(x, y, point);
}

/// Extrapolated value at point outside the sample range [x[0], x[n-1]]: the
/// linear extension of the two nearest end segments. Points inside the range
/// are interpolated (cubic spline). Returns NaN for empty, mismatched, or
/// fewer-than-2-points input. Complexity: O(n).
pub fn extrapolation(x: &Vec[Float64], y: &Vec[Float64], point: Float64) -> Float64 {
  var n = x.len();
  if n < 2 || y.len() != n { return 0.0 / 0.0; }
  if point >= x[0] && point <= x[n - 1] {
    return math.numerical.interp_cubic(x, y, point);
  }
  if point < x[0] {
    return _line_extrap(x[0], y[0], x[1], y[1], point);
  }
  return _line_extrap(x[n - 2], y[n - 2], x[n - 1], y[n - 1], point);
}

/// Least-squares polynomial fit of degree degree through (x, y): solves the
/// (A^T A) c = A^T y normal equations over the Vandermonde basis. Returns
/// the coefficient vector [c0, c1, ..., c_degree] with c0 the constant term;
/// the empty vector for empty/mismatched input or degree < 0 (documented).
/// Complexity: O(n * d^2 + d^3).
pub fn polynomial_approx(x: &Vec[Float64], y: &Vec[Float64], degree: Int) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var n = x.len();
  if n == 0 || y.len() != n || degree < 0 { return empty; }
  var d = degree + 1;
  var at = Vec[Vec[Float64]].new();
  var rhs = Vec[Float64].new();
  var i = 0;
  while i < d {
    var row = Vec[Float64].new();
    var j = 0;
    while j < d {
      var s = 0.0;
      var k = 0;
      while k < n {
        s = s + _vander(x[k], j) * _vander(x[k], i);
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    at.push(row);
    var b = 0.0;
    var k2 = 0;
    while k2 < n {
      b = b + _vander(x[k2], i) * y[k2];
      k2 = k2 + 1;
    }
    rhs.push(b);
    i = i + 1;
  }
  return _solve_square(&at, &rhs);
}

/// Rational approximation (num degree m, den degree n) of the data (x, y) by
/// linearized least squares:
/// y ~= (p0 + p1 x + ... + pm x^m) / (1 + q1 x + ... + qn x^n).
/// Returns [p0..pm, q1..qn] (the leading denominator coefficient is fixed at
/// 1); the empty vector for empty/mismatched input or m, n < 0 (documented).
/// Complexity: O(k * (m+n)^2 + (m+n)^3).
pub fn rational_approx(x: &Vec[Float64], y: &Vec[Float64], m: Int, n: Int) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var k = x.len();
  if k == 0 || y.len() != k || m < 0 || n < 0 { return empty; }
  var cols = m + 1 + n;
  var at = Vec[Vec[Float64]].new();
  var rhs = Vec[Float64].new();
  var i = 0;
  while i < cols {
    var row = Vec[Float64].new();
    var j = 0;
    while j < cols {
      var s = 0.0;
      var t = 0;
      while t < k {
        var bi = _basis(x[t], y[t], i, m);
        var bj = _basis(x[t], y[t], j, m);
        s = s + bi * bj;
        t = t + 1;
      }
      row.push(s);
      j = j + 1;
    }
    at.push(row);
    var b = 0.0;
    var t2 = 0;
    while t2 < k {
      b = b + _basis(x[t2], y[t2], i, m) * y[t2];
      t2 = t2 + 1;
    }
    rhs.push(b);
    i = i + 1;
  }
  return _solve_square(&at, &rhs);
}

/// Fourier series coefficients of the sampled data (x, y) with harmonics
/// sine/cosine terms (the sample points are treated as uniformly spaced over
/// one period). Returns [a0, a1..aH, b1..bH] where a0 is the DC term and
/// a_k/b_k the cosine/sine amplitudes; the empty vector for empty/mismatched
/// input or harmonics < 0 (documented). Complexity: O(k * H).
pub fn trigonometric_approx(x: &Vec[Float64], y: &Vec[Float64], harmonics: Int) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var n = x.len();
  if n == 0 || y.len() != n || harmonics < 0 { return empty; }
  var out = Vec[Float64].new();
  var a0 = 0.0;
  var i = 0;
  while i < n {
    a0 = a0 + y[i];
    i = i + 1;
  }
  a0 = a0 / (n as Float64);
  out.push(a0);
  var h = 1;
  while h <= harmonics {
    var a = 0.0;
    var b = 0.0;
    var t = 0;
    while t < n {
      var theta = 2.0 * 3.141592653589793 * (t as Float64) / (n as Float64);
      a = a + y[t] * math.cos((h as Float64) * theta);
      b = b + y[t] * math.sin((h as Float64) * theta);
      t = t + 1;
    }
    out.push(2.0 * a / (n as Float64));
    out.push(2.0 * b / (n as Float64));
    h = h + 1;
  }
  return out;
}

/// Fitted exponential model y ~= a * e^(b x) of the data (x, y) by
/// least squares on the linearized problem ln y = ln a + b x. Returns
/// [a, b]. Non-positive y values are skipped; the empty vector is returned
/// when no valid samples remain or the inputs mismatch (documented).
/// Complexity: O(k).
pub fn exponential_approx(x: &Vec[Float64], y: &Vec[Float64]) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var n = x.len();
  if n == 0 || y.len() != n { return empty; }
  var sx = 0.0;
  var sl = 0.0;
  var sxx = 0.0;
  var sxl = 0.0;
  var count = 0.0;
  var i = 0;
  while i < n {
    if y[i] > 0.0 {
      var l = math.ln(y[i]);
      sx = sx + x[i];
      sl = sl + l;
      sxx = sxx + x[i] * x[i];
      sxl = sxl + x[i] * l;
      count = count + 1.0;
    }
    i = i + 1;
  }
  if count < 2.0 { return empty; }
  var denom = count * sxx - sx * sx;
  var out = Vec[Float64].new();
  if denom == 0.0 {
    out.push(math.exp(sl / count));
    out.push(0.0);
    return out;
  }
  var b = (count * sxl - sx * sl) / denom;
  var a = math.exp((sl - b * sx) / count);
  out.push(a);
  out.push(b);
  return out;
}

/// Chebyshev series coefficients of f on [a, b] up to degree: the
/// Chebyshev-Gauss quadrature c_k = (2/N) sum_i f(c) T_k over the N mapped
/// Chebyshev nodes (c_0 averaged). Returns [c0, c1, ..., c_degree].
/// The empty vector for degree < 0 (documented). Complexity: O(N * degree).
pub fn chebyshev_approx(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if degree < 0 { return out; }
  var n = degree + 1;
  var i = 0;
  while i <= degree {
    var s = 0.0;
    var j = 0;
    while j < n {
      var theta = 3.141592653589793 * ((j as Float64) + 0.5) / (n as Float64);
      var x = 0.5 * (a + b) + 0.5 * (b - a) * math.cos(theta);
      s = s + f(x) * math.cos((i as Float64) * theta);
      j = j + 1;
    }
    var c = 2.0 * s / (n as Float64);
    if i == 0 { c = c * 0.5; }
    out.push(c);
    i = i + 1;
  }
  return out;
}

/// Normal-equation least-squares solution of A x = b: solves (A^T A) x =
/// A^T b by Gaussian elimination. Returns the empty vector for empty or
/// mismatched input (documented). Complexity: O(m * n^2 + n^3).
/// Least-squares solution of A x = b via the normal equations (A^T A x = A^T b).
/// Returns the empty vector for empty/mismatched input, a singular normal
/// matrix, or when the input matrix is read through a `&Vec[Vec[Float64]]`
/// parameter (TODO(compiler): BUG 26 #1 -- by-ref nested float Vec element
/// reads return garbage data pointers; len fields are correct). The matrix
/// case is unimplementable until the compiler fix lands; the early-return
/// paths are verified.
pub fn least_squares(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var m = a.len();
  if m == 0 || b.len() != m { return empty; }
  var n = a[0].len();
  if n == 0 { return empty; }
  var at = Vec[Vec[Float64]].new();
  var rhs = Vec[Float64].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      var s = 0.0;
      var k = 0;
      while k < m {
        s = s + a[k][i] * a[k][j];
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    at.push(row);
    var r = 0.0;
    var k2 = 0;
    while k2 < m {
      r = r + a[k2][i] * b[k2];
      k2 = k2 + 1;
    }
    rhs.push(r);
    i = i + 1;
  }
  return _solve_square(&at, &rhs);
}

/// Minimax polynomial coefficients of degree degree for f on [a, b].
/// Computed by the Remez exchange algorithm (see remez); the returned vector
/// holds power-basis coefficients from the constant term. Complexity:
/// O(iters * degree^3).
pub fn minimax(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] {
  return remez(f, a, b, degree);
}

/// Pade approximant of order (m, n) of f at x0: builds the Taylor
/// coefficients c0..c_{m+n} by central finite differences, then solves the
/// Pade equations for the denominator q1..qn (q0 = 1) and folds the
/// numerators p0..pm. Returns [p0..pm, q1..qn]; the empty vector for
/// m, n < 0 (documented). NOTE: finite-difference Taylor coefficients limit
/// accuracy (h = 1e-3); the approximation is most reliable for modest
/// orders. Complexity: O((m+n) * cost(f)).
pub fn pade_approx(f: fn(Float64) -> Float64, m: Int, n: Int, x0: Float64) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  if m < 0 || n < 0 { return empty; }
  var order = m + n;
  var c = Vec[Float64].new();
  var i = 0;
  while i <= order {
    c.push(_taylor_coeff(f, x0, i));
    i = i + 1;
  }
  var sys = Vec[Vec[Float64]].new();
  var rhs = Vec[Float64].new();
  var r = m + 1;
  while r <= m + n {
    var row = Vec[Float64].new();
    var col = 1;
    while col <= n {
      var idx = r - col;
      var v = 0.0;
      if idx >= 0 && idx <= order { v = c[idx]; }
      row.push(v);
      col = col + 1;
    }
    sys.push(row);
    var rr = 0.0;
    if r <= order { rr = -(c[r]); }
    rhs.push(rr);
    r = r + 1;
  }
  var q = Vec[Float64].new();
  var den = _solve_square(&sys, &rhs);
  if den.len() != n {
    var j = 0;
    while j < n {
      q.push(0.0);
      j = j + 1;
    }
  } else {
    var j = 0;
    while j < n {
      q.push(den[j]);
      j = j + 1;
    }
  }
  var out = Vec[Float64].new();
  var p = 0;
  while p <= m {
    var s = 0.0;
    var t = 0;
    while t <= p {
      var qv = 1.0;
      if t >= 1 { qv = q[t - 1]; }
      s = s + c[p - t] * qv;
      t = t + 1;
    }
    out.push(s);
    p = p + 1;
  }
  var k = 0;
  while k < n {
    out.push(q[k]);
    k = k + 1;
  }
  return out;
}

/// Remez exchange algorithm producing the degree-degree minimax polynomial
/// of f on [a, b]. Iterates reference points (initialised at the Chebyshev
/// nodes) by solving the alternation linear system and exchanging with the
/// largest deviation on a dense grid. Returns power-basis coefficients from
/// the constant term; the empty vector for degree < 0 (documented).
/// Complexity: O(iters * degree^3).
pub fn remez(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  if degree < 0 { return empty; }
  var n = degree + 2;
  var ref_pts = Vec[Float64].new();
  var i = 0;
  while i < n {
    var theta = 3.141592653589793 * ((degree + 1 - i) as Float64 + 0.5) / (n as Float64);
    var t = math.cos(theta);
    ref_pts.push(0.5 * (a + b) + 0.5 * (b - a) * t);
    i = i + 1;
  }
  var iter = 0;
  while iter < 60 {
    // solve f(x_i) = sum c_k x_i^k + (-1)^i e
    var sys = Vec[Vec[Float64]].new();
    var rhs = Vec[Float64].new();
    var r = 0;
    while r < n {
      var row = Vec[Float64].new();
      var col = 0;
      while col <= degree {
        row.push(math.pow(ref_pts[r], col as Float64));
        col = col + 1;
      }
      var sign = 1.0;
      if r % 2 == 1 { sign = -1.0; }
      row.push(sign);
      sys.push(row);
      rhs.push(f(ref_pts[r]));
      r = r + 1;
    }
    var sol = _solve_square(&sys, &rhs);
    if sol.len() != n { return empty; }
    // dense search for max deviation
    var grid = 256;
    var max_dev = 0.0;
    var max_pt = ref_pts[0];
    var g = 0;
    while g <= grid {
      var x = a + (b - a) * (g as Float64) / (grid as Float64);
      var val = _eval_poly(&sol, x) - f(x);
      if val < 0.0 { val = -val; }
      if val > max_dev {
        max_dev = val;
        max_pt = x;
      }
      g = g + 1;
    }
    var e = sol[degree + 1];
    if e < 0.0 { e = -e; }
    if math.abs_float(max_dev - e) < 1e-12 * (1.0 + e) {
      var out = Vec[Float64].new();
      var k = 0;
      while k <= degree {
        out.push(sol[k]);
        k = k + 1;
      }
      return out;
    }
    // exchange max_pt into the reference
    var worst = 0;
    var w = 1;
    while w < n {
      if _abs(ref_pts[w] - max_pt) < _abs(ref_pts[worst] - max_pt) { worst = w; }
      w = w + 1;
    }
    ref_pts[worst] = max_pt;
    iter = iter + 1;
  }
  var sys2 = Vec[Vec[Float64]].new();
  var rhs2 = Vec[Float64].new();
  var r2 = 0;
  while r2 < n {
    var row = Vec[Float64].new();
    var col = 0;
    while col <= degree {
      row.push(math.pow(ref_pts[r2], col as Float64));
      col = col + 1;
    }
    var sign2 = 1.0;
    if r2 % 2 == 1 { sign2 = -1.0; }
    row.push(sign2);
    sys2.push(row);
    rhs2.push(f(ref_pts[r2]));
    r2 = r2 + 1;
  }
  var sol2 = _solve_square(&sys2, &rhs2);
  if sol2.len() != n { return empty; }
  var out2 = Vec[Float64].new();
  var k2 = 0;
  while k2 <= degree {
    out2.push(sol2[k2]);
    k2 = k2 + 1;
  }
  return out2;
}

/// Cubic spline segment coefficients through the data (x, y): for n points
/// the result holds n - 1 rows, each [a, b, c, d] describing
/// p(x) = a + b*t + c*t^2 + d*t^3 with t = x - x_i (natural spline). The
/// empty matrix for fewer than 2 points or mismatched input (documented).
/// Complexity: O(n).
pub fn spline_approx(x: &Vec[Float64], y: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var n = x.len();
  if n < 2 || y.len() != n { return out; }
  var flat = math.numerical.spline_cubic(x, y);
  var segs = n - 1;
  var i = 0;
  while i < segs {
    var row = Vec[Float64].new();
    var j = 0;
    while j < 4 {
      row.push(flat[4 * i + j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

/// Best least-squares coefficients of f in the given basis functions over
/// [a, b]: samples f and the basis on a 64-point uniform grid and solves the
/// normal equations. Returns the coefficient vector; the empty vector for an
/// empty basis (documented). Complexity: O(64 * m^2 + m^3).
/// Least-squares fit of f over [a, b] in the given function basis, via the
/// normal equations sampled at 64 points. Returns the empty vector for an
/// empty basis or when the basis is read through a `&Vec[fn]` parameter
/// (TODO(compiler): BUG 26 #2 -- Vec[fn] element reads return garbage).
pub fn best_approx(f: fn(Float64) -> Float64, basis: &Vec[fn(Float64) -> Float64], a: Float64, b: Float64) -> Vec[Float64] {
  var empty = Vec[Float64].new();
  var m = basis.len();
  if m == 0 { return empty; }
  var n = 64;
  var at = Vec[Vec[Float64]].new();
  var rhs = Vec[Float64].new();
  var i = 0;
  while i < m {
    var row = Vec[Float64].new();
    var j = 0;
    while j < m {
      var s = 0.0;
      var k = 0;
      while k < n {
        var x = a + (b - a) * (k as Float64) / ((n - 1) as Float64);
        s = s + basis[j](x) * basis[i](x);
        k = k + 1;
      }
      row.push(s);
      j = j + 1;
    }
    at.push(row);
    var r = 0.0;
    var k2 = 0;
    while k2 < n {
      var x2 = a + (b - a) * (k2 as Float64) / ((n - 1) as Float64);
      r = r + basis[i](x2) * f(x2);
      k2 = k2 + 1;
    }
    rhs.push(r);
    i = i + 1;
  }
  return _solve_square(&at, &rhs);
}

// ============================================================================
// Internal helpers
// ============================================================================

// x^k.
fn _vander(x: Float64, k: Int) -> Float64 {
  var r = 1.0;
  var i = 0;
  while i < k {
    r = r * x;
    i = i + 1;
  }
  return r;
}

// Basis column for the rational least-squares problem: columns 0..m are the
// numerator powers x^col; columns m+1..m+n are -y * x^(col - m - 1).
// Basis function of the LINEARIZED rational fit: minimize
// sum_i (P(x_i) - y_i * Q(x_i))^2 over the m+1 numerator and n denominator
// coefficients. Column j <= m is the monomial x^j; column j > m is
// -y_i * x^(j-m-1) (the denominator monomials scaled by the SAMPLE y --
// scaling by x instead would duplicate the numerator basis and make the
// normal matrix singular for m >= n-1).
fn _basis(x: Float64, y: Float64, col: Int, m: Int) -> Float64 {
  if col <= m { return _vander(x, col); }
  return -y * _vander(x, col - m - 1);
}

// Linear extrapolation through (x0, y0), (x1, y1) at x.
fn _line_extrap(x0: Float64, y0: Float64, x1: Float64, y1: Float64, x: Float64) -> Float64 {
  var denom = x1 - x0;
  if denom == 0.0 { return y0; }
  return y0 + (y1 - y0) * (x - x0) / denom;
}

// |x|.
fn _abs(x: Float64) -> Float64 {
  if x < 0.0 { return -x; }
  return x;
}

// Binomial coefficient C(n, k) for the finite-difference stencil weights.
fn _binom(n: Int, k: Int) -> Int {
  if k < 0 || k > n { return 0; }
  var result = 1;
  var i = 1;
  while i <= k {
    result = result * (n - i + 1) / i;
    i = i + 1;
  }
  return result;
}

// Evaluate the polynomial with coefficients (constant first) at x.
fn _eval_poly(c: &Vec[Float64], x: Float64) -> Float64 {
  var s = 0.0;
  var i = c.len();
  while i > 0 {
    s = s * x + c[i - 1];
    i = i - 1;
  }
  return s;
}

// Central finite-difference approximation of the k-th derivative of f at x0
// (used for Pade Taylor coefficients; h = 1e-2 for stability).
fn _taylor_coeff(f: fn(Float64) -> Float64, x0: Float64, k: Int) -> Float64 {
  if k == 0 { return f(x0); }
  var h = 1e-2;
  var sum = 0.0;
  var i = 0;
  while i <= k {
    var sign = 1.0;
    if (k - i) % 2 == 1 { sign = -1.0; }
    var x = x0 + ((k - 2 * i) as Float64) * h;
    sum = sum + sign * (_binom(k, i) as Float64) * f(x);
    i = i + 1;
  }
  var denom = math.pow(2.0 * h, k as Float64);
  return sum / denom;
}

// Solve the square system A x = b by Gaussian elimination with partial
// pivoting. Returns the empty vector for singular or non-square input.
fn _solve_square(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {
  var n = b.len();
  var out = Vec[Float64].new();
  if a.len() != n { return out; }
  var aug = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var row = Vec[Float64].new();
    var j = 0;
    while j < n {
      row.push(a[i][j]);
      j = j + 1;
    }
    row.push(b[i]);
    aug.push(row);
    i = i + 1;
  }
  var p = 0;
  while p < n {
    var piv = _abs(aug[p][p]);
    var piv_row = p;
    var r = p + 1;
    while r < n {
      if _abs(aug[r][p]) > piv {
        piv = _abs(aug[r][p]);
        piv_row = r;
      }
      r = r + 1;
    }
    if piv < 1e-300 { return out; }
    if piv_row != p {
      var c = 0;
      while c <= n {
        var tmp = aug[p][c];
        aug[p][c] = aug[piv_row][c];
        aug[piv_row][c] = tmp;
        c = c + 1;
      }
    }
    var inv_piv = 1.0 / aug[p][p];
    var c2 = 0;
    while c2 <= n {
      aug[p][c2] = aug[p][c2] * inv_piv;
      c2 = c2 + 1;
    }
    var row2 = 0;
    while row2 < n {
      if row2 != p {
        var factor = aug[row2][p];
        if factor != 0.0 {
          var col = 0;
          while col <= n {
            aug[row2][col] = aug[row2][col] - factor * aug[p][col];
            col = col + 1;
          }
        }
      }
      row2 = row2 + 1;
    }
    p = p + 1;
  }
  var k = 0;
  while k < n {
    out.push(aug[k][n]);
    k = k + 1;
  }
  return out;
}
