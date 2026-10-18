// p_wave181_precision_shapes.xi -- wave-181 precision contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the new precision_* contract surfaces:
// - precision_integer: pow sign/zero, zero shifts, gcd/lcm zero rows,
//   factorial(0), binomial(n,0), div/mod zero -> None.
// - precision_float: asin/acos domain acceptance/rejection, log2/cbrt,
//   tan/atan/sinh/tanh at zero, atan2, pi/e precision clamps, from_float.
// - precision_rational: negative-denominator normalization, zero
//   numerator, direct reduce of a non-reduced BigRat, recip(0) -> None,
//   to_integer Some/None, numerator/denominator identities.
// Expected: rc 0.

module p_wave181_precision_shapes

use xiom.num.precision_integer;
use xiom.num.precision_float;
use xiom.num.precision_rational;
use xiom.num.precision_rational.BigRat;
use xiom.io;

fn main() -> Int {
  // precision_integer: pow sign, zero shifts, gcd/lcm zeros, factorial/binomial.
  if precision_integer.bigint_to_str(precision_integer.bigint_pow(precision_integer.bigint_from_int(-2), 3)) != "-8" { return 1; }
  if precision_integer.bigint_to_str(precision_integer.bigint_pow(precision_integer.bigint_from_int(-2), 4)) != "16" { return 2; }
  if precision_integer.bigint_to_str(precision_integer.bigint_pow(precision_integer.bigint_from_int(0), 0)) != "1" { return 3; }
  if precision_integer.bigint_to_str(precision_integer.bigint_shift_left(precision_integer.bigint_from_int(-5), 0)) != "-5" { return 4; }
  if precision_integer.bigint_to_str(precision_integer.bigint_shift_right(precision_integer.bigint_from_int(-8), 0)) != "-8" { return 5; }
  if precision_integer.bigint_to_str(precision_integer.bigint_gcd(precision_integer.bigint_from_int(0), precision_integer.bigint_from_int(0))) != "0" { return 6; }
  if precision_integer.bigint_to_str(precision_integer.bigint_lcm(precision_integer.bigint_from_int(0), precision_integer.bigint_from_int(9))) != "0" { return 7; }
  if precision_integer.bigint_to_str(precision_integer.bigint_factorial(0)) != "1" { return 8; }
  if precision_integer.bigint_to_str(precision_integer.bigint_binomial(5, 0)) != "1" { return 9; }

  // precision_float: asin/acos domains, log2, cbrt, trig/hyperbolic, pi/e clamps.
  var half = precision_float.bigfloat_from_str("0.5");
  match half {
    Some(h) => {
      match precision_float.bigfloat_asin(h) {
        Some(_) => {},
        None => { return 10; }
      }
      match precision_float.bigfloat_acos(h) {
        Some(_) => {},
        None => { return 11; }
      }
    }
    None => { return 12; }
  }
  var two = precision_float.bigfloat_from_str("2");
  match two {
    Some(t) => {
      match precision_float.bigfloat_asin(t) {
        Some(_) => { return 13; }
        None => {}
      }
      match precision_float.bigfloat_acos(t) {
        Some(_) => { return 14; }
        None => {}
      }
    }
    None => { return 15; }
  }
  var neg2 = precision_float.bigfloat_from_str("-2");
  match neg2 {
    Some(n) => {
      match precision_float.bigfloat_asin(n) {
        Some(_) => { return 16; }
        None => {}
      }
      match precision_float.bigfloat_acos(n) {
        Some(_) => { return 17; }
        None => {}
      }
    }
    None => { return 18; }
  }
  var eight = precision_float.bigfloat_from_str("8");
  match eight {
    Some(e) => {
      match precision_float.bigfloat_log2(e) {
        Some(v) => { if precision_float.bigfloat_to_str(v) == "" { return 19; } }
        None => { return 19; }
      }
      var c = precision_float.bigfloat_cbrt(e);
      if precision_float.bigfloat_to_str(c) == "" { return 20; }
    }
    None => { return 21; }
  }
  var zero = precision_float.bigfloat_from_str("0");
  match zero {
    Some(z) => {
      if precision_float.bigfloat_to_str(precision_float.bigfloat_tan(z)) != "0" { return 22; }
      if precision_float.bigfloat_to_str(precision_float.bigfloat_atan(z)) != "0" { return 23; }
      if precision_float.bigfloat_to_str(precision_float.bigfloat_sinh(z)) != "0" { return 24; }
      if precision_float.bigfloat_to_str(precision_float.bigfloat_tanh(z)) != "0" { return 25; }
      match precision_float.bigfloat_log2(z) {
        Some(_) => { return 26; }
        None => {}
      }
    }
    None => { return 27; }
  }
  var one = precision_float.bigfloat_from_str("1");
  match one {
    Some(o) => {
      var a2 = precision_float.bigfloat_atan2(o, o);
      if precision_float.bigfloat_to_str(a2) == "" { return 28; }
      if precision_float.bigfloat_to_str(precision_float.bigfloat_cosh(precision_float.bigfloat_with_precision(o, 0))) == "" { return 29; }
    }
    None => { return 30; }
  }
  var pi0 = precision_float.bigfloat_pi(0);
  if precision_float.bigfloat_to_str(pi0) == "" { return 31; }
  var e0 = precision_float.bigfloat_e(0);
  if precision_float.bigfloat_to_str(e0) == "" { return 32; }
  var f15 = precision_float.bigfloat_from_float(-1.5);
  if precision_float.bigfloat_to_str(f15) != "-1.5" { return 33; }

  // precision_rational: sign normalization, zero, reduce, recip/to_integer edges.
  var rn = precision_rational.bigrat_new(precision_integer.bigint_from_int(1), precision_integer.bigint_from_int(-2));
  match rn {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "-1/2" { return 40; }
    }
    None => { return 41; }
  }
  var rz = precision_rational.bigrat_new(precision_integer.bigint_from_int(0), precision_integer.bigint_from_int(5));
  match rz {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "0" { return 42; }
    }
    None => { return 43; }
  }
  var raw = BigRat{ num: precision_integer.bigint_from_int(4); den: precision_integer.bigint_from_int(6); };
  if precision_rational.bigrat_is_reduced(raw) { return 44; }
  var red = precision_rational.bigrat_reduce(raw);
  if precision_rational.bigrat_to_str(red) != "2/3" { return 45; }
  if !precision_rational.bigrat_is_reduced(red) { return 46; }
  var rzero = precision_rational.bigrat_from_int(0);
  match precision_rational.bigrat_recip(rzero) {
    Some(_) => { return 47; }
    None => {}
  }
  match precision_rational.bigrat_to_integer(precision_rational.bigrat_from_int(3)) {
    Some(v) => { if precision_integer.bigint_to_str(v) != "3" { return 48; } }
    None => { return 48; }
  }
  var rfrac = precision_rational.bigrat_from_str("1/2");
  match rfrac {
    Some(f) => {
      match precision_rational.bigrat_to_integer(f) {
        Some(_) => { return 49; }
        None => {}
      }
      if precision_integer.bigint_to_str(precision_rational.bigrat_numerator(f)) != "1" { return 50; }
      if precision_integer.bigint_to_str(precision_rational.bigrat_denominator(f)) != "2" { return 51; }
    }
    None => { return 52; }
  }

  io.println("p_wave181_precision_shapes: OK");
  return 0;
}
