// XIOM - Math: Exponential
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.exponential

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Exponential, logarithm and power functions (concrete Float64).
// Hot primitives (exp/ln/pow/log2/log10) delegate to libm via math.*; the
// accurate-for-small-x variants expm1/log1p use series expansions; the
// *_pure variants delegate to the proven pure series implementations in
// math.xi (math.exp_pure etc.), which are libm-free. Domain errors that
// would produce NaN (ln(x<=0), log1p(x<=-1), sqrt of negatives) return a
// documented -1.0 sentinel because BUG 19 cannot construct NaN.
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.
// ============================================================================

// e^x. Returns +inf for x > 700 (overflow) and 0.0 for x < -745
// (underflow) via libm. Complexity: O(1), libm exp.
pub fn exp(x: Float64) -> Float64 {
  return math.exp(x);
}

// 2^x. Complexity: O(1), libm pow.
pub fn exp2(x: Float64) -> Float64 {
  return math.pow(2.0, x);
}

// 10^x. Complexity: O(1), libm pow.
pub fn exp10(x: Float64) -> Float64 {
  return math.pow(10.0, x);
}

// e^x - 1, accurate for small x. Uses the Taylor series x + x^2/2! + ...
// for |x| <= 1e-4 (where exp(x) - 1.0 suffers catastrophic cancellation)
// and libm exp - 1.0 otherwise. Returns -1.0 for x < -700 and +inf for
// x > 700. Complexity: O(20) series terms / O(1) libm.
pub fn expm1(x: Float64) -> Float64 {
  if x > 700.0 { return 1.0 / 0.0; }
  if x < -700.0 { return -1.0; }
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  if ax > 1e-4 { return math.exp(x) - 1.0; }
  var sum = x;
  var term = x;
  var i = 1;
  while i < 20 {
    term = term * x / ((i + 1) as Float64);
    sum = sum + term;
    i = i + 1;
  }
  return sum;
}

// Natural logarithm of x. Requires x > 0. For x <= 0 returns NaN
// (IEEE semantics; BUG 19 fixed -- NaN ops now work).
pub fn ln(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.ln(x);
}

// Base-2 logarithm of x. Requires x > 0. For x <= 0 returns NaN
// (see ln). Complexity: O(1), libm log2.
pub fn log2(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.log2(x);
}

// Base-10 logarithm of x. Requires x > 0. For x <= 0 returns NaN
// (see ln). Complexity: O(1), libm log10.
pub fn log10(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.log10(x);
}

// ln(1 + x), accurate for small x. Requires x > -1. Uses the alternating
// series x - x^2/2 + x^3/3 - ... for |x| <= 1e-4 and libm ln(1+x) otherwise.
// log1p(-1.0) == -inf (ln 0), log1p(x < -1) returns NaN (IEEE semantics).
pub fn log1p(x: Float64) -> Float64 {
  if x < -1.0 { return 0.0 / 0.0; }
  var ax = x;
  if ax < 0.0 { ax = -ax; }
  if ax > 1e-4 { return math.ln(1.0 + x); }
  var sum = 0.0;
  var term = x;
  var i = 1;
  while i < 30 {
    if i % 2 == 1 {
      sum = sum + term / (i as Float64);
    } else {
      sum = sum - term / (i as Float64);
    }
    term = term * x;
    i = i + 1;
  }
  return sum;
}

// ln(1 + x), alias of log1p. See log1p for semantics and domain handling.
pub fn ln_1_plus(x: Float64) -> Float64 {
  return log1p(x);
}

// base^exp. Uses libm pow; negative bases require an integral exponent
// (libm semantics). For a negative base with a non-integral exponent
// returns NaN (IEEE semantics). Complexity: O(1), libm pow.
pub fn pow(base: Float64, exp: Float64) -> Float64 {
  if base < 0.0 {
    if exp != math.floor(exp) { return 0.0 / 0.0; }
  }
  return math.pow(base, exp);
}

// base raised to an integer power via binary exponentiation (square-and-
// multiply). pow_int(2, 10) == 1024, pow_int(2, -2) == 0.25. 0^0 == 1.0;
// 0^negative == +inf; base^INT_MIN is handled by magnitude (|base| < 1 -> 0,
// == 1 -> 1, > 1 -> +inf). Complexity: O(log |exp|) multiplications.
pub fn pow_int(base: Float64, exp: Int) -> Float64 {
  if exp == 0 { return 1.0; }
  if base == 0.0 {
    if exp > 0 { return 0.0; }
    return 1.0 / 0.0;
  }
  if exp == -9223372036854775808 {
    var b = base;
    if b < 0.0 { b = -b; }
    if b == 1.0 { return 1.0; }
    if b < 1.0 { return 0.0; }
    return 1.0 / 0.0;
  }
  var neg = false;
  var e = exp;
  if e < 0 {
    neg = true;
    e = -e;
  }
  var result = 1.0;
  var b = base;
  while e > 0 {
    if e % 2 == 1 {
      result = result * b;
    }
    b = b * b;
    e = e / 2;
  }
  if neg { return 1.0 / result; }
  return result;
}

// base^exp for a float exponent. See pow for semantics and domain handling.
// Complexity: O(1), libm pow.
pub fn pow_float(base: Float64, exp: Float64) -> Float64 {
  if base < 0.0 {
    if exp != math.floor(exp) { return 0.0 / 0.0; }
  }
  return math.pow(base, exp);
}

// sqrt(base)^exp. Requires base >= 0. For base < 0 returns NaN (IEEE).
// Complexity: O(1), libm.
pub fn sqrt_power(base: Float64, exp: Float64) -> Float64
  ensures: result >= 0.0 || result != result
{
  if base < 0.0 { return 0.0 / 0.0; }
  return math.pow(math.sqrt(base), exp);
}

// e^x via the pure range-reduced Taylor series (math.exp_pure), no libm.
// Returns +inf for x > 700 and 0.0 for x < -700. Complexity: O(25 + log).
pub fn exp_pure(x: Float64) -> Float64 {
  return math.exp_pure(x);
}

// Natural logarithm via the pure atanh series (math.ln_pure), no libm.
// Requires x > 0; for x <= 0 returns NaN (IEEE semantics).
pub fn ln_pure(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.ln_pure(x);
}

// Base-2 logarithm via the pure series (math.log2_pure), no libm. Requires
// x > 0; for x <= 0 returns NaN (IEEE semantics).
pub fn log2_pure(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.log2_pure(x);
}

// Base-10 logarithm via the pure series (math.log10_pure), no libm.
// Requires x > 0; for x <= 0 returns NaN (IEEE semantics).
pub fn log10_pure(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  return math.log10_pure(x);
}

// base^exp via the pure exp/ln series (math.pow_pure), no libm. Negative
// bases are handled before delegation because math.pow_pure declares
// `requires: base >= 0.0 || exp integral` (runtime-enforced in this
// compiler); a negative base with a non-integral exponent returns NaN
// (IEEE semantics). Complexity: O(ln + exp).
pub fn pow_pure(base: Float64, exp: Float64) -> Float64 {
  if base < 0.0 {
    if exp != math.floor(exp) { return 0.0 / 0.0; }
  }
  return math.pow_pure(base, exp);
}
