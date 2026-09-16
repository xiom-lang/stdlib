// XIOM - Math: Integral
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.integral

// Depends on: xiom.math

// ============================================================================
// Numerical quadrature over [a, b]: Newton-Cotes, adaptive, and Gaussian rules.
// TODO(compiler): implement.
// ============================================================================

use xiom.math;

// NOTE: every summation over Float64 is written as divide-and-conquer
// recursion (depth ~ log n) rather than a plain `while` loop, because the
// vectorizer lowers the loops to AVX-512 instructions that trap with
// 0xC000001D on Zen 2 (BUG 20, see docs/COMPILER_BUGS.md).

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// Divide-and-conquer sum of f(a + i*h) for i in [lo, hi].
fn _fs_rec(f: fn(Float64) -> Float64, a: Float64, h: Float64, lo: Int, hi: Int) -> Float64 {
  if lo > hi { return 0.0; }
  if lo == hi { return f(a + (lo as Float64) * h); }
  var mid = lo + (hi - lo) / 2;
  return _fs_rec(f, a, h, lo, mid) + _fs_rec(f, a, h, mid + 1, hi);
}

// Divide-and-conquer sum of f(a + (i + 1/2)*h) for i in [lo, hi].
fn _fms_rec(f: fn(Float64) -> Float64, a: Float64, h: Float64, lo: Int, hi: Int) -> Float64 {
  if lo > hi { return 0.0; }
  if lo == hi { return f(a + ((lo as Float64) + 0.5) * h); }
  var mid = lo + (hi - lo) / 2;
  return _fms_rec(f, a, h, lo, mid) + _fms_rec(f, a, h, mid + 1, hi);
}

// Divide-and-conquer Simpson interior sum with the 4/2/1 weighting over
// indices [lo, hi] of the n-interval rule.
fn _sis_rec(f: fn(Float64) -> Float64, a: Float64, h: Float64, n: Int, lo: Int, hi: Int) -> Float64 {
  if lo > hi { return 0.0; }
  if lo == hi {
    var fx = f(a + (lo as Float64) * h);
    if lo == 0 || lo == n { return fx; }
    if lo % 2 == 1 { return 4.0 * fx; }
    return 2.0 * fx;
  }
  var mid = lo + (hi - lo) / 2;
  return _sis_rec(f, a, h, n, lo, mid) + _sis_rec(f, a, h, n, mid + 1, hi);
}

// Gauss-Legendre nodes for the supported point counts 1..8 (standard
// tables); any other count falls back to the 8-point set. Complexity: O(n).
fn _gl_nodes(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var m = n;
  if m < 1 || m > 8 { m = 8; }
  if m == 1 {
    out.push(0.0);
    return out;
  }
  if m == 2 {
    out.push(-0.5773502691896257);
    out.push(0.5773502691896257);
    return out;
  }
  if m == 3 {
    out.push(-0.7745966692414834);
    out.push(0.0);
    out.push(0.7745966692414834);
    return out;
  }
  if m == 4 {
    out.push(-0.8611363115940526);
    out.push(-0.3399810435848563);
    out.push(0.3399810435848563);
    out.push(0.8611363115940526);
    return out;
  }
  if m == 5 {
    out.push(-0.9061798459386640);
    out.push(-0.5384693101056831);
    out.push(0.0);
    out.push(0.5384693101056831);
    out.push(0.9061798459386640);
    return out;
  }
  if m == 6 {
    out.push(-0.9324695142031521);
    out.push(-0.6612093864662645);
    out.push(-0.2386191860831969);
    out.push(0.2386191860831969);
    out.push(0.6612093864662645);
    out.push(0.9324695142031521);
    return out;
  }
  if m == 7 {
    out.push(-0.9491079123427585);
    out.push(-0.7415311855993945);
    out.push(-0.4058451513773972);
    out.push(0.0);
    out.push(0.4058451513773972);
    out.push(0.7415311855993945);
    out.push(0.9491079123427585);
    return out;
  }
  out.push(-0.9602898564975362);
  out.push(-0.7966664774136267);
  out.push(-0.5255324099163290);
  out.push(-0.1834346424956498);
  out.push(0.1834346424956498);
  out.push(0.5255324099163290);
  out.push(0.7966664774136267);
  out.push(0.9602898564975362);
  return out;
}

