// XIOM - Math: Inverse Trig
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.inverse_trig

// Depends on: xiom.math

// ============================================================================
// Inverse circular trigonometric functions. NOTE: current implementation lives
// in math/trig.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

use xiom.math;

// The libm-backed variants delegate to xiom.math.trig; the *_pure variants
// delegate to the pure-XIOM series implementations in xiom.math (no libm).
// Domain errors return NaN (IEEE semantics).

// Arcsine of x in radians, result in [-pi/2, pi/2]. For x outside [-1, 1]
// returns NaN (documented domain error). Complexity: O(1).
/// Arcsine of x in radians, result in [-pi/2, pi/2]. For x outside [-1, 1]
/// returns NaN (documented domain error). Complexity: O(1).
pub fn asin(x: Float64) -> Float64 {
  return math.trig.asin(x);
}

// Arccosine of x in radians, result in [0, pi]. For x outside [-1, 1] returns
// NaN (documented domain error). Complexity: O(1).
/// Arccosine of x in radians, result in [0, pi]. For x outside [-1, 1] returns
/// NaN (documented domain error). Complexity: O(1).
pub fn acos(x: Float64) -> Float64 {
  return math.trig.acos(x);
}

// Arctangent of x in radians, result in (-pi/2, pi/2). Complexity: O(1).
/// Arctangent of x in radians, result in (-pi/2, pi/2). Complexity: O(1).
pub fn atan(x: Float64) -> Float64 {
  return math.trig.atan(x);
}

// Four-quadrant arctangent of y/x in radians. When both y and x are zero
// returns NaN (documented; the angle is undefined there). Complexity: O(1).
/// Four-quadrant arctangent of y/x in radians. When both y and x are zero
/// returns NaN (documented; the angle is undefined there). Complexity: O(1).
pub fn atan2(y: Float64, x: Float64) -> Float64 {
  return math.trig.atan2(y, x);
}

// Four-quadrant arctangent of y/x computed purely by series (xiom.math's
// pure atan, no libm). When both y and x are zero returns NaN (documented).
// Complexity: O(series terms).
/// Four-quadrant arctangent of y/x computed purely by series (xiom.math's
/// pure atan, no libm). When both y and x are zero returns NaN (documented).
/// Complexity: O(series terms).
pub fn atan2_pure(y: Float64, x: Float64) -> Float64 {
  if y == 0.0 && x == 0.0 { return 0.0 / 0.0; }
  return math.atan2_pure(y, x);
}

// Arcsine of x via the identity asin(x) = atan(x/sqrt(1-x^2)) using the pure
// atan/sqrt implementations (no libm). For x outside [-1, 1] returns NaN
// (documented domain error). Complexity: O(series terms).
/// Arcsine of x via the identity asin(x) = atan(x/sqrt(1-x^2)) using the pure
/// atan/sqrt implementations (no libm). For x outside [-1, 1] returns NaN
/// (documented domain error). Complexity: O(series terms).
pub fn asin_pure(x: Float64) -> Float64 {
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  return math.asin_pure(x);
}

// Arccosine of x via acos(x) = pi/2 - asin(x) on the pure asin (no libm).
// For x outside [-1, 1] returns NaN (documented domain error). Complexity:
// O(series terms).
/// Arccosine of x via acos(x) = pi/2 - asin(x) on the pure asin (no libm).
/// For x outside [-1, 1] returns NaN (documented domain error). Complexity:
/// O(series terms).
pub fn acos_pure(x: Float64) -> Float64 {
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  return math.acos_pure(x);
}

// Arctangent of x via the pure Taylor-series implementation (no libm). For
// |x| > 1 the reciprocal identity is applied. Complexity: O(series terms).
/// Arctangent of x via the pure Taylor-series implementation (no libm). For
/// |x| > 1 the reciprocal identity is applied. Complexity: O(series terms).
pub fn atan_pure(x: Float64) -> Float64 {
  return math.atan_pure(x);
}

// Four-quadrant arctangent of y/x with the result in radians. Alias of atan2.
// Complexity: O(1).
/// Four-quadrant arctangent of y/x with the result in radians. Alias of atan2.
/// Complexity: O(1).
pub fn atan2_radians(y: Float64, x: Float64) -> Float64
  requires: true  // extern atan2 call (T002 confinement)
{
  return atan2(y, x);
}

// Four-quadrant arctangent of y/x with the result in degrees. Complexity:
// O(1).
/// Four-quadrant arctangent of y/x with the result in degrees. Complexity:
/// O(1).
pub fn atan2_degrees(y: Float64, x: Float64) -> Float64
  requires: true  // extern atan2 call (T002 confinement)
{
  var r = atan2(y, x);
  var pi = math.constants.PI;
  return r * 180.0 / pi;
}

// Angle of the vector (x, y) in radians: alias of atan2. Complexity: O(1).
/// Angle of the vector (x, y) in radians: alias of atan2. Complexity: O(1).
pub fn arg(y: Float64, x: Float64) -> Float64
  requires: true  // extern atan2 call (T002 confinement)
{
  return atan2(y, x);
}
