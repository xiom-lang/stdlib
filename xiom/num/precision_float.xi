// XIOM - Num: Precision Float
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.num.precision_float

// Depends on: none

// ============================================================================
// Arbitrary-precision floating-point operations as thin wrappers over the
// BigFloat implementation. The reference implementation lives in
// num/bigfloat.xi (module xiom.num.bigfloat); these thin wrappers present the
// frozen xiom.num.precision_float API (by-value operands, Option on fallible
// paths -- division by zero, negative roots, non-positive logs, out-of-domain
// asin/acos). All fallible inputs are validated before dispatch so the
// underlying requires clauses are never violated.
// ============================================================================

use xiom.num.bigfloat;
use xiom.math;

/// Representation invariant: no negative zero and a consistent sign bit.
fn _wf(b: &BigFloat) -> Bool {
  return (b.significand.negative == false) && ((b.significand.digits.len() != 0) || (b.sign == false)) && ((b.sign == false) || (b.significand.digits.len() > 0));
}

/// |a| compared with 1 (for the asin/acos domain).
fn _cmp_abs_one(a: &BigFloat) -> Int {
  var one = bigfloat.bigfloat_one();
  var aa = bigfloat.bigfloat_abs(a);
  return bigfloat.bigfloat_compare(&aa, &one);
}

/// Constructs a BigFloat from a native float. NaN/inf are not representable
/// (the underlying implementation requires finite inputs; do not pass them).
/// Complexity: O(1).
pub fn bigfloat_from_float(x: Float64) -> BigFloat
  requires: !xiom.math.is_nan(x)
  requires: !xiom.math.is_inf(x)
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_from_float(x);
}

/// Parses a decimal string ("3.14", "-1e-10", ".5"). None on invalid input.
/// Complexity: O(n).
pub fn bigfloat_from_str(s: Str) -> Option[BigFloat]
  ensures: (s == "") => (result is None)
{
  var r = bigfloat.bigfloat_from_str(s);
  match r {
    Ok(v) => { return Some(v); }
    Err(_) => { return None; }
  }
}

/// Decimal string representation at the current precision. Complexity: O(n).
pub fn bigfloat_to_str(b: BigFloat) -> Str
  ensures: result != ""
{
  return bigfloat.bigfloat_to_str(&b);
}

/// Re-rounds b to p significant digits (round-half-to-even), returning a
/// fresh value with precision p. p < 1 is clamped to 1 (documented).
/// Complexity: O(n).
pub fn bigfloat_with_precision(b: BigFloat, p: Int) -> BigFloat
  ensures: _wf(&result)
{
  var pp = p;
  if pp < 1 { pp = 1; }
  var s = bigfloat.bigfloat_to_str_prec(&b, pp);
  var r = bigfloat.bigfloat_from_str(s);
  match r {
    Ok(v) => { return v; }
    Err(_) => { return b; }
  }
}

/// Sum a + b, rounded to max(a.precision, b.precision). Complexity: O(n).
pub fn bigfloat_add(a: BigFloat, b: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_add(&a, &b);
}

/// Difference a - b. Complexity: O(n).
pub fn bigfloat_sub(a: BigFloat, b: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_sub(&a, &b);
}

/// Product a * b. Complexity: O(n^2).
pub fn bigfloat_mul(a: BigFloat, b: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_mul(&a, &b);
}

/// Quotient a / b. None when b is zero. Complexity: O(n^2).
pub fn bigfloat_div(a: BigFloat, b: BigFloat) -> Option[BigFloat]
  ensures: (result is None) => bigfloat.bigfloat_is_zero(&b)
  ensures: (result is Some) => !bigfloat.bigfloat_is_zero(&b)
{
  if bigfloat.bigfloat_is_zero(&b) { return None; }
  return Some(bigfloat.bigfloat_div(&a, &b));
}

/// Negation. Complexity: O(1).
pub fn bigfloat_neg(a: BigFloat) -> BigFloat
  ensures: result.significand.negative == false
{
  return bigfloat.bigfloat_neg(&a);
}

/// Absolute value. Complexity: O(1).
pub fn bigfloat_abs(a: BigFloat) -> BigFloat
  ensures: (result.sign == false) && (result.significand.negative == false)
{
  return bigfloat.bigfloat_abs(&a);
}

/// Square root. None when a is negative (Newton on the significand).
/// Complexity: O(prec^2).
pub fn bigfloat_sqrt(a: BigFloat) -> Option[BigFloat]
  ensures: (result is None) => bigfloat.bigfloat_is_negative(&a)
  ensures: (result is Some) => !bigfloat.bigfloat_is_negative(&a)
{
  if bigfloat.bigfloat_is_negative(&a) { return None; }
  return Some(bigfloat.bigfloat_sqrt(&a));
}

/// Cube root. Complexity: O(prec^2).
pub fn bigfloat_cbrt(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_cbrt(&a);
}

/// Exponential function. Complexity: O(prec^2) series.
pub fn bigfloat_exp(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_exp(&a);
}

