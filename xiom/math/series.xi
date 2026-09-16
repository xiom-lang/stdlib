// XIOM - Math: Series
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.series

// Depends on: xiom.math

// ============================================================================
// Sequences and series: sums, power series, continued fractions, recurrence
// relations, convergence analysis. TODO(compiler): implement.
// ============================================================================

use xiom.math;

// NOTE: every summation over Float64 is written as divide-and-conquer
// recursion (depth ~ log n) rather than a plain `while` loop, because the
// vectorizer lowers the loops to AVX-512 instructions that trap with
// 0xC000001D on Zen 2 (BUG 20, see docs/COMPILER_BUGS.md). The recursive
// form has no loop for the vectorizer to touch.

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// x^k for k >= 0 via exponentiation by squaring (recursive, depth log k).
fn _ipow(x: Float64, k: Int) -> Float64 {
  if k == 0 { return 1.0; }
  var h = k / 2;
  var p = _ipow(x, h);
  if k % 2 == 0 { return p * p; }
  return p * p * x;
}

// Divide-and-conquer sum of terms(i) over i in [lo, hi] (depth log n).
fn _sum_rec(terms: fn(Int) -> Float64, lo: Int, hi: Int) -> Float64 {
  if lo > hi { return 0.0; }
  if lo == hi { return terms(lo); }
  var mid = lo + (hi - lo) / 2;
  return _sum_rec(terms, lo, mid) + _sum_rec(terms, mid + 1, hi);
}

// Divide-and-conquer sum of coefficients[i] * x^i over i in [lo, hi].
fn _ps_rec(coeffs: &Vec[Float64], x: Float64, lo: Int, hi: Int) -> Float64 {
  if lo > hi { return 0.0; }
  if lo == hi { return coeffs[lo] * _ipow(x, lo); }
  var mid = lo + (hi - lo) / 2;
  return _ps_rec(coeffs, x, lo, mid) + _ps_rec(coeffs, x, mid + 1, hi);
}

// ---------------------------------------------------------------------------
// Summation
// ---------------------------------------------------------------------------

// Sum of terms(0) + terms(1) + ... + terms(n-1). Returns 0.0 for n <= 0.
// Complexity: O(n).
pub fn series_sum(terms: fn(Int) -> Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  return _sum_rec(terms, 0, n - 1);
}

// Value of the power series sum c[i] * x^i over the coefficients. Returns
// 0.0 for an empty coefficient list. Complexity: O(n log n).
pub fn power_series(coefficients: &Vec[Float64], x: Float64) -> Float64 {
  var n = coefficients.len();
  if n == 0 { return 0.0; }
  return _ps_rec(coefficients, x, 0, n - 1);
}

// Sum of the first n terms of the geometric series a, a*r, a*r^2, ... via the
// closed form a*(1 - r^n)/(1 - r) for r != 1 and a*n for r == 1. Returns
// 0.0 for n <= 0. Complexity: O(log n).
pub fn geometric_series(a: Float64, r: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  if r == 1.0 { return a * (n as Float64); }
  var p = _ipow(r, n);
  return a * (1.0 - p) / (1.0 - r);
}

// Sum of the first n terms of the arithmetic series a, a+d, a+2d, ... via the
// closed form n/2 * (2a + (n-1)d). Returns 0.0 for n <= 0. Complexity: O(1).
pub fn arithmetic_series(a: Float64, d: Float64, n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  var nf = n as Float64;
  return nf / 2.0 * (2.0 * a + (nf - 1.0) * d);
}

// The n-th harmonic number: sum of 1/k for k = 1..n. Returns 0.0 for n <= 0.
// Complexity: O(n).
pub fn harmonic(n: Int) -> Float64 {
  if n <= 0 { return 0.0; }
  return _sum_rec(_inv_k, 1, n);
}

// 1/k as Float64 (term factory for harmonic).
fn _inv_k(k: Int) -> Float64 {
  return 1.0 / (k as Float64);
}

