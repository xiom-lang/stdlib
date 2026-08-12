// XIOM - Math: Trigonometry
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.trigonometry

// Depends on: xiom.math

// ============================================================================
// Circular (angle) trigonometric functions. The libm-backed wrappers
// (math.sin/math.cos/math.tan) are used for the core functions; the
// sin_pure/cos_pure/tan_pure fallbacks are implemented as normalized Taylor
// series (no libm). Domain errors return IEEE NaN (0.0/0.0); poles return
// +-inf. Complexity is documented per function.
// ============================================================================

use xiom.math;

const _PI: Float64 = 3.141592653589793;
const _TAU: Float64 = 6.283185307179586;

// Normalize an angle into [-pi, pi].
fn _norm(x: Float64) -> Float64 {
  var r = x;
  while r > _PI {
    r = r - _TAU;
  }
  while r < -_PI {
    r = r + _TAU;
  }
  return r;
}

// Sine of x (radians). NaN/infinite inputs propagate. Complexity: O(1).
pub fn sin(x: Float64) -> Float64 {
  return math.sin(x);
}

// Cosine of x (radians). Complexity: O(1).
pub fn cos(x: Float64) -> Float64 {
  return math.cos(x);
}

// Tangent of x (radians); a pole (cos(x) == 0) yields +-infinity. Complexity: O(1).
pub fn tan(x: Float64) -> Float64 {
  return math.tan(x);
}

// Cosecant of x: 1/sin(x); a zero sine yields +inf (documented). Complexity: O(1).
pub fn csc(x: Float64) -> Float64 {
  var s = math.sin(x);
  if s == 0.0 { return 1.0 / 0.0; }
  return 1.0 / s;
}

// Secant of x: 1/cos(x); a zero cosine yields +inf (documented). Complexity: O(1).
pub fn sec(x: Float64) -> Float64 {
  var c = math.cos(x);
  if c == 0.0 { return 1.0 / 0.0; }
  return 1.0 / c;
}

// Cotangent of x: cos(x)/sin(x); a zero sine yields +inf (documented). Complexity: O(1).
pub fn cot(x: Float64) -> Float64 {
  var c = math.cos(x);
  var s = math.sin(x);
  if s == 0.0 { return 1.0 / 0.0; }
  return c / s;
}

// Pair (sin(x), cos(x)) computed once. Complexity: O(1).
pub fn sincos(x: Float64) -> (Float64, Float64) {
  var s = math.sin(x);
  var c = math.cos(x);
  return (s, c);
}

// Pair (sin(pi*x), cos(pi*x)). Complexity: O(1).
pub fn sincospi(x: Float64) -> (Float64, Float64) {
  var px = _PI * x;
  var s = math.sin(px);
  var c = math.cos(px);
  return (s, c);
}

// Sine via the normalized Taylor series (no libm), 10 terms. Complexity: O(10).
pub fn sin_pure(x: Float64) -> Float64 {
  var a = _norm(x);
  var result = a;
  var term = a;
  var i = 1;
  while i <= 10 {
    var den = (2 * i) * (2 * i + 1) as Float64;
    term = -term * a * a / den;
    result = result + term;
    i = i + 1;
  }
  return result;
}

// Cosine via the normalized Taylor series (no libm), 10 terms. Complexity: O(10).
pub fn cos_pure(x: Float64) -> Float64 {
  var a = _norm(x);
  var result = 1.0;
  var term = 1.0;
  var i = 1;
  while i <= 10 {
    var den = (2 * i - 1) * (2 * i) as Float64;
    term = -term * a * a / den;
    result = result + term;
    i = i + 1;
  }
  return result;
}

// Tangent via pure sin/cos. Complexity: O(10).
pub fn tan_pure(x: Float64) -> Float64 {
  var s = sin_pure(x);
  var c = cos_pure(x);
  if c == 0.0 { return 1.0 / 0.0; }
  return s / c;
}

// sin(pi*x), accurate for large x by reducing x into [0, 2) first.
// Complexity: O(1).
pub fn sinpi(x: Float64) -> Float64 {
  if x != x { return x; }
  if x == 0.0 { return 0.0; }
  var r = x;
  while r >= 2.0 {
    r = r - 2.0;
  }
  while r < 0.0 {
    r = r + 2.0;
  }
  return math.sin(_PI * r);
}

// cos(pi*x), accurate for large x by reducing x into [0, 2) first.
// Complexity: O(1).
pub fn cospi(x: Float64) -> Float64 {
  if x != x { return x; }
  var r = x;
  while r >= 2.0 {
    r = r - 2.0;
  }
  while r < 0.0 {
    r = r + 2.0;
  }
  return math.cos(_PI * r);
}

// tan(pi*x), accurate for large x by reducing x into [0, 2) first. A pole
// yields +-infinity. Complexity: O(1).
pub fn tanpi(x: Float64) -> Float64 {
  if x != x { return x; }
  var r = x;
  while r >= 2.0 {
    r = r - 2.0;
  }
  while r < 0.0 {
    r = r + 2.0;
  }
  return math.tan(_PI * r);
}