/// Natural logarithm. None when a is not positive (zero or negative).
/// Complexity: O(prec^2).
pub fn bigfloat_ln(a: BigFloat) -> Option[BigFloat]
  ensures: (result is None) => (bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a))
  ensures: (result is Some) => (!bigfloat.bigfloat_is_zero(&a) && !bigfloat.bigfloat_is_negative(&a))
{
  if bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a) {
    return None;
  }
  return Some(bigfloat.bigfloat_ln(&a));
}

/// Base-10 logarithm. None when a is not positive.
/// Complexity: O(prec^2).
pub fn bigfloat_log10(a: BigFloat) -> Option[BigFloat]
  ensures: (result is None) => (bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a))
  ensures: (result is Some) => (!bigfloat.bigfloat_is_zero(&a) && !bigfloat.bigfloat_is_negative(&a))
{
  if bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a) {
    return None;
  }
  return Some(bigfloat.bigfloat_log10(&a));
}

/// Base-2 logarithm. None when a is not positive.
/// Complexity: O(prec^2).
pub fn bigfloat_log2(a: BigFloat) -> Option[BigFloat]
  ensures: (result is None) => (bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a))
  ensures: (result is Some) => (!bigfloat.bigfloat_is_zero(&a) && !bigfloat.bigfloat_is_negative(&a))
{
  if bigfloat.bigfloat_is_zero(&a) || bigfloat.bigfloat_is_negative(&a) {
    return None;
  }
  return Some(bigfloat.bigfloat_log2(&a));
}

/// Exponentiation base^exp for arbitrary BigFloat exponent (log + exp).
/// Complexity: O(prec^2).
pub fn bigfloat_pow(base: BigFloat, exp: BigFloat) -> BigFloat
  requires: !bigfloat.bigfloat_is_negative(&base)
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_pow_bf(&base, &exp);
}

/// Sine. Complexity: O(prec^2) series.
pub fn bigfloat_sin(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_sin(&a);
}

/// Cosine. Complexity: O(prec^2) series.
pub fn bigfloat_cos(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_cos(&a);
}

/// Tangent. Complexity: O(prec^2).
pub fn bigfloat_tan(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_tan(&a);
}

/// Arcsine. None when a is outside [-1, 1]. Complexity: O(prec^2).
pub fn bigfloat_asin(a: BigFloat) -> Option[BigFloat]
  ensures: (result is Some) => _cmp_abs_one(&a) <= 0
  ensures: (result is None) => _cmp_abs_one(&a) > 0
{
  var one = bigfloat.bigfloat_one();
  var n_one = bigfloat.bigfloat_neg(&one);
  if bigfloat.bigfloat_compare(&a, &one) > 0 { return None; }
  if bigfloat.bigfloat_compare(&a, &n_one) < 0 { return None; }
  return Some(bigfloat.bigfloat_asin(&a));
}

/// Arccosine. None when a is outside [-1, 1]. Complexity: O(prec^2).
pub fn bigfloat_acos(a: BigFloat) -> Option[BigFloat]
  ensures: (result is Some) => _cmp_abs_one(&a) <= 0
  ensures: (result is None) => _cmp_abs_one(&a) > 0
{
  var one = bigfloat.bigfloat_one();
  var n_one = bigfloat.bigfloat_neg(&one);
  if bigfloat.bigfloat_compare(&a, &one) > 0 { return None; }
  if bigfloat.bigfloat_compare(&a, &n_one) < 0 { return None; }
  return Some(bigfloat.bigfloat_acos(&a));
}

/// Arctangent. Complexity: O(prec^2).
pub fn bigfloat_atan(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_atan(&a);
}

/// Four-quadrant arctangent of y/x. Complexity: O(prec^2).
pub fn bigfloat_atan2(y: BigFloat, x: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_atan2(&y, &x);
}

/// Hyperbolic sine. Complexity: O(prec^2).
pub fn bigfloat_sinh(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_sinh(&a);
}

/// Hyperbolic cosine. Complexity: O(prec^2).
pub fn bigfloat_cosh(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_cosh(&a);
}

/// Hyperbolic tangent. Complexity: O(prec^2).
pub fn bigfloat_tanh(a: BigFloat) -> BigFloat
  ensures: _wf(&result)
{
  return bigfloat.bigfloat_tanh(&a);
}

/// Pi to p significant digits (p < 1 clamped to 1). Complexity: O(prec^2).
pub fn bigfloat_pi(p: Int) -> BigFloat
  ensures: _wf(&result)
{
  var pp = p;
  if pp < 1 { pp = 1; }
  return bigfloat.bigfloat_pi_with_precision(pp);
}

/// Euler's number e to p significant digits (p < 1 clamped to 1).
/// Complexity: O(prec^2).
pub fn bigfloat_e(p: Int) -> BigFloat
  ensures: _wf(&result)
{
  var pp = p;
  if pp < 1 { pp = 1; }
  return bigfloat.bigfloat_e_with_precision(pp);
}

/// Three-way comparison: -1, 0, or 1 ordering a vs b. Complexity: O(n).
pub fn bigfloat_compare(a: BigFloat, b: BigFloat) -> Int
  ensures: (result >= -1) && (result <= 1)
{
  return bigfloat.bigfloat_compare(&a, &b);
}
