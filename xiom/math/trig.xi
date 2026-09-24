// XIOM - Math: Trig
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.trig

// Depends on: xiom.math, xiom.math.hyperbolic
// ============================================================================
// Trigonometric and hyperbolic functions, radians/degrees conversion.
// ============================================================================

use xiom.math;
use xiom.math.hyperbolic;

// All circular functions delegate to the libm-backed xiom.math wrappers
// (math.sin/math.cos/...); the hyperbolic ones delegate to
// xiom.math.hyperbolic (composed from math.exp/math.ln/math.sqrt) and the
// inverse-hyperbolic asinh/acosh are composed here. Domain errors return NaN
// (IEEE semantics; BUG 19 fixed), never sentinel values.

/// Sine of x in radians. NaN and infinite inputs propagate. Complexity: O(1).
pub fn sin(x: Float64) -> Float64 {
  return math.sin(x);
}

/// Cosine of x in radians. NaN and infinite inputs propagate. Complexity: O(1).
pub fn cos(x: Float64) -> Float64 {
  return math.cos(x);
}

/// Tangent of x in radians; a pole (cos(x) == 0) yields +-infinity (IEEE).
/// Complexity: O(1).
pub fn tan(x: Float64) -> Float64 {
  return math.tan(x);
}

/// Arc sine of x in radians, result in [-pi/2, pi/2]. For x outside [-1, 1]
/// returns NaN (documented domain error). Complexity: O(1).
pub fn asin(x: Float64) -> Float64 {
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  return math.asin(x);
}

/// Arc cosine of x in radians, result in [0, pi]. For x outside [-1, 1]
/// returns NaN (documented domain error). Complexity: O(1).
pub fn acos(x: Float64) -> Float64 {
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  return math.acos(x);
}

/// Arc tangent of x in radians, result in (-pi/2, pi/2). Complexity: O(1).
pub fn atan(x: Float64) -> Float64 {
  return math.atan(x);
}

/// Four-quadrant arc tangent of y/x in radians. When both y and x are zero
/// returns NaN (documented; the angle is undefined there). Complexity: O(1).
pub fn atan2(y: Float64, x: Float64) -> Float64 {
  if y == 0.0 && x == 0.0 { return 0.0 / 0.0; }
  return math.atan2(y, x);
}

/// Hyperbolic sine of x: (exp(x) - exp(-x))/2. Large |x| propagates as +-
/// infinity. Complexity: O(1). Delegates to xiom.math.hyperbolic (the
/// pure-exp composition is gate-green there; the old inline-arithmetic stub
/// refreshed 2026-09-24).
pub fn sinh(x: Float64) -> Float64 {
  return hyperbolic.sinh(x);
}

/// Hyperbolic cosine of x: (exp(x) + exp(-x))/2. Complexity: O(1).
/// Delegates to xiom.math.hyperbolic.
pub fn cosh(x: Float64) -> Float64 {
  return hyperbolic.cosh(x);
}

/// Hyperbolic tangent of x: sinh(x)/cosh(x). Saturated to +-1 for |x| > 20 to
/// avoid a NaN from inf/inf at the exponent overflow boundary. Complexity: O(1).
/// Delegates to xiom.math.hyperbolic.
pub fn tanh(x: Float64) -> Float64 {
  return hyperbolic.tanh(x);
}

/// Inverse hyperbolic sine of x: ln(x + sqrt(x^2 + 1)). Well-defined for every
/// x. Complexity: O(1).
pub fn asinh(x: Float64) -> Float64 {
  var x2 = x * x;
  var s = math.sqrt(x2 + 1.0);
  var arg = x + s;
  return math.ln(arg);
}

/// Inverse hyperbolic cosine of x: ln(x + sqrt(x^2 - 1)). For x < 1 returns
/// NaN (documented domain error). Complexity: O(1).
pub fn acosh(x: Float64) -> Float64 {
  if x < 1.0 { return 0.0 / 0.0; }
  var x2 = x * x;
  var s = math.sqrt(x2 - 1.0);
  var arg = x + s;
  return math.ln(arg);
}

/// Inverse hyperbolic tangent of x: ln((1+x)/(1-x))/2. For |x| >= 1 returns
/// NaN (documented domain error; the function is undefined at the poles).
/// Complexity: O(1). Delegates to xiom.math.hyperbolic.
pub fn atanh(x: Float64) -> Float64 {
  return hyperbolic.atanh(x);
}

/// Secant of x: 1/cos(x). A pole (cos(x) == 0) yields +-infinity (IEEE).
/// Complexity: O(1).
pub fn sec(x: Float64) -> Float64 {
  var c = math.cos(x);
  return 1.0 / c;
}

/// Cosecant of x: 1/sin(x). A pole (sin(x) == 0) yields +-infinity (IEEE).
/// Complexity: O(1).
pub fn csc(x: Float64) -> Float64 {
  var s = math.sin(x);
  return 1.0 / s;
}

/// Cotangent of x: cos(x)/sin(x). A pole (sin(x) == 0) yields +-infinity
/// (IEEE). Complexity: O(1).
pub fn cot(x: Float64) -> Float64 {
  var c = math.cos(x);
  var s = math.sin(x);
  return c / s;
}

/// Convert radians to degrees: x * 180/pi. Complexity: O(1).
pub fn degrees(x: Float64) -> Float64 {
  var pi = math.constants.PI;
  return x * 180.0 / pi;
}

/// Convert degrees to radians: x * pi/180. Complexity: O(1).
pub fn radians(x: Float64) -> Float64 {
  var pi = math.constants.PI;
  return x * pi / 180.0;
}

/// Sine of x in degrees. Complexity: O(1).
pub fn sin_deg(x: Float64) -> Float64 {
  var r = radians(x);
  return math.sin(r);
}

/// Cosine of x in degrees. Complexity: O(1).
pub fn cos_deg(x: Float64) -> Float64 {
  var r = radians(x);
  return math.cos(r);
}

/// Tangent of x in degrees. Complexity: O(1).
pub fn tan_deg(x: Float64) -> Float64 {
  var r = radians(x);
  return math.tan(r);
}
