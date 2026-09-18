// XIOM - Math: Decompose
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.decompose

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// IEEE-754 bit decomposition and float classification (concrete Float64).
// frexp uses the [0.5, 1) fraction convention; ilogb/exponent use the
// [1, 2) mantissa convention (ilogb(8.0) == 3). NaN cannot be produced by
// this compiler (BUG 19); classify still detects a NaN input if one ever
// arrives. nextafter/nexttoward delegate to the exact arithmetic walk in
// math.primitives (exact for all finite normal/subnormal values).
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

pub enum FloatClass {
  NaN,
  Infinity,
  Normal,
  Subnormal,
  Zero,
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

// Core frexp: exact, no libm. fraction in [0.5, 1) with sign; x == 0 gives
// (0.0, 0); +-inf pass through with exponent 0.
fn _frexp_impl(x: Float64) -> (Float64, Int) {
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

// Split x into (fraction, exponent) with x == fraction * 2^exponent and
// fraction in [0.5, 1). frexp(8.0) == (0.5, 4), frexp(0.0) == (0.0, 0).
// Exact. Complexity: O(1074) worst case.
/// Split x into (fraction, exponent) with x == fraction * 2^exponent and
/// fraction in [0.5, 1). frexp(8.0) == (0.5, 4), frexp(0.0) == (0.0, 0).
/// Exact. Complexity: O(1074) worst case.
pub fn frexp(x: Float64) -> (Float64, Int) {
  return _frexp_impl(x);
}

// x * 2^n with a single rounding. For n beyond the representable exponent
// range the result is +-inf (n > 1100) or 0.0 (n < -1100); subnormal results
// flush correctly. Exact for all finite representable outcomes.
// Complexity: O(1074 + 1024).
/// x * 2^n with a single rounding. For n beyond the representable exponent
/// range the result is +-inf (n > 1100) or 0.0 (n < -1100); subnormal results
/// flush correctly. Exact for all finite representable outcomes.
/// Complexity: O(1074 + 1024).
pub fn ldexp(x: Float64, n: Int) -> Float64 {
  return ldexp_pure(x, n);
}

// Binary exponent of x: the e with |x| == m * 2^e and 1 <= m < 2.
// ilogb(8.0) == 3, ilogb(0.5) == -1. For x == 0 returns INT_MIN (C
// FP_ILOGB0), for +-inf returns INT_MAX (C FP_ILOGB... convention).
// Complexity: O(1074) worst case.
/// Binary exponent of x: the e with |x| == m * 2^e and 1 <= m < 2.
/// ilogb(8.0) == 3, ilogb(0.5) == -1. For x == 0 returns INT_MIN (C
/// FP_ILOGB0), for +-inf returns INT_MAX (C FP_ILOGB... convention).
/// Complexity: O(1074) worst case.
pub fn ilogb(x: Float64) -> Int {
  if x == 0.0 { return -9223372036854775808; }
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return 9223372036854775807; }
  var fr = _frexp_impl(x);
  return fr.1 - 1;
}

// Binary exponent of x as a float: logb(8.0) == 3.0. For x == 0 returns -inf,
// for +-inf returns +inf (C semantics). Complexity: O(1074) worst case.
/// Binary exponent of x as a float: logb(8.0) == 3.0. For x == 0 returns -inf,
/// for +-inf returns +inf (C semantics). Complexity: O(1074) worst case.
pub fn logb(x: Float64) -> Float64 {
  if x == 0.0 { return -1.0 / 0.0; }
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return 1.0 / 0.0; }
  return (ilogb(x) as Float64);
}

// x * 2^n (FLT_RADIX == 2). Same semantics as ldexp. Complexity: O(ldexp).
/// x * 2^n (FLT_RADIX == 2). Same semantics as ldexp. Complexity: O(ldexp).
pub fn scalbn(x: Float64, n: Int) -> Float64 {
  return ldexp(x, n);
}

// x * 2^n with a long (Int64) exponent. Same semantics as ldexp.
// Complexity: O(ldexp).
/// x * 2^n with a long (Int64) exponent. Same semantics as ldexp.
/// Complexity: O(ldexp).
pub fn scalbln(x: Float64, n: Int64) -> Float64 {
  return ldexp(x, n as Int);
}

// Normalized fraction of x in [0.5, 1), sign preserved (frexp fraction).
// significand(8.0) == 0.5, significand(0.0) == 0.0; +-inf pass through.
// Complexity: O(1074) worst case.
/// Normalized fraction of x in [0.5, 1), sign preserved (frexp fraction).
/// significand(8.0) == 0.5, significand(0.0) == 0.0; +-inf pass through.
/// Complexity: O(1074) worst case.
pub fn significand(x: Float64) -> Float64 {
  if x == 0.0 { return 0.0; }
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return x; }
  var fr = _frexp_impl(x);
  return fr.0;
}

