// XIOM - Math: Hyperbolic
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.hyperbolic

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Hyperbolic and inverse hyperbolic functions (concrete Float64).
// sinh/cosh/tanh use libm math.exp; the *_pure variants build on the pure
// series math.exponential.exp_pure (no libm). tanh uses the stable form
// (exp(2x)-1)/(exp(2x)+1) with saturation at |x| > 20. Inverse functions:
// asinh/acosh/atanh via logarithms; domain errors that would produce NaN
// (acosh x<1, atanh |x|>1) return a documented -1.0 sentinel because BUG 19
// cannot construct NaN. csch(0) / coth(0) are +inf (native 1.0/0.0).
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

// Hyperbolic sine of x. sinh(0.0) == 0.0; |x| > ~710 overflows to +-inf.
// Complexity: O(1), libm exp.
pub fn sinh(x: Float64) -> Float64 {
  return (math.exp(x) - math.exp(-x)) / 2.0;
}

// Hyperbolic cosine of x. cosh(0.0) == 1.0; |x| > ~710 overflows to +inf.
// Complexity: O(1), libm exp.
pub fn cosh(x: Float64) -> Float64 {
  return (math.exp(x) + math.exp(-x)) / 2.0;
}

// Hyperbolic tangent of x. tanh(0.0) == 0.0; saturates to +-1.0 for
// |x| > 20. Uses (exp(2x)-1)/(exp(2x)+1) for stability. Complexity: O(1).
pub fn tanh(x: Float64) -> Float64 {
  if x > 20.0 { return 1.0; }
  if x < -20.0 { return -1.0; }
  var ex = math.exp(2.0 * x);
  return (ex - 1.0) / (ex + 1.0);
}

// Hyperbolic cosecant, 1/sinh(x). csch(0.0) == +inf (native 1.0/0.0).
// Complexity: O(1), libm exp.
pub fn csch(x: Float64) -> Float64 {
  return 1.0 / sinh(x);
}

// Hyperbolic secant, 1/cosh(x). Always finite (cosh > 0). Complexity: O(1).
pub fn sech(x: Float64) -> Float64 {
  return 1.0 / cosh(x);
}

// Hyperbolic cotangent, 1/tanh(x). coth(0.0) == +inf (native 1.0/0.0).
// Complexity: O(1), libm exp.
pub fn coth(x: Float64) -> Float64 {
  return 1.0 / tanh(x);
}

// Inverse hyperbolic sine: ln(x + sqrt(x^2 + 1)). Odd function. For
// |x| > 1e150 uses ln(|x|) + ln 2 (avoids x^2 overflow and cancellation).
// asinh(1.0) == 0.881373587019543. Complexity: O(1), libm ln/sqrt.
pub fn asinh(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  var neg = x < 0.0;
  var ax = x;
  if neg { ax = -ax; }
  var r = 0.0;
  if ax > 1e150 {
    r = math.ln(ax) + 0.6931471805599453;
  } else {
    r = math.ln(ax + math.sqrt(ax * ax + 1.0));
  }
  if neg { return -r; }
  return r;
}

// Inverse hyperbolic cosine: ln(x + sqrt(x^2 - 1)). Requires x >= 1.
// For x < 1 returns NaN (IEEE semantics). For x > 1e150 uses ln(x) + ln 2
// (avoids overflow). acosh(1.0) == 0.0, acosh(cosh(1.0)) == 1.0.
// Complexity: O(1), libm ln/sqrt.
pub fn acosh(x: Float64) -> Float64 {
  if x < 1.0 { return 0.0 / 0.0; }
  if x == 1.0 { return 0.0; }
  if x > 1e150 {
    return math.ln(x) + 0.6931471805599453;
  }
  return math.ln(x + math.sqrt(x * x - 1.0));
}

// Inverse hyperbolic tangent: 0.5 * ln((1+x)/(1-x)). Requires |x| < 1.
// For |x| > 1 returns NaN (IEEE semantics);
// atanh(1.0) == +inf and atanh(-1.0) == -inf (native, ln 0/inf).
// atanh(0.0) == 0.0. Complexity: O(1), libm ln.
pub fn atanh(x: Float64) -> Float64 {
  if x > 1.0 || x < -1.0 { return 0.0 / 0.0; }
  return 0.5 * math.ln((1.0 + x) / (1.0 - x));
}

// Hyperbolic sine via the pure exp series (math.exponential.exp_pure), no
// libm. sinh_pure(0.0) == 0.0. Complexity: O(exp_pure).
pub fn sinh_pure(x: Float64) -> Float64 {
  return (math.exponential.exp_pure(x) - math.exponential.exp_pure(-x)) / 2.0;
}

// Hyperbolic cosine via the pure exp series, no libm. cosh_pure(0.0) == 1.0.
// Complexity: O(exp_pure).
pub fn cosh_pure(x: Float64) -> Float64 {
  return (math.exponential.exp_pure(x) + math.exponential.exp_pure(-x)) / 2.0;
}

// Hyperbolic tangent via pure sinh/cosh series, no libm. Saturates to +-1.0
// for |x| > 20. tanh_pure(0.0) == 0.0. Complexity: O(exp_pure).
pub fn tanh_pure(x: Float64) -> Float64 {
  if x > 20.0 { return 1.0; }
  if x < -20.0 { return -1.0; }
  var sh = sinh_pure(x);
  var ch = cosh_pure(x);
  return sh / ch;
}
