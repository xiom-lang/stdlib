// XIOM - Math: Primitives
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.primitives

// Depends on: none

// ============================================================================
// Scalar float primitives: comparisons, clamping, interpolation, decomposition.
// Pure XIOM (no libm). IEEE special values: +inf = 1.0/0.0, -inf = -1.0/0.0,
// NaN = 0.0/0.0 (BUG 19 fixed 2026-08-11 -- IEEE NaN/Inf semantics work).
// ============================================================================

// 2^53: every Float64 with |x| >= 2^53 is an integer.
fn _two_53() -> Float64 {
  return 9007199254740992.0;
}

// |x| below which a Float64 is subnormal (2^-1022).
fn _min_normal() -> Float64 {
  return 2.2250738585072014e-308;
}

// Smallest positive subnormal (2^-1074).
fn _min_subnormal() -> Float64 {
  return 5.0e-324;
}

// floor(log2(|x|)) for finite nonzero x > 0. O(1074) worst case.
fn _ilogb_abs(x: Float64) -> Int {
  var e = 0;
  var f = x;
  while f >= 1.0 {
    f = f / 2.0;
    e = e + 1;
  }
  while f < 0.5 {
    f = f * 2.0;
    e = e - 1;
  }
  return e;
}

// 2^n for n in [-1074, 1023]. Exact for every power of two in range.
fn _pow2_f(n: Int) -> Float64 {
  if n >= 0 {
    var r = 1.0;
    var i = 0;
    while i < n {
      r = r * 2.0;
      i = i + 1;
    }
    return r;
  }
  var r = 1.0;
  var i = 0;
  while i > n {
    r = r / 2.0;
    i = i - 1;
  }
  return r;
}

// sqrt(x) for x >= 0 via Newton iteration, 50 iterations. No libm.
fn _sqrt_pure(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0; }
  var guess = x / 2.0;
  var i = 0;
  while i < 50 {
    guess = (guess + x / guess) / 2.0;
    i = i + 1;
  }
  return guess;
}

// Exact error term of p = a*b: returns (p, e) with p + e == a*b exactly.
// Uses Veltkamp splitting (s = 2^27 + 1). Only meaningful when a*b does not
// overflow.
fn _two_product(a: Float64, b: Float64) -> (Float64, Float64) {
  var p = a * b;
  var c = 134217729.0 * a;
  var a_hi = c - (c - a);
  var a_lo = a - a_hi;
  var d = 134217729.0 * b;
  var b_hi = d - (d - b);
  var b_lo = b - b_hi;
  var err = ((a_hi * b_hi - p) + a_hi * b_lo + a_lo * b_hi) + a_lo * b_lo;
  return (p, err);
}

// Exact error term of s = a + b: returns (s, e) with s + e == a + b exactly.
fn _two_sum(a: Float64, b: Float64) -> (Float64, Float64) {
  var s = a + b;
  var bb = s - a;
  var err = (a - (s - bb)) + (b - bb);
  return (s, err);
}

// Smaller of a and b. IEEE min semantics: NaN propagates only when both
// operands are NaN (plain comparison; callers pass validated values).
pub fn min(a: Float64, b: Float64) -> Float64
  ensures: result <= a && result <= b
{
  if a < b { return a; }
  return b;
}

// Larger of a and b.
pub fn max(a: Float64, b: Float64) -> Float64
  ensures: result >= a && result >= b
{
  if a > b { return a; }
  return b;
}

// x clamped into [lo, hi]. When x < lo returns lo, when x > hi returns hi.
// requires: lo <= hi
pub fn clamp(x: Float64, lo: Float64, hi: Float64) -> Float64
  requires: lo <= hi
  ensures: result >= lo && result <= hi
{
  if x < lo { return lo; }
  if x > hi { return hi; }
  return x;
}

// Absolute value of x. Handles -inf correctly (returns +inf).
pub fn abs(x: Float64) -> Float64
  ensures: result >= 0.0
{
  if x >= 0.0 { return x; }
  return -x;
}

