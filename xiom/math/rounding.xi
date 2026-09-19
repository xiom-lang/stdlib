// XIOM - Math: Rounding
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.rounding

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Rounding and fraction-decomposition functions (concrete Float64).
// `round` rounds ties away from zero; `round_nearest` rounds ties to even.
// Pure variants implement floor/ceil/round/trunc/fract without libm.
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

/// Largest integer <= x. For |x| >= 2^63 the result is x itself (such values
/// are integers). Complexity: O(1), libm floor.
pub fn floor(x: Float64) -> Float64 {
  return math.floor(x);
}

/// Smallest integer >= x. For |x| >= 2^63 the result is x itself.
/// Complexity: O(1), libm ceil.
pub fn ceil(x: Float64) -> Float64 {
  return math.ceil(x);
}

/// Nearest integer, ties away from zero. round(2.5) == 3.0, round(-2.5) == -3.0.
/// For |x| >= 2^63 the result is x (already integral). Complexity: O(1).
pub fn round(x: Float64) -> Float64 {
  if x >= 0.0 { return math.floor(x + 0.5); }
  return math.ceil(x - 0.5);
}

/// Integer part of x, truncated toward zero. trunc(2.7) == 2.0,
/// trunc(-2.7) == -2.0. For |x| >= 2^63 the result is x. Complexity: O(1).
pub fn trunc(x: Float64) -> Float64 {
  if x >= 0.0 { return math.floor(x); }
  return math.ceil(x);
}

/// Fractional part of x: x - trunc(x), same sign as x. fract(2.5) == 0.5,
/// fract(-2.5) == -0.5. Complexity: O(1).
pub fn fract(x: Float64) -> Float64 {
  return x - trunc(x);
}

/// Split x into (fract, int): fract is the fractional part, int is the
/// integer part truncated toward zero. modf(2.5) == (0.5, 2.0).
/// Complexity: O(1).
pub fn modf(x: Float64) -> (Float64, Float64) {
  var i = trunc(x);
  return (x - i, i);
}

/// Largest integer <= x without libm. Pure-XIOM; see floor() for semantics.
/// Complexity: O(1).
pub fn floor_pure(x: Float64) -> Float64 {
  if x >= 9223372036854775808.0 || x <= -9223372036854775808.0 { return x; }
  var i = x as Int;
  if x >= 0.0 { return (i as Float64); }
  if (i as Float64) == x { return (i as Float64); }
  return ((i - 1) as Float64);
}

/// Smallest integer >= x without libm. Pure-XIOM; see ceil() for semantics.
/// Complexity: O(1).
pub fn ceil_pure(x: Float64) -> Float64 {
  if x >= 9223372036854775808.0 || x <= -9223372036854775808.0 { return x; }
  var i = x as Int;
  if x <= 0.0 { return (i as Float64); }
  if (i as Float64) == x { return (i as Float64); }
  return ((i + 1) as Float64);
}

/// Nearest integer, ties away from zero, without libm. See round().
/// Complexity: O(1).
pub fn round_pure(x: Float64) -> Float64 {
  if x >= 0.0 { return floor_pure(x + 0.5); }
  return ceil_pure(x - 0.5);
}

/// Integer part truncated toward zero, without libm. See trunc().
/// Complexity: O(1).
pub fn trunc_pure(x: Float64) -> Float64 {
  if x >= 9223372036854775808.0 || x <= -9223372036854775808.0 { return x; }
  var i = x as Int;
  return (i as Float64);
}

/// Fractional part of x without libm. See fract(). Complexity: O(1).
pub fn fract_pure(x: Float64) -> Float64 {
  return x - trunc_pure(x);
}

/// Integer part of x (truncated toward zero), as a Float64. Alias of trunc.
/// Complexity: O(1).
pub fn integer_part(x: Float64) -> Float64 {
  return trunc(x);
}

/// Fractional part of x. Alias of fract. Complexity: O(1).
pub fn frac_part(x: Float64) -> Float64 {
  return fract(x);
}

/// Round x to `places` decimal places, ties away from zero. Negative places
/// round to multiples of 10^|places| (round_to(1234.5, -2) == 1200.0).
/// Decimal rounding is subject to binary float representation error; the
/// result is the correctly rounded Float64 of x scaled by 10^places.
/// Complexity: O(1).
pub fn round_to(x: Float64, places: Int) -> Float64 {
  var factor = math.pow(10.0, places as Float64);
  return round(x * factor) / factor;
}

/// Round to the nearest integer, ties to even, returned as Int.
/// round_nearest(2.5) == 2, round_nearest(3.5) == 4, round_nearest(-2.5) == -2.
/// For |x| >= 2^63 the result saturates to INT_MAX/INT_MIN (documented;
/// the true rounded value is outside Int range). Complexity: O(1).
pub fn round_nearest(x: Float64) -> Int {
  if x >= 9223372036854775808.0 { return 9223372036854775807; }
  if x <= -9223372036854775808.0 { return -9223372036854775808; }
  var f = math.floor(x);
  var lo = f as Int;
  var diff = x - f;
  if diff < 0.5 { return lo; }
  if diff > 0.5 { return lo + 1; }
  if lo % 2 == 0 { return lo; }
  return lo + 1;
}
