// XIOM - Math: Numerical
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.numerical

// Depends on: xiom.math

// ============================================================================
// Root finding, linear solvers, interpolation, quadrature, and optimization
// primitives for numerical computing.
//
// Scalar methods (bisection/newton/secant/falsi/brent/fixed_point/
// steffensen, quadrature, golden/ternary search, interpolation) are
// implemented directly on f64; the multi-variable methods operate on
// Vec[Float64]/Vec[Vec[Float64]] in row-major storage. All fallible inputs
// are validated in the bodies and return documented sentinels (NaN for
// scalar results, empty vectors for vector results) -- requires/ensures are
// runtime-enforced and would trap. Convergence guards cap iteration counts
// on every loop.
// ============================================================================

use xiom.math;

// ============================================================================
// Single-variable root finding
// ============================================================================

// Root of f in [a, b] via bisection on a sign change. When f(a) and f(b)
// share a sign the interval is sampled (64 points) for a sub-bracket; if
// none is found NaN (0.0/0.0) is returned (documented). Convergence to
// interval width tol, at most 200 iterations. Complexity: O(log((b-a)/tol)).
pub fn bisection(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  var lo = a;
  var hi = b;
  var f_lo = f(lo);
  var f_hi = f(hi);
  if f_lo == 0.0 { return lo; }
  if f_hi == 0.0 { return hi; }
  if f_lo * f_hi > 0.0 {
    var found = false;
    var k = 0;
    while k < 64 {
      var x = lo + (hi - lo) * ((k as Float64) / 64.0);
      var fx = f(x);
      if fx == 0.0 { return x; }
      if f_lo * fx < 0.0 {
        hi = x;
        f_hi = fx;
        found = true;
        k = 64;
      }
      k = k + 1;
    }
    if !found { return 0.0 / 0.0; }
  }
  var iter = 0;
  while iter < 200 {
    var mid = 0.5 * (lo + hi);
    var f_mid = f(mid);
    if math.abs_float(hi - lo) < tol { return mid; }
    if f_mid == 0.0 { return mid; }
    if f_lo * f_mid < 0.0 {
      hi = mid;
      f_hi = f_mid;
    } else {
      lo = mid;
      f_lo = f_mid;
    }
    iter = iter + 1;
  }
  return 0.5 * (lo + hi);
}