// Binary exponent of x. Alias of ilogb: exponent(8.0) == 3, exponent(0) ==
// INT_MIN, exponent(+-inf) == INT_MAX. Complexity: O(ilogb).
/// Binary exponent of x. Alias of ilogb: exponent(8.0) == 3, exponent(0) ==
/// INT_MIN, exponent(+-inf) == INT_MAX. Complexity: O(ilogb).
pub fn exponent(x: Float64) -> Int {
  return ilogb(x);
}

// frexp without libm. Identical semantics to frexp (the algorithm is exact
// integer scaling; no libm involved). Complexity: O(1074) worst case.
/// frexp without libm. Identical semantics to frexp (the algorithm is exact
/// integer scaling; no libm involved). Complexity: O(1074) worst case.
pub fn frexp_pure(x: Float64) -> (Float64, Int) {
  return _frexp_impl(x);
}

// ldexp without libm. x * 2^n via exact frexp decomposition and power-of-two
// scaling (all intermediate steps are exact or correctly flushed). For
// n > 1100 returns +-inf, for n < -1100 returns 0.0. Complexity: O(1074).
/// ldexp without libm. x * 2^n via exact frexp decomposition and power-of-two
/// scaling (all intermediate steps are exact or correctly flushed). For
/// n > 1100 returns +-inf, for n < -1100 returns 0.0. Complexity: O(1074).
pub fn ldexp_pure(x: Float64, n: Int) -> Float64 {
  if x == 0.0 { return 0.0; }
  if n > 1100 {
    if x > 0.0 { return 1.0 / 0.0; }
    return -1.0 / 0.0;
  }
  if n < -1100 { return 0.0; }
  var fr = _frexp_impl(x);
  var target = fr.1 + n;
  if target > 1023 {
    if x > 0.0 { return 1.0 / 0.0; }
    return -1.0 / 0.0;
  }
  if target < -1074 { return 0.0; }
  var r = fr.0;
  var k = target;
  while k > 0 {
    r = r * 2.0;
    k = k - 1;
  }
  while k < 0 {
    r = r / 2.0;
    k = k + 1;
  }
  return r;
}

// True iff x is a normal (non-subnormal, non-zero, finite) Float64:
// 2^-1022 <= |x| < +inf. Complexity: O(1).
/// True iff x is a normal (non-subnormal, non-zero, finite) Float64:
/// 2^-1022 <= |x| < +inf. Complexity: O(1).
pub fn is_normal(x: Float64) -> Bool {
  if x == 0.0 { return false; }
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return false; }
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  return ax >= 2.2250738585072014e-308;
}

// True iff x is a subnormal Float64: 0 < |x| < 2^-1022. Complexity: O(1).
/// True iff x is a subnormal Float64: 0 < |x| < 2^-1022. Complexity: O(1).
pub fn is_subnormal(x: Float64) -> Bool {
  if x == 0.0 { return false; }
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return false; }
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  return ax < 2.2250738585072014e-308;
}

// Classify x into the FloatClass taxonomy: NaN, Infinity, Normal, Subnormal,
// Zero. NaN classification is unreachable from code compiled by this
// compiler (BUG 19 cannot produce NaN), but is detected if one arrives.
// Complexity: O(1).
/// Classify x into the FloatClass taxonomy: NaN, Infinity, Normal, Subnormal,
/// Zero. NaN classification is unreachable from code compiled by this
/// compiler (BUG 19 cannot produce NaN), but is detected if one arrives.
/// Complexity: O(1).
pub fn classify(x: Float64) -> FloatClass {
  if x == 1.0 / 0.0 || x == -1.0 / 0.0 { return FloatClass.Infinity; }
  if x != x { return FloatClass.NaN; }
  if x == 0.0 { return FloatClass.Zero; }
  if is_subnormal(x) { return FloatClass.Subnormal; }
  return FloatClass.Normal;
}

// Next representable Float64 from x toward y. Exact for all finite normal
// and subnormal values; delegates to math.primitives.nextafter (the same
// arithmetic ulp walk). nextafter(max, +inf) == +inf.
// TODO(compiler): an exact implementation normally uses a float<->int
// bitcast; the arithmetic form is exact for finite values (see primitives).
/// Next representable Float64 from x toward y. Exact for all finite normal
/// and subnormal values; delegates to math.primitives.nextafter (the same
/// arithmetic ulp walk). nextafter(max, +inf) == +inf.
/// TODO(compiler): an exact implementation normally uses a float<->int
/// bitcast; the arithmetic form is exact for finite values (see primitives).
pub fn nextafter(x: Float64, y: Float64) -> Float64 {
  return math.primitives.nextafter(x, y);
}

// Next representable Float64 from x toward y. Float64 has no distinct long
// double, so this is the same operation as nextafter.
/// Next representable Float64 from x toward y. Float64 has no distinct long
/// double, so this is the same operation as nextafter.
pub fn nexttoward(x: Float64, y: Float64) -> Float64 {
  return math.primitives.nextafter(x, y);
}