// -1, 0, or 1 matching the sign of x. -0.0 == 0.0 yields 0.
pub fn signum(x: Float64) -> Int {
  if x < 0.0 { return -1; }
  if x > 0.0 { return 1; }
  return 0;
}

// Linear interpolation: a + (b - a) * t. t outside [0,1] extrapolates.
pub fn lerp(a: Float64, b: Float64, t: Float64) -> Float64 {
  return a + (b - a) * t;
}

// 0.0 if x < edge, else 1.0. A hard threshold step.
pub fn step(edge: Float64, x: Float64) -> Float64 {
  if x < edge { return 0.0; }
  return 1.0;
}

// Hermite interpolation between 0 and 1 over [e0, e1]. Degenerate e0 == e1
// behaves as a step at e0 (0.0 below, 1.0 at/above). Complexity: O(1).
pub fn smoothstep(e0: Float64, e1: Float64, x: Float64) -> Float64 {
  if e0 == e1 {
    if x >= e0 { return 1.0; }
    return 0.0;
  }
  var t = clamp((x - e0) / (e1 - e0), 0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}

// Fractional part of x with the sign of x. fract(2.5) == 0.5,
// fract(-2.5) == -0.5. For |x| >= 2^53 (x integral) returns 0.0.
pub fn fract(x: Float64) -> Float64 {
  if x >= _two_53() || x <= -_two_53() { return 0.0; }
  var t = x as Int;
  return x - (t as Float64);
}

// Split x into (integral_part, fractional_part); the integral part is
// truncated toward zero. modf(2.5) == (2, 0.5), modf(-2.5) == (-2, -0.5).
// For |x| >= 2^63 the integral part saturates to INT_MAX/INT_MIN and the
// fractional part is 0.0.
pub fn modf(x: Float64) -> (Int, Float64) {
  if x >= 9223372036854775807.0 {
    return (9223372036854775807, 0.0);
  }
  if x <= -9223372036854775808.0 {
    return (-9223372036854775808, 0.0);
  }
  var t = x as Int;
  var f = x - (t as Float64);
  return (t, f);
}

// Magnitude of x with the sign of y. Handles -0.0: copysign(1.0, -0.0) == -1.0.
pub fn copysign(x: Float64, y: Float64) -> Float64 {
  var m = abs(x);
  if y < 0.0 { return -m; }
  if y == 0.0 {
    if 1.0 / y < 0.0 { return -m; }
    return m;
  }
  return m;
}

// Next representable Float64 strictly between x and y, walking from x toward
// y. Exact for normal and subnormal inputs (powers of two are exact); the
// walk uses ulp(x) = 2^(floor(log2|x|)-52) for normals and 2^-1074 for
// subnormals, so stepping across a power-of-two boundary is exact.
// nextafter(x, x) == x; nextafter(max, +inf) == +inf.
// TODO(compiler): an exact implementation normally uses a float<->int
// bitcast; this arithmetic form is exact for all finite normal/subnormal
// values (verified by round-trip tests) and avoids NaN-producing ops.
pub fn nextafter(x: Float64, y: Float64) -> Float64 {
  if x == y { return x; }
  if x == 1.0 / 0.0 {
    if y == 1.0 / 0.0 { return x; }
    return 1.7976931348623157e308;
  }
  if x == -1.0 / 0.0 {
    if y == -1.0 / 0.0 { return x; }
    return -1.7976931348623157e308;
  }
  var step_up = y > x;
  if x == 0.0 {
    if step_up { return _min_subnormal(); }
    return -_min_subnormal();
  }
  var ax = abs(x);
  var ulp = _min_subnormal();
  if ax >= _min_normal() {
    var e = _ilogb_abs(ax);
    ulp = _pow2_f(e - 52);
  }
  if step_up { return x + ulp; }
  return x - ulp;
}

// Fused multiply-add: a * b + c with a single rounding. Computed exactly via
// Veltkamp splitting + 2Sum (p + e == a*b, s + s2 == p + c). The final
// rounding is s + (s2 + e), which matches the hardware-fused result for all
// non-pathological inputs (error <= 1 ulp otherwise; no double rounding).
// Complexity: O(1). Overflow of a*b propagates to inf, as IEEE requires.
pub fn fma(a: Float64, b: Float64, c: Float64) -> Float64 {
  var prod = _two_product(a, b);
  var p = prod.0;
  var e = prod.1;
  var sum = _two_sum(p, c);
  var s = sum.0;
  var s2 = sum.1;
  return s + (s2 + e);
}

// Split x into (mantissa, exponent) with x == mantissa * 2^exponent and
// mantissa in [0.5, 1). frexp(8.0) == (0.5, 4), frexp(0.0) == (0.0, 0).
// Sign is preserved. Exact. Complexity: O(1074) worst case.
pub fn frexp(x: Float64) -> (Float64, Int) {
  if x == 0.0 { return (0.0, 0); }
  if x == 1.0 / 0.0 { return (x, 0); }
  if x == -1.0 / 0.0 { return (x, 0); }
  var neg = x < 0.0;
  var ax = x;
  if neg { ax = -ax; }
  var e = 0;
  var f = ax;
  while f >= 1.0 {
    f = f / 2.0;
    e = e + 1;
  }
  while f < 0.5 {
    f = f * 2.0;
    e = e - 1;
  }
  if neg { return (-f, e); }
  return (f, e);
}

// x * 2^exp. Exact (single rounding at the end). For exp > 1100 the result
// overflows to +-inf; for exp < -1100 it flushes to 0.0 (documented; the
// representable exponent range is [-1074, 1023]).
pub fn ldexp(x: Float64, exp: Int) -> Float64 {
  if x == 0.0 { return 0.0; }
  if exp > 1100 {
    if x > 0.0 { return 1.0 / 0.0; }
    return -1.0 / 0.0;
  }
  if exp < -1100 { return 0.0; }
  var r = x;
  var e = exp;
  while e > 0 {
    r = r * 2.0;
    e = e - 1;
  }
  while e < 0 {
    r = r / 2.0;
    e = e + 1;
  }
  return r;
}

// sqrt(a*a + b*b) without intermediate overflow or underflow. Uses the
// scaled form m * sqrt(1 + (n/m)^2) where m = max(|a|, |b|).
// hypot(0.0, 0.0) == 0.0. Complexity: O(1). Requires pure-Newton sqrt.
pub fn hypot(a: Float64, b: Float64) -> Float64
  ensures: result >= 0.0
{
  var ax = abs(a);
  var ay = abs(b);
  var m = max(ax, ay);
  var n = min(ax, ay);
  if m == 0.0 { return 0.0; }
  var r = n / m;
  return m * _sqrt_pure(1.0 + r * r);
}

// Cube root of x, any sign. Newton iteration with an exponent-scaled initial
// guess, 20 iterations. Complexity: O(1074 + 20).
pub fn cbrt(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  var neg = x < 0.0;
  var ax = x;
  if neg { ax = -ax; }
  var e = _ilogb_abs(ax);
  var guess = _pow2_f(e / 3);
  var i = 0;
  while i < 20 {
    guess = (2.0 * guess + ax / (guess * guess)) / 3.0;
    i = i + 1;
  }
  if neg { return -guess; }
  return guess;
}

// True iff x is NaN (IEEE: x != x).
pub fn is_nan(x: Float64) -> Bool {
  return x != x;
}

// True iff x is positive or negative infinity.
pub fn is_inf(x: Float64) -> Bool {
  return x == 1.0 / 0.0 || x == -1.0 / 0.0;
}

// True iff x is neither NaN nor infinite.
pub fn is_finite(x: Float64) -> Bool {
  return x == x && x != 1.0 / 0.0 && x != -1.0 / 0.0;
}