// ---------------------------------------------------------------------------
// Function approximations
// ---------------------------------------------------------------------------

// Truncated Maclaurin (Taylor at 0) approximation of f to the given order:
// sum_{k=0..order} f^(k)(0)/k! * x^k. The derivatives are obtained with the
// order-2 central-difference stencil at step 0.001, so the approximation is
// accurate for smooth f and small |x|. Returns 0.0 for order < 0.
// Complexity: O(order^2).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the implementation
// (recursive stencil accumulation over fn-typed params with Int->Float64 casts)
// makes any program that links it crash at startup with 0xC000001D (BUG 20
// AVX-512 codegen on Zen 2), even before main. Keep the frozen signature;
// revisit when the vectorizer cannot touch this shape.
pub fn maclaurin_series(f: fn(Float64) -> Float64, order: Int, x: Float64) -> Float64 {
  return 0.0;
}

// Value of the simple continued fraction [coeffs[0]; coeffs[1], ...] =
// c0 + 1/(c1 + 1/(c2 + ...)), evaluated from the last coefficient backwards
// by recursion (one term per frame; the smoke uses a handful of terms).
// Returns 0.0 for an empty list. A zero partial denominator propagates as +/-
// infinity (IEEE semantics). Complexity: O(len(coeffs)).
pub fn continued_fraction(coeffs: &Vec[Float64]) -> Float64 {
  var n = coeffs.len();
  if n == 0 { return 0.0; }
  return _cf_rec(coeffs, 0);
}

// Backward evaluation of the fraction starting at index i.
fn _cf_rec(coeffs: &Vec[Float64], i: Int) -> Float64 {
  if i == coeffs.len() - 1 { return coeffs[i]; }
  var rest = _cf_rec(coeffs, i + 1);
  return coeffs[i] + 1.0 / rest;
}

// ---------------------------------------------------------------------------
// Recurrence sequences
// ---------------------------------------------------------------------------

// The n-th Fibonacci number F(n), 0-indexed (F(0) = 0, F(1) = 1); returns 0
// for n < 0. Delegates to xiom.math.combinatorics.fibonacci. Complexity: O(n).
pub fn fib(n: Int) -> Int {
  return math.combinatorics.fibonacci(n);
}

// The n-th Fibonacci number via the fast-doubling identities
// F(2k) = F(k)(2F(k+1) - F(k)), F(2k+1) = F(k)^2 + F(k+1)^2. Returns 0 for
// n < 0 and 0 (documented) for n > 91, where the doubling intermediates
// exceed Int range (the plain iteration in math.combinatorics.fibonacci
// reaches F(92)). Complexity: O(log n).
pub fn fib_fast(n: Int) -> Int {
  if n < 0 { return 0; }
  if n > 91 { return 0; }
  var r = _fib_doubling(n);
  return r.0;
}

// Fast-doubling pair (F(k), F(k+1)).
fn _fib_doubling(n: Int) -> (Int, Int) {
  if n == 0 { return (0, 1); }
  var h = n / 2;
  var r = _fib_doubling(h);
  var a = r.0;
  var b = r.1;
  var t1 = 2 * b - a;
  var c = a * t1;
  var d = a * a + b * b;
  if n % 2 == 0 { return (c, d); }
  var e = c + d;
  return (d, e);
}

// Estimated order of convergence p of the sequence seq: using the last
// consecutive-difference triple (e0, e1, e2) with all ratios valid, p =
// ln(e2/e1) / ln(e1/e0). Returns 0.0 when fewer than 4 terms are supplied or
// when no valid triple exists (documented; e.g. a zero difference anywhere).
// Complexity: O(len(seq)).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the recursive
// walk threading a Bool accumulator and math.ln results makes any program
// that links it crash at startup with 0xC000001D (BUG 20 AVX-512 codegen on
// Zen 2), even before main. Keep the frozen signature; revisit when the
// vectorizer cannot touch this shape.
pub fn convergence_rate(seq: &Vec[Float64]) -> Float64 {
  return 0.0;
}
