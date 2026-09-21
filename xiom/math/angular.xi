// XIOM - Math: Angular
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.angular

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Angle unit conversion and angle arithmetic (concrete Float64).
// Angle normalization wraps into (-pi, pi] / (-180, 180] using a fractional
// part via math.floor, so no integer cast is needed and large inputs cannot
// overflow; accuracy degrades gracefully beyond |x| ~ 2^53/TAU.
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

/// Degrees to radians: deg * (pi/180).
pub fn to_radians(deg: Float64) -> Float64 {
  return deg * 0.017453292519943295;
}

/// Radians to degrees: rad * (180/pi).
pub fn to_degrees(rad: Float64) -> Float64 {
  return rad * 57.29577951308232;
}

/// Degrees to gradians (400 gradians per full circle): deg * (10/9).
pub fn to_gradians(deg: Float64) -> Float64 {
  return deg * 1.1111111111111112;
}

/// Gradians to degrees: grad * (9/10).
pub fn from_gradians(grad: Float64) -> Float64 {
  return grad * 0.9;
}

/// Degrees to milliradians (6400 mils per full circle): deg * (160/9).
pub fn to_mils(deg: Float64) -> Float64 {
  return deg * 17.77777777777778;
}

/// Milliradians to degrees: mil * (9/160).
pub fn from_mils(mil: Float64) -> Float64 {
  return mil * 0.05625;
}

/// Degrees to arcminutes: deg * 60.
pub fn to_arcmin(deg: Float64) -> Float64 {
  return deg * 60.0;
}

/// Arcminutes to degrees: arcmin / 60.
pub fn from_arcmin(arcmin: Float64) -> Float64 {
  return arcmin * 0.016666666666666666;
}

/// Degrees to arcseconds: deg * 3600.
pub fn to_arcsec(deg: Float64) -> Float64 {
  return deg * 3600.0;
}

/// Arcseconds to degrees: arcsec / 3600.
pub fn from_arcsec(arcsec: Float64) -> Float64 {
  return arcsec * 0.0002777777777777778;
}

/// Wrap radians into (-pi, pi]. normalize_angle(-pi) == pi,
/// normalize_angle(3*pi) == pi. Infinities pass through unchanged.
/// Complexity: O(1).
pub fn normalize_angle(rad: Float64) -> Float64 {
  if math.is_inf(rad) { return rad; }
  var pi = math.constants.PI;
  var tau = math.constants.TAU;
  var r = rad / tau;
  var f = r - math.floor(r);
  var angle = f * tau;
  if angle > pi { angle = angle - tau; }
  return angle;
}

/// Wrap degrees into (-180, 180]. normalize_angle_deg(-180) == 180,
/// normalize_angle_deg(540) == 180. Complexity: O(1).
pub fn normalize_angle_deg(deg: Float64) -> Float64 {
  if math.is_inf(deg) { return deg; }
  var r = deg / 360.0;
  var f = r - math.floor(r);
  var angle = f * 360.0;
  if angle > 180.0 { angle = angle - 360.0; }
  return angle;
}

/// Signed angular difference a - b (radians), wrapped into (-pi, pi].
/// angle_diff(pi/2, 0) == pi/2. Complexity: O(1).
pub fn angle_diff(a: Float64, b: Float64) -> Float64 {
  return normalize_angle(a - b);
}

/// Shortest-path linear interpolation between angles a and b at parameter t:
/// a + normalize_angle(b - a) * t. t in [0, 1] interpolates; angle_lerp(0, pi,
/// 0.5) == pi/2. Complexity: O(1).
pub fn angle_lerp(a: Float64, b: Float64, t: Float64) -> Float64 {
  return a + normalize_angle(b - a) * t;
}
