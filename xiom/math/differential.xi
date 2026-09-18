// XIOM - Math: Differential
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.differential

// Depends on: xiom.math

// ============================================================================
// Numerical differentiation and vector calculus: finite differences, gradients,
// Jacobians. TODO(compiler): implement.
// ============================================================================

use xiom.math;

// NOTE: on this machine (Zen 2, no AVX-512) the compiler emits AVX-512 for
// many catalog Float64 constructs (BUG 20, docs/COMPILER_BUGS.md), so several
// functions keep their frozen signatures as documented stubs. Verified
// working: the plain central-difference derivatives. Trapping shapes: the
// Richardson iteration loop, and the vector-calculus Vec[Float64] loops.

// First derivative of f at x by the central difference (f(x+h) - f(x-h))/2h.
// Returns 0.0 for h == 0 (documented). Complexity: O(1).
/// First derivative of f at x by the central difference (f(x+h) - f(x-h))/2h.
/// Returns 0.0 for h == 0 (documented). Complexity: O(1).
pub fn derivative(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 {
  if h == 0.0 { return 0.0; }
  var fplus = f(x + h);
  var fminus = f(x - h);
  return (fplus - fminus) / (2.0 * h);
}

// Second derivative of f at x by the central difference
// (f(x+h) - 2f(x) + f(x-h))/h^2. Returns 0.0 for h == 0 (documented).
// Complexity: O(1).
/// Second derivative of f at x by the central difference
/// (f(x+h) - 2f(x) + f(x-h))/h^2. Returns 0.0 for h == 0 (documented).
/// Complexity: O(1).
pub fn derivative2(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 {
  if h == 0.0 { return 0.0; }
  var fplus = f(x + h);
  var f0 = f(x);
  var fminus = f(x - h);
  var h2 = h * h;
  return (fplus - 2.0 * f0 + fminus) / h2;
}

// Third derivative of f at x by the four-point central difference
// (f(x+2h) - 2f(x+h) + 2f(x-h) - f(x-2h))/2h^3. Returns 0.0 for h == 0
// (documented). Complexity: O(1).
/// Third derivative of f at x by the four-point central difference
/// (f(x+2h) - 2f(x+h) + 2f(x-h) - f(x-2h))/2h^3. Returns 0.0 for h == 0
/// (documented). Complexity: O(1).
pub fn derivative3(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 {
  if h == 0.0 { return 0.0; }
  var fp2 = f(x + 2.0 * h);
  var fp1 = f(x + h);
  var fm1 = f(x - h);
  var fm2 = f(x - 2.0 * h);
  var h2 = h * h;
  var h3 = h2 * h;
  return (fp2 - 2.0 * fp1 + 2.0 * fm1 - fm2) / (2.0 * h3);
}

// Central finite-difference approximation of the first derivative. Alias of
// derivative. Returns 0.0 for h == 0 (documented). Complexity: O(1).
/// Central finite-difference approximation of the first derivative. Alias of
/// derivative. Returns 0.0 for h == 0 (documented). Complexity: O(1).
pub fn finite_difference(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 {
  return derivative(f, x, h);
}

// Richardson-extrapolated first derivative of f at x: repeatedly halves h and
// combines D(h) and D(h/2) as (4*D(h/2) - D(h))/3 until consecutive estimates
// agree within tol. Returns 0.0 for tol <= 0 (documented). Complexity:
// O(halvings).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the halving
// iteration loop emits AVX-512 and crashes with 0xC000001D (BUG 20) on Zen 2.
// Keep the frozen signature; revisit when the loop is not vectorized.
/// Richardson-extrapolated first derivative of f at x: repeatedly halves h and
/// combines D(h) and D(h/2) as (4*D(h/2) - D(h))/3 until consecutive estimates
/// agree within tol. Returns 0.0 for tol <= 0 (documented). Complexity:
/// O(halvings).
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the halving
/// iteration loop emits AVX-512 and crashes with 0xC000001D (BUG 20) on Zen 2.
/// Keep the frozen signature; revisit when the loop is not vectorized.
pub fn richardson(f: fn(Float64) -> Float64, x: Float64, h: Float64, tol: Float64) -> Float64 {
  return 0.0;
}

// Gradient vector of the scalar field f at x: each component is the central
// partial difference (f(x + h e_i) - f(x - h e_i))/2h with h = 1e-6.
// Complexity: O(n * f).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the central
// partial-difference loops build and read Vec[Float64] perturbations, which
// crash with 0xC0000005 (BUG 12 family Vec[Float64] element reads) and
// 0xC000001D (BUG 20 loops). Keep the frozen signature; revisit when
// Vec[Float64] element reads and float loops are codegen-correct.
/// Gradient vector of the scalar field f at x: each component is the central
/// partial difference (f(x + h e_i) - f(x - h e_i))/2h with h = 1e-6.
/// Complexity: O(n * f).
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the central
/// partial-difference loops build and read Vec[Float64] perturbations, which
/// crash with 0xC0000005 (BUG 12 family Vec[Float64] element reads) and
/// 0xC000001D (BUG 20 loops). Keep the frozen signature; revisit when
/// Vec[Float64] element reads and float loops are codegen-correct.
pub fn gradient(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  return out;
}

// Jacobian matrix of the function vector fs at x: entry (i, j) is the central
// partial difference of fs[i] with respect to x[j] (step h = 1e-6).
// Complexity: O(|fs| * n * f).
// TODO(compiler): NOT IMPLEMENTABLE - same Vec[Float64]/loop crash as gradient
// (0xC0000005 / 0xC000001D). Keep the frozen signature.
/// Jacobian matrix of the function vector fs at x: entry (i, j) is the central
/// partial difference of fs[i] with respect to x[j] (step h = 1e-6).
/// Complexity: O(|fs| * n * f).
/// TODO(compiler): NOT IMPLEMENTABLE - same Vec[Float64]/loop crash as gradient
/// (0xC0000005 / 0xC000001D). Keep the frozen signature.
pub fn jacobian(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

// Partial derivative of f with respect to x[i] at x by the central difference.
// Returns 0.0 for h == 0 and for i out of [0, len(x)) (documented).
// Complexity: O(f).
// TODO(compiler): NOT IMPLEMENTABLE - same Vec[Float64]/loop crash as gradient
// (0xC0000005 / 0xC000001D). Keep the frozen signature.
/// Partial derivative of f with respect to x[i] at x by the central difference.
/// Returns 0.0 for h == 0 and for i out of [0, len(x)) (documented).
/// Complexity: O(f).
/// TODO(compiler): NOT IMPLEMENTABLE - same Vec[Float64]/loop crash as gradient
/// (0xC0000005 / 0xC000001D). Keep the frozen signature.
pub fn partial_derivative(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64], i: Int, h: Float64) -> Float64 {
  return 0.0;
}