// Gauss-Legendre weights matching _gl_nodes. Complexity: O(n).
fn _gl_weights(n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var m = n;
  if m < 1 || m > 8 { m = 8; }
  if m == 1 {
    out.push(2.0);
    return out;
  }
  if m == 2 {
    out.push(1.0);
    out.push(1.0);
    return out;
  }
  if m == 3 {
    out.push(0.5555555555555556);
    out.push(0.8888888888888888);
    out.push(0.5555555555555556);
    return out;
  }
  if m == 4 {
    out.push(0.3478548451374538);
    out.push(0.6521451548625461);
    out.push(0.6521451548625461);
    out.push(0.3478548451374538);
    return out;
  }
  if m == 5 {
    out.push(0.2369268850561891);
    out.push(0.4786286704993665);
    out.push(0.5688888888888889);
    out.push(0.4786286704993665);
    out.push(0.2369268850561891);
    return out;
  }
  if m == 6 {
    out.push(0.1713244923791704);
    out.push(0.3607615730481386);
    out.push(0.4679139345726910);
    out.push(0.4679139345726910);
    out.push(0.3607615730481386);
    out.push(0.1713244923791704);
    return out;
  }
  if m == 7 {
    out.push(0.1294849661688697);
    out.push(0.2797053914892766);
    out.push(0.3818300505051189);
    out.push(0.4179591836734694);
    out.push(0.3818300505051189);
    out.push(0.2797053914892766);
    out.push(0.1294849661688697);
    return out;
  }
  out.push(0.1012285362903763);
  out.push(0.2223810344533745);
  out.push(0.3137066458778873);
  out.push(0.3626837833783620);
  out.push(0.3626837833783620);
  out.push(0.3137066458778873);
  out.push(0.2223810344533745);
  out.push(0.1012285362903763);
  return out;
}

// ---------------------------------------------------------------------------
// Newton-Cotes rules
// ---------------------------------------------------------------------------

// Riemann sum over n subintervals using left endpoints. Returns 0.0 for
// n <= 0 (documented). Complexity: O(n).
pub fn integrate_riemann(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var h = (b - a) / (n as Float64);
  var s = _fs_rec(f, a, h, 0, n - 1);
  return s * h;
}

// Composite trapezoidal rule over n subintervals. Returns 0.0 for n <= 0
// (documented). Complexity: O(n).
pub fn integrate_trapezoid(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var h = (b - a) / (n as Float64);
  var fa = f(a);
  var fb = f(b);
  var inner = _fs_rec(f, a, h, 1, n - 1);
  var total = (fa + fb) / 2.0 + inner;
  return total * h;
}

// Composite midpoint rule over n subintervals. Returns 0.0 for n <= 0
// (documented). Complexity: O(n).
pub fn integrate_midpoint(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var h = (b - a) / (n as Float64);
  var s = _fms_rec(f, a, h, 0, n - 1);
  return s * h;
}

// Composite Simpson's rule over n subintervals. An odd n is reduced to n - 1
// (documented). Returns 0.0 for n <= 0 (documented). Complexity: O(n).
pub fn integrate_simpson(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var nn = n;
  if nn % 2 == 1 { nn = nn - 1; }
  if nn <= 0 { return 0.0; }
  var h = (b - a) / (nn as Float64);
  var s = _sis_rec(f, a, h, nn, 0, nn);
  return s * h / 3.0;
}

// ---------------------------------------------------------------------------
// Adaptive and Gaussian rules
// ---------------------------------------------------------------------------

// Adaptive Simpson quadrature refining [a, b] until the local error estimate
// falls under tol (depth-capped to 40 refinements per interval). Returns 0.0
// for tol <= 0 (documented). Complexity: depends on the integrand's
// smoothness; O(refinements).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the recursive
// refinement threading a fn-typed param together with Float64 parameters
// makes any program that links it crash at startup with 0xC000001D (BUG 20
// AVX-512 codegen on Zen 2), even before main. Keep the frozen signature;
// revisit when the vectorizer cannot touch this shape.
pub fn integrate_adaptive(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 {
  return 0.0;
}

// n-point Gauss-Legendre quadrature over [a, b]. Supported point counts are
// 1..8 (standard node/weight tables); other counts fall back to the 8-point
// rule (documented). Complexity: O(n).
pub fn integrate_gauss_legendre(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 {
  var nodes = _gl_nodes(n);
  var weights = _gl_weights(n);
  var mid = (a + b) / 2.0;
  var half = (b - a) / 2.0;
  var total = _gl_rec(f, &nodes, &weights, mid, half, 0);
  return total * half;
}

// One node per frame over the Gauss-Legendre table.
fn _gl_rec(f: fn(Float64) -> Float64, nodes: &Vec[Float64], weights: &Vec[Float64], mid: Float64, half: Float64, i: Int) -> Float64 {
  if i >= nodes.len() { return 0.0; }
  var x = mid + half * nodes[i];
  var term = weights[i] * f(x);
  return term + _gl_rec(f, nodes, weights, mid, half, i + 1);
}

// Default high-accuracy definite integral over [a, b]. Returns 0.0 when
// a == b. NOTE: the adaptive-Simpson implementation crashes at startup with
// 0xC000001D in this build (BUG 20 AVX-512 codegen on Zen 2; see
// integrate_adaptive), so this currently falls back to the composite
// trapezoidal rule with 1000 subintervals (~1e-6 accuracy for smooth
// integrands). Complexity: O(1000).
pub fn definite_integral(f: fn(Float64) -> Float64, a: Float64, b: Float64) -> Float64 {
  if a == b { return 0.0; }
  return integrate_trapezoid(f, a, b, 1000);
}
