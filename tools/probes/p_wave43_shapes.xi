// p_wave43_shapes.xi -- wave 43 verification: num.float + num.convert +
// num.base + precision_integer + precision_rational clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses. Cases: exact float
// bits (v0.64.0/m194; was fallback 0 before), mantissa/exponent,
// classification, nextafter/ulp; base58/62, ascii85, roman; radix conversions and digits; bigint wrappers and BigRat
// construction/arithmetic/compare/float. Returns 0 when every case holds.

module p_wave43_shapes

use xiom.math;
use xiom.num.float;
use xiom.num.convert;
use xiom.num.base;
use xiom.num.precision_integer;
use xiom.num.precision_rational;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn is_nan(x: Float64) -> Bool {
  return x != x;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;
  var inf = 1.0 / 0.0;

  // ---- num.float ----
  if float.float_bits(1.5) != 4609434218613702656 { return 1; }
  if !(float.bits_to_float(7) > 0.0) { return 2; }
  if float.float_mantissa(1.0) != 4503599627370496 { return 3; }
  if float.float_mantissa(0.0) != 0 { return 4; }
  if float.float_mantissa(nan) != 0 { return 5; }
  if float.float_exponent(1.0) != 0 { return 6; }
  if float.float_exponent(8.0) != 3 { return 7; }
  if float.float_exponent(0.5) != -1 { return 8; }
  if float.float_exponent(0.0) != 0 { return 9; }
  if !float.float_is_subnormal(1e-310) { return 10; }
  if float.float_is_subnormal(1.0) { return 11; }
  if !float.float_is_nan(nan) { return 12; }
  if float.float_is_nan(1.0) { return 13; }
  if !float.float_is_infinite(inf) { return 14; }
  if !float.float_is_infinite(0.0 - inf) { return 15; }
  if float.float_is_infinite(1.0) { return 16; }
  if !(float.float_next_up(1.0) > 1.0) { return 17; }
  if float.float_next_up(inf) != inf { return 18; }
  if !(float.float_next_down(1.0) < 1.0) { return 19; }
  if !near(float.float_ulp(1.0), 2.220446049250313e-16, 1e-30) { return 20; }
  if float.float_ulp(0.0) <= 0.0 { return 21; }
  if !is_nan(float.float_ulp(nan)) { return 22; }
  if float.float_classify(nan) != "nan" { return 23; }
  if float.float_classify(inf) != "inf" { return 24; }
  if float.float_classify(0.0 - inf) != "-inf" { return 25; }
  if float.float_classify(0.0) != "zero" { return 26; }
  if float.float_classify(1.0) != "normal" { return 27; }
  if float.float_classify(1e-310) != "subnormal" { return 28; }

  // ---- num.convert ----
  if convert.to_base58(0) != "1" { return 29; }
  if convert.to_base58(-1) != "-2" { return 30; }
  if convert.from_base58("").is_some() { return 31; }
  if !convert.from_base58("1").is_some() { return 32; }
  if convert.to_base62(0) != "0" { return 33; }
  if convert.from_base62("").is_some() { return 34; }
  var emptyb = Vec[UInt8].new();
  if convert.to_ascii85(&emptyb) != "" { return 35; }
  if !convert.from_ascii85("").is_some() { return 36; }
  if convert.to_roman(0).is_some() { return 37; }
  if !convert.to_roman(4).is_some() { return 38; }
  if convert.from_roman("").is_some() { return 39; }
  if convert.from_roman("IV").unwrap() != 4 { return 40; }

  // ---- num.base ----
  if base.to_base(0, 10) != "0" { return 41; }
  if base.to_base(5, 1) != "" { return 42; }
  if base.to_base(255, 16) != "ff" { return 43; }
  if !base.from_base("10", 2).is_ok { return 44; }
  if base.from_base("10", 40).is_ok { return 45; }
  if base.from_base("", 10).is_ok { return 46; }
  if base.to_base_float(inf, 10, 2) != "inf" { return 47; }
  if base.to_base_float(1.5, 1, 2) != "" { return 48; }
  if base.to_base_float(2.5, 10, 1) != "2.5" { return 49; }
  if !near(base.from_base_float("1.5", 10).unwrap(), 1.5, 1e-9) { return 50; }
  if base.from_base_float("", 10).is_ok { return 51; }
  if base.from_base_float("z", 10).is_ok { return 52; }
  var d5 = base.digits_of(5, 2);
  if d5.len() != 3 { return 53; }
  if d5[0] != 1 { return 54; }
  if d5[1] != 0 { return 55; }
  if d5[2] != 1 { return 56; }
  if base.digits_of(0, 10).len() != 1 { return 57; }
  if base.digits_of(5, 1).len() != 0 { return 58; }
  if base.from_digits(&d5, 2) != 5 { return 59; }
  if base.from_digits(&d5, 1) != 0 { return 60; }

  // ---- precision_integer ----
  if precision_integer.bigint_from_str("").is_some() { return 61; }
  var bi = precision_integer.bigint_from_str("-123");
  if !bi.is_some() { return 62; }
  var biv = bi.unwrap();
  if precision_integer.bigint_to_str(biv) != "-123" { return 63; }
  var b255 = precision_integer.bigint_from_str("255").unwrap();
  if precision_integer.bigint_to_hex(b255) != "ff" { return 64; }
  var b5 = precision_integer.bigint_from_str("5").unwrap();
  if precision_integer.bigint_to_bin(b5) != "101" { return 65; }
  var b8 = precision_integer.bigint_from_str("8").unwrap();
  if precision_integer.bigint_to_oct(b8) != "10" { return 66; }
  if precision_integer.bigint_compare(b5, b8) != -1 { return 67; }
  if precision_integer.bigint_compare(b8, b8) != 0 { return 68; }

  // ---- precision_rational ----
  if precision_rational.bigrat_from_str("").is_some() { return 69; }
  var half = precision_rational.bigrat_from_str("1/2");
  if !half.is_some() { return 70; }
  var hv = half.unwrap();
  if precision_rational.bigrat_to_str(hv) != "1/2" { return 71; }
  var third = precision_rational.bigrat_from_str("1/3").unwrap();
  var neg_half = precision_rational.bigrat_from_str("-0.5").unwrap();
  if precision_rational.bigrat_to_str(neg_half) != "-1/2" { return 72; }
  if precision_rational.bigrat_compare(hv, third) != 1 { return 73; }
  if precision_rational.bigrat_compare(third, third) != 0 { return 74; }
  if !near(precision_rational.bigrat_to_float(hv), 0.5, 1e-9) { return 75; }
  if !near(precision_rational.bigrat_to_float(neg_half), -0.5, 1e-9) { return 76; }
  var zero_rat = precision_rational.bigrat_from_int(0);
  if !near(precision_rational.bigrat_to_float(zero_rat), 0.0, 1e-9) { return 77; }
  if precision_rational.bigrat_to_str(precision_rational.bigrat_neg(hv)) != "-1/2" { return 78; }
  if precision_rational.bigrat_to_str(precision_rational.bigrat_abs(neg_half)) != "1/2" { return 79; }
  if precision_rational.bigrat_from_str("abc").is_some() { return 80; }

  return 0;
}