// Root of f via Newton's method from x0: x <- x - f(x)/f'(x). Returns x0
// when the derivative vanishes (documented), at most 200 iterations.
// Complexity: O(200 * cost(f + f')).
pub fn newton(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {
  var x = x0;
  var i = 0;
  while i < 200 {
    var fx = f(x);
    if math.abs_float(fx) < tol { return x; }
    var fp = fprime(x);
    if fp == 0.0 { return x; }
    var step = fx / fp;
    x = x - step;
    if math.abs_float(step) < tol { return x; }
    i = i + 1;
  }
  return x;
}

// Root of f via the secant method from x0, x1. Returns x1 when f(x1) ==
// f(x0) (documented, division by zero guard), at most 200 iterations.
// Complexity: O(200 * cost(f)).
pub fn secant(f: fn(Float64) -> Float64, x0: Float64, x1: Float64, tol: Float64) -> Float64 {
  var a = x0;
  var b = x1;
  var f_a = f(a);
  var f_b = f(b);
  var i = 0;
  while i < 200 {
    if math.abs_float(f_b) < tol { return b; }
    var denom = f_b - f_a;
    if denom == 0.0 { return b; }
    var c = b - f_b * (b - a) / denom;
    a = b;
    f_a = f_b;
    b = c;
    f_b = f(b);
    if math.abs_float(b - a) < tol { return b; }
    i = i + 1;
  }
  return b;
}

// Root of f in [a, b] via regula falsi (false position) with the Illinois
// anti-stalling adjustment. Returns NaN when no sign change exists in
// [a, b] (documented), at most 200 iterations. Complexity: O(200 * cost(f)).
pub fn falsi(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  var lo = a;
  var hi = b;
  var f_lo = f(lo);
  var f_hi = f(hi);
  if f_lo == 0.0 { return lo; }
  if f_hi == 0.0 { return hi; }
  if f_lo * f_hi > 0.0 { return 0.0 / 0.0; }
  var prev_c = lo;
  var i = 0;
  while i < 200 {
    var denom = f_hi - f_lo;
    if denom == 0.0 { return lo; }
    var c = lo - f_lo * (hi - lo) / denom;
    var f_c = f(c);
    if math.abs_float(f_c) < tol { return c; }
    if math.abs_float(hi - lo) < tol { return c; }
    if f_lo * f_c < 0.0 {
      hi = c;
      f_hi = f_c;
      if f_hi * f_lo > 0.0 { f_lo = f_lo * 0.5; }
    } else {
      lo = c;
      f_lo = f_c;
      if f_hi * f_lo > 0.0 { f_hi = f_hi * 0.5; }
    }
    prev_c = c;
    i = i + 1;
  }
  return prev_c;
}

// Root of f in [a, b] via Brent's method (inverse quadratic interpolation
// with bisection fallback). The most robust of the bracketing methods;
// returns NaN when no sign change exists in [a, b] (documented). At most
// 200 iterations. Complexity: O(200 * cost(f)).
pub fn brent(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  var fa = f(a);
  var fb = f(b);
  if fa == 0.0 { return a; }
  if fb == 0.0 { return b; }
  if fa * fb > 0.0 { return 0.0 / 0.0; }
  var c = a;
  var fc = fa;
  var d = b - a;
  var e = d;
  var i = 0;
  while i < 200 {
    if math.abs_float(fc) < math.abs_float(fb) {
      a = b;
      b = c;
      c = a;
      fa = fb;
      fb = fc;
      fc = fa;
    }
    var tol1 = 2.0 * 2.220446049250313e-16 * math.abs_float(b) + 0.5 * tol;
    var m = 0.5 * (c - b);
    if math.abs_float(m) <= tol1 || fb == 0.0 { return b; }
    if math.abs_float(e) >= tol1 && math.abs_float(fa) > math.abs_float(fb) {
      var s = fb / fa;
      var p = 0.0;
      var q = 0.0;
      if a == c {
        p = 2.0 * m * s;
        q = 1.0 - s;
      } else {
        var q1 = fa / fc;
        var r = fb / fc;
        p = s * (2.0 * m * q1 * (q1 - r) - (b - a) * (r - 1.0));
        q = (q1 - 1.0) * (r - 1.0) * (s - 1.0);
      }
      if p > 0.0 { q = -q; }
      p = math.abs_float(p);
      var min1 = 3.0 * m * q - math.abs_float(tol1 * q);
      var min2 = math.abs_float(e * q);
      if 2.0 * p < min1 && 2.0 * p < min2 {
        e = d;
        d = p / q;
      } else {
        d = m;
        e = m;
      }
    } else {
      d = m;
      e = m;
    }
    a = b;
    fa = fb;
    if math.abs_float(d) > tol1 {
      b = b + d;
    } else {
      if m > 0.0 { b = b + tol1; } else { b = b - tol1; }
    }
    fb = f(b);
    if (fb > 0.0 && fc > 0.0) || (fb < 0.0 && fc < 0.0) {
      c = a;
      fc = fa;
      d = b - a;
      e = d;
    }
    i = i + 1;
  }
  return b;
}

// Fixed point of g by iteration x <- g(x) from x0. Convergence when
// |g(x) - x| < tol; at most 1000 iterations. Complexity: O(1000 * cost(g)).
pub fn fixed_point(g: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {
  var x = x0;
  var i = 0;
  while i < 1000 {
    var nx = g(x);
    if math.abs_float(nx - x) < tol { return nx; }
    x = nx;
    i = i + 1;
  }
  return x;
}

// Root of f via Steffensen's accelerated iteration, which achieves
// quadratic convergence without derivatives:
// x <- x - f(x)^2 / (f(x + f(x)) - f(x)). Returns x when the denominator
// vanishes (documented), at most 200 iterations.
// Complexity: O(200 * cost(f)).
pub fn steffensen(f: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {
  var x = x0;
  var i = 0;
  while i < 200 {
    var fx = f(x);
    if math.abs_float(fx) < tol { return x; }
    var denom = f(x + fx) - fx;
    if denom == 0.0 { return x; }
    var step = (fx * fx) / denom;
    x = x - step;
    if math.abs_float(step) < tol { return x; }
    i = i + 1;
  }
  return x;
}

// ============================================================================
// Multi-variable nonlinear systems
// ============================================================================

// Root of the nonlinear system fs(x) = 0 via Newton's method with the
// Jacobian supplied by jac. Solves J * d = -f by Gaussian elimination each
// iteration; converges to norm(d) < tol (at most 100 iterations). Returns
// the last iterate. Complexity: O(iters * n^3).
pub fn newton_multi(fs: &Vec[fn(&Vec[Float64]) -> Float64], jac: fn(&Vec[Float64]) -> Vec[Vec[Float64]],
                    x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var i = 0;
  while i < 100 {
    var f = eval_fs(fs, &x);
    var jm = jac(&x);
    var rhs = neg_vec(&f);
    var d = _solve_linear(&jm, &rhs);
    if d.len() == 0 { return x; }
    var upd = 0.0;
    var k = 0;
    while k < n {
      x[k] = x[k] + d[k];
      k = k + 1;
    }
    upd = vec_max_abs(&d);
    if upd < tol { return x; }
    i = i + 1;
  }
  return x;
}

// Multi-variable Newton-Raphson root of the system fs(x) = 0. Alias of
// newton_multi. Complexity: O(iters * n^3).
pub fn newton_raphson_multi(fs: &Vec[fn(&Vec[Float64]) -> Float64], jac: fn(&Vec[Float64]) -> Vec[Vec[Float64]],
                            x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  return newton_multi(fs, jac, x0, tol);
}

// Solve Ax = b by Gauss-Seidel iteration from x0. Requires a non-zero
// diagonal; returns the last iterate (at most 1000 iterations, convergence
// on the sup-norm of the increment). The empty vector is returned for
// empty input. Complexity: O(iters * n^2).
pub fn gauss_seidel(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  if n == 0 { return Vec[Float64].new(); }
  var x = clone_vec(x0);
  var i = 0;
  while i < 1000 {
    var maxd = 0.0;
    var r = 0;
    while r < n {
      var s = 0.0;
      var c = 0;
      while c < n {
        if c != r {
          s = s + a[r][c] * x[c];
        }
        c = c + 1;
      }
      var denom = a[r][r];
      if denom == 0.0 { return x; }
      var nx = (b[r] - s) / denom;
      var diff = nx - x[r];
      if diff < 0.0 { diff = -diff; }
      if diff > maxd { maxd = diff; }
      x[r] = nx;
      r = r + 1;
    }
    if maxd < tol { return x; }
    i = i + 1;
  }
  return x;
}

// Solve Ax = b by Jacobi iteration from x0 (updates use the previous
// iterate). Requires a non-zero diagonal; returns the last iterate.
// Complexity: O(iters * n^2).
pub fn jacobi_iterative(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  if n == 0 { return Vec[Float64].new(); }
  var x = clone_vec(x0);
  var i = 0;
  while i < 1000 {
    var nx = Vec[Float64].new();
    var r = 0;
    while r < n {
      var s = 0.0;
      var c = 0;
      while c < n {
        if c != r {
          s = s + a[r][c] * x[c];
        }
        c = c + 1;
      }
      var denom = a[r][r];
      if denom == 0.0 { return x; }
      nx.push((b[r] - s) / denom);
      r = r + 1;
    }
    var maxd = 0.0;
    var k = 0;
    while k < n {
      var diff = nx[k] - x[k];
      if diff < 0.0 { diff = -diff; }
      if diff > maxd { maxd = diff; }
      k = k + 1;
    }
    x = nx;
    if maxd < tol { return x; }
    i = i + 1;
  }
  return x;
}

// Solve SPD Ax = b by the conjugate gradient method from x0. Requires a
// symmetric positive-definite system; returns the last iterate (at most
// n + 200 iterations). Complexity: O(iters * n^2).
pub fn conjugate_gradient(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  if n == 0 { return Vec[Float64].new(); }
  var x = clone_vec(x0);
  var r = Vec[Float64].new();
  var i = 0;
  while i < n {
    var s = 0.0;
    var c = 0;
    while c < n {
      s = s + a[i][c] * x[c];
      c = c + 1;
    }
    r.push(b[i] - s);
    i = i + 1;
  }
  var p = clone_vec(&r);
  var rho = vec_dot_in(&r, &r);
  var iter = 0;
  while iter < n + 200 {
    if math.sqrt(rho) < tol { return x; }
    var ap = Vec[Float64].new();
    var i2 = 0;
    while i2 < n {
      var s = 0.0;
      var c = 0;
      while c < n {
        s = s + a[i2][c] * p[c];
        c = c + 1;
      }
      ap.push(s);
      i2 = i2 + 1;
    }
    var pap = vec_dot_in(&p, &ap);
    if pap == 0.0 { return x; }
    var alpha = rho / pap;
    var k = 0;
    while k < n {
      x[k] = x[k] + alpha * p[k];
      r[k] = r[k] - alpha * ap[k];
      k = k + 1;
    }
    var rho_new = vec_dot_in(&r, &r);
    if math.sqrt(rho_new) < tol { return x; }
    var beta = rho_new / rho;
    var j = 0;
    while j < n {
      p[j] = r[j] + beta * p[j];
      j = j + 1;
    }
    rho = rho_new;
    iter = iter + 1;
  }
  return x;
}

// Minimize f(x) by gradient descent with learning rate lr from x0.
// Returns the last iterate (at most 10000 steps, stop when |lr * grad| <
// tol). Complexity: O(steps * cost(grad)).
pub fn gradient_descent(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                        x0: &Vec[Float64], lr: Float64, tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var i = 0;
  while i < 10000 {
    var g = grad(&x);
    var maxd = 0.0;
    var k = 0;
    while k < n {
      var step = lr * g[k];
      x[k] = x[k] - step;
      if step < 0.0 { step = -step; }
      if step > maxd { maxd = step; }
      k = k + 1;
    }
    if maxd < tol { return x; }
    i = i + 1;
  }
  return x;
}

// Solve the nonlinear system fs(x) = 0 by Broyden's quasi-Newton method
// (secant update of the inverse-Jacobian estimate, no derivatives needed).
// Returns the last iterate (at most 100 iterations). Complexity:
// O(iters * n^2).
pub fn broyden(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var f = eval_fs(fs, &x);
  var inv_j = mat_identity(n);
  var i = 0;
  while i < 100 {
    if vec_max_abs(&f) < tol { return x; }
    var d = _mat_vec_mul(&inv_j, &f);
    var dneg = neg_vec(&d);
    var step = 1.0;
    var k = 0;
    while k < n {
      x[k] = x[k] + step * dneg[k];
      k = k + 1;
    }
    var f_new = eval_fs(fs, &x);
    var s = neg_vec(&d);
    var y = Vec[Float64].new();
    var j = 0;
    while j < n {
      y.push(f_new[j] - f[j]);
      j = j + 1;
    }
    var sy = vec_dot_in(&s, &y);
    if sy != 0.0 {
      var ys = Vec[Vec[Float64]].new();
      var r = 0;
      while r < n {
        var row = Vec[Float64].new();
        var c = 0;
        while c < n {
          row.push(s[r] * y[c]);
          c = c + 1;
        }
        ys.push(row);
        r = r + 1;
      }
      // invJ <- invJ + ((s - invJ*y) / (y^T s)) * s^T
      var invj_y = _mat_vec_mul(&inv_j, &y);
      var diff = Vec[Float64].new();
      var m = 0;
      while m < n {
        diff.push(s[m] - invj_y[m]);
        m = m + 1;
      }
      var outer = Vec[Vec[Float64]].new();
      var r2 = 0;
      while r2 < n {
        var row2 = Vec[Float64].new();
        var c2 = 0;
        while c2 < n {
          row2.push(diff[r2] * s[c2] / sy);
          c2 = c2 + 1;
        }
        outer.push(row2);
        r2 = r2 + 1;
      }
      inv_j = _mat_add(&inv_j, &outer);
    }
    f = f_new;
    i = i + 1;
  }
  return x;
}

// Anderson-accelerated fixed-point iteration for the system fs(x) = 0
// (fixed-point map x - fs(x)), keeping a history of the last m residuals.
// Returns the last iterate (at most 1000 outer iterations). Complexity:
// O(iters * m * n).
pub fn anderson(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], m: Int, tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var hist = Vec[Vec[Float64]].new();
  var res = Vec[Vec[Float64]].new();
  var i = 0;
  while i < 1000 {
    var f = eval_fs(fs, &x);
    if vec_max_abs(&f) < tol { return x; }
    var gx = Vec[Float64].new();
    var k = 0;
    while k < n {
      gx.push(x[k] - f[k]);
      k = k + 1;
    }
    hist.push(clone_vec(&gx));
    res.push(clone_vec(&f));
    while hist.len() > m {
      hist.remove(0);
      res.remove(0);
    }
    var h = hist.len();
    if h > 1 {
      var best_g = clone_vec(&gx);
      var best_w = 1.0;
      var j = 0;
      while j < h {
        var w = 1.0 / (1.0 + vec_max_abs(&res[j]));
        var cand = Vec[Float64].new();
        var q = 0;
        while q < n {
          cand.push(w * hist[j][q] + (1.0 - w) * gx[q]);
          q = q + 1;
        }
        var cand_res = eval_fs(fs, &cand);
        var cr = vec_max_abs(&cand_res);
        if cr < best_w {
          best_w = cr;
          best_g = cand;
        }
        j = j + 1;
      }
      gx = best_g;
    }
    var maxd = 0.0;
    var q2 = 0;
    while q2 < n {
      var diff = gx[q2] - x[q2];
      if diff < 0.0 { diff = -diff; }
      if diff > maxd { maxd = diff; }
      q2 = q2 + 1;
    }
    x = gx;
    if maxd < tol { return x; }
    i = i + 1;
  }
  return x;
}

// General nonlinear system solver from x0. Broyden requires no Jacobian, so
// it is the natural default; delegates to broyden. Complexity: O(iters*n^2).
pub fn solver_system(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  return broyden(fs, x0, tol);
}

// ============================================================================
// Interpolation
// ============================================================================

// Piecewise linear interpolation of the points (xs, ys) at x. x outside
// [xs[0], xs[n-1]] is clamped to the nearest endpoint (documented).
// Returns NaN for empty or mismatched input. Complexity: O(n).
pub fn interp_linear(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 {
  var n = xs.len();
  if n == 0 || ys.len() != n { return 0.0 / 0.0; }
  if n == 1 { return ys[0]; }
  if x <= xs[0] { return ys[0]; }
  if x >= xs[n - 1] { return ys[n - 1]; }
  var i = 0;
  while i < n - 1 {
    if x >= xs[i] && x <= xs[i + 1] {
      var denom = xs[i + 1] - xs[i];
      if denom == 0.0 { return ys[i]; }
      var t = (x - xs[i]) / denom;
      return ys[i] + (ys[i + 1] - ys[i]) * t;
    }
    i = i + 1;
  }
  return ys[n - 1];
}

// Polynomial interpolation through the points (xs, ys) evaluated at x
// (Lagrange form). Returns NaN for empty, mismatched, or repeated-x input
// (division by zero guard). Complexity: O(n^2).
pub fn interp_polynomial(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 {
  var n = xs.len();
  if n == 0 || ys.len() != n { return 0.0 / 0.0; }
  var result = 0.0;
  var i = 0;
  while i < n {
    var term = ys[i];
    var j = 0;
    while j < n {
      if j != i {
        var denom = xs[i] - xs[j];
        if denom == 0.0 { return 0.0 / 0.0; }
        term = term * (x - xs[j]) / denom;
      }
      j = j + 1;
    }
    result = result + term;
    i = i + 1;
  }
  return result;
}

// Default spline interpolation at x: a natural cubic spline through the
// points (xs, ys). Same semantics as interp_cubic. Returns NaN for empty,
// mismatched, or fewer-than-2-points input. Complexity: O(n) per call after
// an O(n) setup.
pub fn interp_spline(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 {
  return interp_cubic(xs, ys, x);
}

// Natural cubic spline interpolation at x through the points (xs, ys)
// (zero second derivatives at the ends). Returns NaN for empty, mismatched,
// or fewer-than-2-points input. Complexity: O(n) setup + O(n) evaluation.
pub fn interp_cubic(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 {
  var n = xs.len();
  if n < 2 || ys.len() != n { return 0.0 / 0.0; }
  // BUG 24 fix: xs/ys are ALREADY &Vec[Float64] -- `&xs` was a double-address.
  var coeffs = _natural_cubic(xs, ys);
  return _eval_spline(xs, ys, &coeffs, x);
}

// Hermite cubic interpolation at x using derivative values dys. Returns
// NaN for empty, mismatched input, or fewer than 2 points. x outside the
// data range is clamped to the nearest endpoint (documented).
// Complexity: O(n).
pub fn interp_hermite(xs: &Vec[Float64], ys: &Vec[Float64], dys: &Vec[Float64], x: Float64) -> Float64 {
  var n = xs.len();
  if n < 2 || ys.len() != n || dys.len() != n { return 0.0 / 0.0; }
  if x <= xs[0] { return ys[0]; }
  if x >= xs[n - 1] { return ys[n - 1]; }
  var i = 0;
  while i < n - 1 {
    if x >= xs[i] && x <= xs[i + 1] {
      var h = xs[i + 1] - xs[i];
      if h == 0.0 { return ys[i]; }
      var t = (x - xs[i]) / h;
      var t2 = t * t;
      var t3 = t2 * t;
      var h00 = 2.0 * t3 - 3.0 * t2 + 1.0;
      var h10 = t3 - 2.0 * t2 + t;
      var h01 = -2.0 * t3 + 3.0 * t2;
      var h11 = t3 - t2;
      return h00 * ys[i] + h10 * h * dys[i] + h01 * ys[i + 1] + h11 * h * dys[i + 1];
    }
    i = i + 1;
  }
  return ys[n - 1];
}

// ============================================================================
// Spline construction
// ============================================================================

// Build linear spline coefficients: for n points the returned vector holds
// 2 * (n - 1) values, one (slope, intercept) pair per segment (documented
// layout). Returns the empty vector for fewer than 2 points or mismatched
// input. Complexity: O(n).
pub fn spline_linear(xs: &Vec[Float64], ys: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = xs.len();
  if n < 2 || ys.len() != n { return out; }
  var i = 0;
  while i < n - 1 {
    var dx = xs[i + 1] - xs[i];
    if dx == 0.0 {
      out.push(0.0);
      out.push(ys[i]);
    } else {
      var m = (ys[i + 1] - ys[i]) / dx;
      var b = ys[i] - m * xs[i];
      out.push(m);
      out.push(b);
    }
    i = i + 1;
  }
  return out;
}

// Build natural cubic spline coefficients: for n points the returned
// vector holds 4 * (n - 1) values, one (a, b, c, d) tuple per segment with
// p(x) = a + b*(x - x_i) + c*(x - x_i)^2 + d*(x - x_i)^3 (documented
// layout). Returns the empty vector for fewer than 2 points or mismatched
// input. Complexity: O(n).
pub fn spline_cubic(xs: &Vec[Float64], ys: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = xs.len();
  if n < 2 || ys.len() != n { return out; }
  // BUG 24 fix: xs/ys are ALREADY &Vec[Float64] -- `&xs` was a double-address.
  var coeffs = _natural_cubic(xs, ys);
  var i = 0;
  while i < coeffs.len() {
    out.push(coeffs[i]);
    i = i + 1;
  }
  return out;
}

// Build B-spline control points of degree degree interpolating the data
// points ys (uniform knots). For degree 3 the interior control points come
// from the standard tridiagonal system c_(i-1) + 4 c_i + c_(i+1) = 6 y_i;
// for degree 1 the data points are returned as control points; other
// degrees fall back to the degree-3 fit (documented). Returns the empty
// vector for fewer than 2 points. Complexity: O(n) Thomas solve.
pub fn spline_b_spline(xs: &Vec[Float64], ys: &Vec[Float64], degree: Int) -> Vec[Float64] {
  var n = ys.len();
  var out = Vec[Float64].new();
  if n < 2 || xs.len() != n { return out; }
  if degree <= 1 {
    var i = 0;
    while i < n {
      out.push(ys[i]);
      i = i + 1;
    }
    return out;
  }
  // cubic: solve tridiagonal c_{i-1} + 4 c_i + c_{i+1} = 6 y_i
  var lower = Vec[Float64].new();
  var diag = Vec[Float64].new();
  var upper = Vec[Float64].new();
  var rhs = Vec[Float64].new();
  var i = 0;
  while i < n {
    if i == 0 {
      diag.push(1.0);
      rhs.push(ys[0]);
    } else {
      if i == n - 1 {
        diag.push(1.0);
        rhs.push(ys[n - 1]);
      } else {
        lower.push(1.0);
        diag.push(4.0);
        upper.push(1.0);
        rhs.push(6.0 * ys[i]);
      }
    }
    i = i + 1;
  }
  var c = _tridiagonal(&lower, &diag, &upper, &rhs);
  if c.len() != n { return out; }
  var j = 0;
  while j < c.len() {
    out.push(c[j]);
    j = j + 1;
  }
  return out;
}

// Build NURBS control points from ys with the per-point weights: returns
// the homogeneous (weighted) control points w_i * y_i, one per data point
// (documented layout; an evaluator divides through by the weights).
// Returns the empty vector when weights do not match ys or the data is
// empty. Complexity: O(n).
pub fn spline_nurbs(xs: &Vec[Float64], ys: &Vec[Float64], weights: &Vec[Float64], degree: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = ys.len();
  if n == 0 || xs.len() != n || weights.len() != n { return out; }
  var i = 0;
  while i < n {
    out.push(weights[i] * ys[i]);
    i = i + 1;
  }
  return out;
}

// ============================================================================
// Quadrature
// ============================================================================

// Composite trapezoidal rule for the integral of f over [a, b] with n
// subintervals. Returns 0.0 for n <= 0 (documented). Complexity: O(n).
pub fn quadrature_trapezoid(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var h = (b - a) / (n as Float64);
  var s = 0.5 * (f(a) + f(b));
  var i = 1;
  while i < n {
    s = s + f(a + h * (i as Float64));
    i = i + 1;
  }
  return s * h;
}

// Composite Simpson's rule for the integral of f over [a, b] with n
// subintervals (n is clamped up to an even count; returns 0.0 for n <= 0).
// Complexity: O(n).
pub fn quadrature_simpson(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var m = n;
  if m % 2 == 1 { m = m + 1; }
  var h = (b - a) / (m as Float64);
  var s = f(a) + f(b);
  var i = 1;
  while i < m {
    if i % 2 == 1 {
      s = s + 4.0 * f(a + h * (i as Float64));
    } else {
      s = s + 2.0 * f(a + h * (i as Float64));
    }
    i = i + 1;
  }
  return s * h / 3.0;
}

// n-point Gauss-Legendre quadrature over [a, b]. Nodes/weights are computed
// on the fly by Newton iteration on the Legendre polynomial (valid for any
// n >= 1); returns 0.0 for n <= 0 (documented). Exact for polynomials of
// degree <= 2n - 1. Complexity: O(n^2).
pub fn quadrature_gauss(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var nodes = _legendre_nodes(n);
  var s = 0.0;
  var i = 0;
  while i < n {
    var x = 0.5 * (b - a) * nodes[2 * i] + 0.5 * (a + b);
    s = s + nodes[2 * i + 1] * f(x);
    i = i + 1;
  }
  return s * 0.5 * (b - a);
}

// Adaptive quadrature to absolute tolerance tol via recursive Simpson
// refinement (a global error bookkeeping loop, at most 32 levels deep).
// Returns NaN for tol <= 0 (documented). Complexity: O(refinements * cost(f)).
pub fn quadrature_adaptive(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  if tol <= 0.0 { return 0.0 / 0.0; }
  var whole = _simp(f, a, b);
  var left = _simp(f, a, 0.5 * (a + b));
  var right = _simp(f, 0.5 * (a + b), b);
  return _adapt(f, a, b, whole, left, right, tol, 0);
}

// Monte Carlo quadrature of f over [a, b] with n samples using the seeded
// xiom RNG (math.random). Returns 0.0 for n <= 0 (documented). Error ~
// O(sigma / sqrt(n)). Complexity: O(n).
pub fn quadrature_monte_carlo(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    var x = a + (b - a) * math.random();
    s = s + f(x);
    i = i + 1;
  }
  return (b - a) * s / (n as Float64);
}

// ============================================================================
// Univariate optimization
// ============================================================================

// Minimize the univariate f over [a, b] by golden-section search to width
// tol. Returns the minimizing x (at most 200 iterations). Complexity:
// O(200 * cost(f)).
pub fn optimize_golden(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  var phi_inv = 0.6180339887498949;
  var lo = a;
  var hi = b;
  var x1 = lo + (1.0 - phi_inv) * (hi - lo);
  var x2 = lo + phi_inv * (hi - lo);
  var f1 = f(x1);
  var f2 = f(x2);
  var i = 0;
  while i < 200 {
    if hi - lo < tol { return 0.5 * (lo + hi); }
    if f1 < f2 {
      hi = x2;
      x2 = x1;
      f2 = f1;
      x1 = lo + (1.0 - phi_inv) * (hi - lo);
      f1 = f(x1);
    } else {
      lo = x1;
      x1 = x2;
      f1 = f2;
      x2 = lo + phi_inv * (hi - lo);
      f2 = f(x2);
    }
    i = i + 1;
  }
  return 0.5 * (lo + hi);
}

// Minimize the univariate f over [a, b] by ternary search to width tol.
// Returns the minimizing x (at most 200 iterations). Complexity:
// O(200 * cost(f)).
pub fn optimize_ternary(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  var lo = a;
  var hi = b;
  var i = 0;
  while i < 200 {
    if hi - lo < tol { return 0.5 * (lo + hi); }
    var m1 = lo + (hi - lo) / 3.0;
    var m2 = hi - (hi - lo) / 3.0;
    if f(m1) < f(m2) {
      hi = m2;
    } else {
      lo = m1;
    }
    i = i + 1;
  }
  return 0.5 * (lo + hi);
}

// ============================================================================
// Multi-variable optimization
// ============================================================================

// Minimize f by the BFGS quasi-Newton method from x0 (approximate inverse
// Hessian updated by the secant formula; line search = fixed step 1).
// Returns the last iterate (at most 200 iterations). Complexity:
// O(iters * n^2).
pub fn optimize_bfgs(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                     x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var h = mat_identity(n);
  var g = grad(&x);
  var i = 0;
  while i < 200 {
    if vec_max_abs(&g) < tol { return x; }
    var d = neg_vec(&_mat_vec_mul(&h, &g));
    var alpha = _line_search(f, grad, &x, &d);
    var x_new = Vec[Float64].new();
    var k = 0;
    while k < n {
      x_new.push(x[k] + alpha * d[k]);
      k = k + 1;
    }
    var g_new = grad(&x_new);
    var s = Vec[Float64].new();
    var y = Vec[Float64].new();
    var j = 0;
    while j < n {
      s.push(x_new[j] - x[j]);
      y.push(g_new[j] - g[j]);
      j = j + 1;
    }
    var sy = vec_dot_in(&s, &y);
    if sy != 0.0 {
      var hy = _mat_vec_mul(&h, &y);
      var rho = 1.0 / sy;
      var h_new = _mat_identity_like(&h);
      var r = 0;
      while r < n {
        var c = 0;
        while c < n {
          var v = h[r][c];
          v = v - rho * (s[r] * hy[c] + hy[r] * s[c]);
          v = v + rho * rho * sy * s[r] * s[c] + rho * s[r] * s[c];
          h_new[r][c] = v;
          c = c + 1;
        }
        r = r + 1;
      }
      h = h_new;
    }
    x = x_new;
    g = g_new;
    i = i + 1;
  }
  return x;
}

// Minimize f by limited-memory BFGS from x0 keeping the last m update
// pairs. Falls back to steepest descent when the history is empty. Returns
// the last iterate (at most 200 iterations). Complexity: O(iters * m * n).
pub fn optimize_lbfgs(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                      x0: &Vec[Float64], m: Int, tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var g = grad(&x);
  var s_hist = Vec[Vec[Float64]].new();
  var y_hist = Vec[Vec[Float64]].new();
  var rho_hist = Vec[Float64].new();
  var i = 0;
  while i < 200 {
    if vec_max_abs(&g) < tol { return x; }
    // two-loop recursion for the search direction
    var q = clone_vec(&g);
    var alphas = Vec[Float64].new();
    var k = s_hist.len();
    while k > 0 {
      var idx = k - 1;
      var alpha = rho_hist[idx] * vec_dot_in(&s_hist[idx], &q);
      var j = 0;
      while j < n {
        q[j] = q[j] - alpha * y_hist[idx][j];
        j = j + 1;
      }
      alphas.push(alpha);
      k = k - 1;
    }
    var r = clone_vec(&q);
    var j2 = 0;
    while j2 < n {
      r[j2] = r[j2] * 0.5;
      j2 = j2 + 1;
    }
    var a_count = alphas.len();
    var idx2 = 0;
    while idx2 < s_hist.len() {
      var alpha = alphas[a_count - 1 - idx2];
      var beta = rho_hist[idx2] * vec_dot_in(&y_hist[idx2], &r);
      var j3 = 0;
      while j3 < n {
        r[j3] = r[j3] + s_hist[idx2][j3] * (alpha - beta);
        j3 = j3 + 1;
      }
      idx2 = idx2 + 1;
    }
    var d = neg_vec(&r);
    var alpha_step = _line_search(f, grad, &x, &d);
    var x_new = Vec[Float64].new();
    var j4 = 0;
    while j4 < n {
      x_new.push(x[j4] + alpha_step * d[j4]);
      j4 = j4 + 1;
    }
    var g_new = grad(&x_new);
    var s = Vec[Float64].new();
    var y = Vec[Float64].new();
    var j5 = 0;
    while j5 < n {
      s.push(x_new[j5] - x[j5]);
      y.push(g_new[j5] - g[j5]);
      j5 = j5 + 1;
    }
    var sy = vec_dot_in(&s, &y);
    if sy != 0.0 {
      s_hist.push(s);
      y_hist.push(y);
      rho_hist.push(1.0 / sy);
    }
    while s_hist.len() > m && m > 0 {
      s_hist.remove(0);
      y_hist.remove(0);
      rho_hist.remove(0);
    }
    x = x_new;
    g = g_new;
    i = i + 1;
  }
  return x;
}

// Minimize f by the Nelder-Mead downhill simplex method from x0. Returns
// the best vertex (at most 500 iterations). Complexity: O(iters * n).
pub fn optimize_simplex(f: fn(&Vec[Float64]) -> Float64, x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var simplex = Vec[Vec[Float64]].new();
  simplex.push(clone_vec(x0));
  var i = 1;
  while i <= n {
    var v = clone_vec(x0);
    var step = 1.0;
    if v[i - 1] == 0.0 { step = 0.00025; } else { step = 0.05 * v[i - 1]; }
    v[i - 1] = v[i - 1] + step;
    simplex.push(v);
    i = i + 1;
  }
  var vals = Vec[Float64].new();
  var j = 0;
  while j <= n {
    vals.push(f(&simplex[j]));
    j = j + 1;
  }
  var iter = 0;
  while iter < 500 {
    _sort_simplex(&mut simplex, &mut vals);
    var spread = vals[n] - vals[0];
    if spread < tol { return simplex[0]; }
    var centroid = Vec[Float64].new();
    var c = 0;
    while c < n {
      var s = 0.0;
      var r = 0;
      while r < n {
        s = s + simplex[r][c];
        r = r + 1;
      }
      centroid.push(s / (n as Float64));
      c = c + 1;
    }
    // reflection
    var reflected = Vec[Float64].new();
    var c2 = 0;
    while c2 < n {
      reflected.push(centroid[c2] + 1.0 * (centroid[c2] - simplex[n][c2]));
      c2 = c2 + 1;
    }
    var f_ref = f(&reflected);
    if f_ref < vals[0] {
      // expansion
      var expanded = Vec[Float64].new();
      var c3 = 0;
      while c3 < n {
        expanded.push(centroid[c3] + 2.0 * (reflected[c3] - centroid[c3]));
        c3 = c3 + 1;
      }
      if f(&expanded) < f_ref {
        simplex[n] = expanded;
      } else {
        simplex[n] = reflected;
      }
    } else {
      if f_ref < vals[n - 1] {
        simplex[n] = reflected;
      } else {
      var f_worst = vals[n];
      if f_ref < f_worst {
        // contraction
        var contracted = Vec[Float64].new();
        var c4 = 0;
        while c4 < n {
          contracted.push(centroid[c4] + 0.5 * (reflected[c4] - centroid[c4]));
          c4 = c4 + 1;
        }
        if f(&contracted) < f_ref {
          simplex[n] = contracted;
        } else {
          _shrink_simplex(&mut simplex, &mut vals);
        }
      } else {
        var contracted2 = Vec[Float64].new();
        var c5 = 0;
        while c5 < n {
          contracted2.push(centroid[c5] + 0.5 * (simplex[n][c5] - centroid[c5]));
          c5 = c5 + 1;
        }
        if f(&contracted2) < f_worst {
          simplex[n] = contracted2;
        } else {
          _shrink_simplex(&mut simplex, &mut vals);
        }
      }
    }
    iter = iter + 1;
  }
  return simplex[0];
}
}

// Minimize f by Powell's conjugate direction method from x0 (cyclic
// one-dimensional golden-section line searches along a direction set).
// Returns the best point (at most 100 outer iterations). Complexity:
// O(iters * n * golden).
pub fn optimize_powell(f: fn(&Vec[Float64]) -> Float64, x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var dirs = Vec[Vec[Float64]].new();
  var i = 0;
  while i < n {
    var d = Vec[Float64].new();
    var j = 0;
    while j < n {
      if i == j {
        d.push(1.0);
      } else {
        d.push(0.0);
      }
      j = j + 1;
    }
    dirs.push(d);
    i = i + 1;
  }
  var iter = 0;
  while iter < 100 {
    var max_move = 0.0;
    var k = 0;
    while k < n {
      var step = _line_search(f, null_grad, &x, &dirs[k]);
      if step > max_move { max_move = step; }
      var j = 0;
      while j < n {
        x[j] = x[j] + step * dirs[k][j];
        j = j + 1;
      }
      k = k + 1;
    }
    if max_move < tol { return x; }
    iter = iter + 1;
  }
  return x;
}

// Minimize f by nonlinear conjugate gradient (Polak-Ribiere) from x0 with
// an exact-ish line search. Returns the last iterate (at most 500
// iterations). Complexity: O(iters * cost(grad)).
pub fn optimize_cg(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                   x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var g = grad(&x);
  var d = neg_vec(&g);
  var i = 0;
  while i < 500 {
    if vec_max_abs(&g) < tol { return x; }
    var alpha = _line_search(f, grad, &x, &d);
    var x_new = Vec[Float64].new();
    var k = 0;
    while k < n {
      x_new.push(x[k] + alpha * d[k]);
      k = k + 1;
    }
    var g_new = grad(&x_new);
    var num = vec_dot_in(&g_new, &_sub_vec(&g_new, &g));
    var denom = vec_dot_in(&g, &g);
    var beta = 0.0;
    if denom != 0.0 { beta = num / denom; }
    if beta < 0.0 { beta = 0.0; }
    var j = 0;
    while j < n {
      d[j] = -g_new[j] + beta * d[j];
      j = j + 1;
    }
    x = x_new;
    g = g_new;
    i = i + 1;
  }
  return x;
}

// Minimize f by gradient descent with learning rate lr from x0. Alias of
// gradient_descent. Complexity: O(steps * cost(grad)).
pub fn optimize_gradient(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                         x0: &Vec[Float64], lr: Float64, tol: Float64) -> Vec[Float64] {
  return gradient_descent(f, grad, x0, lr, tol);
}

// Minimize f by Newton's method with the Hessian from x0: solve
// H d = -g and step. Returns the last iterate (at most 100 iterations).
// Complexity: O(iters * n^3).
pub fn optimize_newton(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                       hess: fn(&Vec[Float64]) -> Vec[Vec[Float64]], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var i = 0;
  while i < 100 {
    var g = grad(&x);
    if vec_max_abs(&g) < tol { return x; }
    var h = hess(&x);
    var rhs = neg_vec(&g);
    var d = _solve_linear(&h, &rhs);
    if d.len() == 0 { return x; }
    var alpha = _line_search(f, grad, &x, &d);
    var k = 0;
    while k < n {
      x[k] = x[k] + alpha * d[k];
      k = k + 1;
    }
    i = i + 1;
  }
  return x;
}

// Minimize the sum of squared residuals by Gauss-Newton from x0 (requires
// the residual Jacobian; a one-sided finite-difference Jacobian is used
// when not available through the residual function alone). Returns the last
// iterate (at most 100 iterations). Complexity: O(iters * n^3).
pub fn optimize_least_squares(residuals: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] {
  var n = x0.len();
  var x = clone_vec(x0);
  var i = 0;
  while i < 100 {
    var r = residuals(&x);
    var m = r.len();
    var jac = Vec[Vec[Float64]].new();
    var c = 0;
    while c < n {
      var xp = clone_vec(&x);
      var h = 1e-6 * 0.001;
      xp[c] = xp[c] + h;
      var rp = residuals(&xp);
      var row = Vec[Float64].new();
      var rr = 0;
      while rr < m {
        row.push((rp[rr] - r[rr]) / h);
        rr = rr + 1;
      }
      jac.push(row);
      c = c + 1;
    }
    // normal equations J^T J d = -J^T r
    var jtj = _mat_mul_tt(&jac);
    var jtr = _mat_vec_t_mul(&jac, &r);
    var rhs = neg_vec(&jtr);
    var d = _solve_linear(&jtj, &rhs);
    if d.len() == 0 { return x; }
    var k = 0;
    while k < n {
      x[k] = x[k] + d[k];
      k = k + 1;
    }
    if vec_max_abs(&d) < tol { return x; }
    i = i + 1;
  }
  return x;
}

// ============================================================================
// Aliases
// ============================================================================

// Bracketing root finder via bisection. Alias of bisection.
// Complexity: O(log((b-a)/tol)).
pub fn bisection_root(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  return bisection(f, a, b, tol);
}

// Derivative-based Newton root finder. Alias of newton.
// Complexity: O(200 * cost(f + f')).
pub fn newton_root(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 {
  return newton(f, fprime, x0, tol);
}

// General single-equation root solver over [a, b]. Uses Brent's method
// (robust bracketing with quadratic convergence). Alias of brent.
pub fn solver_single(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  return brent(f, a, b, tol);
}

// ============================================================================
// Internal helpers
// ============================================================================

// Natural cubic spline coefficients (4 * (n - 1) values, one
// (a, b, c, d) tuple per segment, p(x) = a + b*t + c*t^2 + d*t^3 with
// t = x - x_i). O(n) via the tridiagonal Thomas algorithm.
fn _natural_cubic(xs: &Vec[Float64], ys: &Vec[Float64]) -> Vec[Float64] {
  var n = xs.len();
  var out = Vec[Float64].new();
  if n < 2 { return out; }
  var h = Vec[Float64].new();
  var i = 0;
  while i < n - 1 {
    h.push(xs[i + 1] - xs[i]);
    i = i + 1;
  }
  var lower = Vec[Float64].new();
  var diag = Vec[Float64].new();
  var upper = Vec[Float64].new();
  var rhs = Vec[Float64].new();
  lower.push(0.0);
  diag.push(1.0);
  upper.push(0.0);
  rhs.push(0.0);
  var j = 1;
  while j < n - 1 {
    lower.push(h[j - 1]);
    diag.push(2.0 * (h[j - 1] + h[j]));
    upper.push(h[j]);
    var t = 3.0 * ((ys[j + 1] - ys[j]) / h[j] - (ys[j] - ys[j - 1]) / h[j - 1]);
    rhs.push(t);
    j = j + 1;
  }
  lower.push(0.0);
  diag.push(1.0);
  upper.push(0.0);
  rhs.push(0.0);
  var c = _tridiagonal(&lower, &diag, &upper, &rhs);
  if c.len() != n { return out; }
  var s = 0;
  while s < n - 1 {
    var a = ys[s];
    var b = (ys[s + 1] - ys[s]) / h[s] - h[s] * (2.0 * c[s] + c[s + 1]) / 3.0;
    var d = (c[s + 1] - c[s]) / (3.0 * h[s]);
    out.push(a);
    out.push(b);
    out.push(c[s]);
    out.push(d);
    s = s + 1;
  }
  return out;
}

// Evaluate a natural cubic spline given by coefficients (from
// _natural_cubic) at x. Clamps x into [xs[0], xs[n-1]].
fn _eval_spline(xs: &Vec[Float64], ys: &Vec[Float64], coeffs: &Vec[Float64], x: Float64) -> Float64 {
  var n = xs.len();
  if n < 2 { return 0.0 / 0.0; }
  if x <= xs[0] { return ys[0]; }
  if x >= xs[n - 1] { return ys[n - 1]; }
  var i = 0;
  while i < n - 1 {
    if x >= xs[i] && x <= xs[i + 1] {
      var t = x - xs[i];
      var a = coeffs[4 * i];
      var b = coeffs[4 * i + 1];
      var c = coeffs[4 * i + 2];
      var d = coeffs[4 * i + 3];
      return a + b * t + c * t * t + d * t * t * t;
    }
    i = i + 1;
  }
  return ys[n - 1];
}

// Solve a tridiagonal system (lower, diag, upper, rhs) via the Thomas
// algorithm. Returns the empty vector when the matrix is singular.
fn _tridiagonal(lower: &Vec[Float64], diag: &Vec[Float64], upper: &Vec[Float64], rhs: &Vec[Float64]) -> Vec[Float64] {
  var n = diag.len();
  var out = Vec[Float64].new();
  if n == 0 { return out; }
  var cp = Vec[Float64].new();
  var dp = Vec[Float64].new();
  var i = 0;
  while i < n {
    if i == 0 {
      if diag[0] == 0.0 { return out; }
      cp.push(upper[0] / diag[0]);
      dp.push(rhs[0] / diag[0]);
    } else {
      var m = diag[i] - lower[i] * cp[i - 1];
      if m == 0.0 { return out; }
      cp.push(upper[i] / m);
      dp.push((rhs[i] - lower[i] * dp[i - 1]) / m);
    }
    i = i + 1;
  }
  var x = Vec[Float64].new();
  var j = 0;
  while j < n {
    x.push(0.0);
    j = j + 1;
  }
  x[n - 1] = dp[n - 1];
  var k = n - 2;
  while k >= 0 {
    x[k] = dp[k] - cp[k] * x[k + 1];
    k = k - 1;
  }
  return x;
}

// n-point Gauss-Legendre nodes and weights packed as
// [x0, w0, x1, w1, ...]. Computed by Newton iteration on P_n.
fn _legendre_nodes(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < n {
    var x = math.cos(3.141592653589793 * ((i as Float64) + 0.75) / ((n as Float64) + 0.5));
    var iter = 0;
    while iter < 50 {
      var p0 = 1.0;
      var p1 = x;
      var k = 1;
      while k < n {
        var p2 = ((2.0 * (k as Float64) + 1.0) * x * p1 - (k as Float64) * p0) / ((k as Float64) + 1.0);
        p0 = p1;
        p1 = p2;
        k = k + 1;
      }
      if n == 1 { p1 = x; }
      var pn = p1;
      var d = (n as Float64) * (x * pn - p0) / (x * x - 1.0);
      if d == 0.0 { iter = 50; } else {
        var dx = pn / d;
        x = x - dx;
        if math.abs_float(dx) < 1e-15 { iter = 50; }
      }
      iter = iter + 1;
    }
    // recompute P_n and P'_n at the converged node
    var p0 = 1.0;
    var p1 = x;
    var k = 1;
    while k < n {
      var p2 = ((2.0 * (k as Float64) + 1.0) * x * p1 - (k as Float64) * p0) / ((k as Float64) + 1.0);
      p0 = p1;
      p1 = p2;
      k = k + 1;
    }
    if n == 1 { p1 = x; }
    var pprime = d2(n, x, p0);
    var denom = (1.0 - x * x) * pprime * pprime;
    var w = 2.0;
    if denom != 0.0 { w = 2.0 / denom; }
    out.push(x);
    out.push(w);
    i = i + 1;
  }
  return out;
}

// P'_n(x) via the relation n * (x*P_n(x) - P_{n-1}(x)) / (x^2 - 1).
fn d2(n: Int, x: Float64, p_prev: Float64) -> Float64 {
  var px = legendre_at(n, x);
  var denom = x * x - 1.0;
  if denom == 0.0 { return 0.0; }
  return (n as Float64) * (x * px - p_prev) / denom;
}

// Evaluate the n-th Legendre polynomial at x.
fn legendre_at(n: Int, x: Float64) -> Float64 {
  if n == 0 { return 1.0; }
  if n == 1 { return x; }
  var p0 = 1.0;
  var p1 = x;
  var k = 1;
  while k < n {
    var p2 = ((2.0 * (k as Float64) + 1.0) * x * p1 - (k as Float64) * p0) / ((k as Float64) + 1.0);
    p0 = p1;
    p1 = p2;
    k = k + 1;
  }
  return p1;
}

// Simpson value over [a, b].
fn _simp(f: fn(Float64) -> Float64, a: Float64, b: Float64) -> Float64 {
  var h = (b - a) / 6.0;
  return h * (f(a) + 4.0 * f(0.5 * (a + b)) + f(b));
}

// Recursive adaptive Simpson refinement.
fn _adapt(f: fn(Float64) -> Float64, a: Float64, b: Float64, whole: Float64, left: Float64,
          right: Float64, tol: Float64, depth: Int) -> Float64 {
  var mid = 0.5 * (a + b);
  var lmid = 0.5 * (a + mid);
  var rmid = 0.5 * (mid + b);
  var ll = _simp(f, a, mid);
  var rr = _simp(f, mid, b);
  var estimate = left + right - whole;
  if estimate < 0.0 { estimate = -estimate; }
  if estimate < 15.0 * tol || depth > 32 {
    return ll + rr + (ll + rr - whole) / 15.0;
  }
  return _adapt(f, a, mid, ll, _simp(f, a, lmid), _simp(f, lmid, mid), tol * 0.5, depth + 1)
       + _adapt(f, mid, b, rr, _simp(f, mid, rmid), _simp(f, rmid, b), tol * 0.5, depth + 1);
}

// Simple back-tracking line search: step = 1 halved while f(x + step*d)
// does not decrease.
fn _line_search(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64],
                x: &Vec[Float64], d: &Vec[Float64]) -> Float64 {
  var f0 = f(x);
  var step = 1.0;
  var i = 0;
  while i < 20 {
    var xc = Vec[Float64].new();
    var k = 0;
    while k < x.len() {
      xc.push(x[k] + step * d[k]);
      k = k + 1;
    }
    if f(&xc) < f0 { return step; }
    step = step * 0.5;
    i = i + 1;
  }
  return 0.0;
}

// Dummy gradient placeholder for line searches that only need f.
fn null_grad(x: &Vec[Float64]) -> Vec[Float64] {
  return clone_vec(x);
}

// Evaluate all residuals of fs at x into a fresh vector.
fn eval_fs(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < fs.len() {
    out.push(fs[i](x));
    i = i + 1;
  }
  return out;
}

// Copy a dynamic vector.
fn clone_vec(v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < v.len() {
    out.push(v[i]);
    i = i + 1;
  }
  return out;
}

// Negate a dynamic vector.
fn neg_vec(v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < v.len() {
    out.push(-v[i]);
    i = i + 1;
  }
  return out;
}

// a - b component-wise.
fn _sub_vec(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < a.len() {
    out.push(a[i] - b[i]);
    i = i + 1;
  }
  return out;
}

// Dot product of two dynamic vectors.
fn vec_dot_in(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < a.len() {
    s = s + a[i] * b[i];
    i = i + 1;
  }
  return s;
}

// Largest absolute component of a dynamic vector.
fn vec_max_abs(v: &Vec[Float64]) -> Float64 {
  var m = 0.0;
  var i = 0;
  while i < v.len() {
    var a = v[i];
    if a < 0.0 { a = -a; }
    if a > m { m = a; }
    i = i + 1;
  }
  return m;
}

// n x n identity matrix.
fn mat_identity(n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
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

// Copy of a matrix with identity content but the caller's shape.
fn _mat_identity_like(m: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var n = m.len();
  return mat_identity(n);
}

// Matrix-vector product (row-major, m rows x n cols).
fn _mat_vec_mul(a: &Vec[Vec[Float64]], v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var i = 0;
  while i < a.len() {
    var s = 0.0;
    var j = 0;
    while j < v.len() {
      s = s + a[i][j] * v[j];
      j = j + 1;
    }
    out.push(s);
    i = i + 1;
  }
  return out;
}

// J^T * v where J is m x n (returns n-vector).
fn _mat_vec_t_mul(a: &Vec[Vec[Float64]], v: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = a.len();
  var m = v.len();
  var j = 0;
  while j < m {
    var s = 0.0;
    var i = 0;
    while i < n {
      s = s + a[i][j] * v[i];
      i = i + 1;
    }
    out.push(s);
    j = j + 1;
  }
  return out;
}

// J^T * J for an m x n Jacobian (returns n x n).
fn _mat_mul_tt(a: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var n = a.len();
  var m = 0;
  if n > 0 { m = a[0].len(); }
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < m {
    var row = Vec[Float64].new();
    var j = 0;
    while j < m {
      var s = 0.0;
      var k = 0;
      while k < n {
        s = s + a[k][i] * a[k][j];
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

// Sum of two matrices.
fn _mat_add(a: &Vec[Vec[Float64]], b: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  var i = 0;
  while i < a.len() {
    var row = Vec[Float64].new();
    var j = 0;
    while j < a[i].len() {
      row.push(a[i][j] + b[i][j]);
      j = j + 1;
    }
    out.push(row);
    i = i + 1;
  }
  return out;
}

// Solve A x = b (square, row-major) by Gaussian elimination with partial
// pivoting. Returns the empty vector for singular or non-square input.
fn _solve_linear(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] {
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
    var piv = math.abs_float(aug[p][p]);
    var piv_row = p;
    var r = p + 1;
    while r < n {
      if math.abs_float(aug[r][p]) > piv {
        piv = math.abs_float(aug[r][p]);
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
    var row = 0;
    while row < n {
      if row != p {
        var factor = aug[row][p];
        if factor != 0.0 {
          var col = 0;
          while col <= n {
            aug[row][col] = aug[row][col] - factor * aug[p][col];
            col = col + 1;
          }
        }
      }
      row = row + 1;
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

// Sort simplex vertices by ascending function value (selection sort).
fn _sort_simplex(simplex: &mut Vec[Vec[Float64]], vals: &mut Vec[Float64]) {
  var n = simplex.len();
  var i = 0;
  while i < n {
    var best = i;
    var j = i + 1;
    while j < n {
      if vals[j] < vals[best] { best = j; }
      j = j + 1;
    }
    if best != i {
      var tv = vals[i];
      vals[i] = vals[best];
      vals[best] = tv;
      var ts = simplex[i];
      simplex[i] = simplex[best];
      simplex[best] = ts;
    }
    i = i + 1;
  }
}

// Nelder-Mead shrink: move all vertices toward the best vertex.
fn _shrink_simplex(simplex: &mut Vec[Vec[Float64]], vals: &mut Vec[Float64]) {
  var n = simplex.len();
  var i = 1;
  while i < n {
    var j = 0;
    while j < simplex[0].len() {
      simplex[i][j] = simplex[0][j] + 0.5 * (simplex[i][j] - simplex[0][j]);
      j = j + 1;
    }
    i = i + 1;
  }
}
