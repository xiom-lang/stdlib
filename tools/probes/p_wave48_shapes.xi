// p_wave48_shapes.xi -- wave 48 verification: xiom.num.bigfloat remainder.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (canonical form,
// non-negative significand, bigint-canonical to_bigint, non-empty strings,
// zero-fits integer conversions). Returns 0 when every case holds.

module p_wave48_shapes

use xiom.num.bigfloat;
use xiom.bigint;

fn eqv(a: &BigFloat, s: Str) -> Bool {
  return bigfloat.bigfloat_to_str(a) == s;
}

fn main() -> Int {
  var zero = bigfloat.bigfloat_zero();
  var one = bigfloat.bigfloat_one();

  // from_float
  if !eqv(&bigfloat.bigfloat_from_float(0.5), "0.5") { return 1; }
  if !eqv(&bigfloat.bigfloat_from_float(-3.25), "-3.25") { return 2; }
  if !eqv(&bigfloat.bigfloat_from_float(0.0), "0") { return 3; }

  // to_str_prec
  var fpi = bigfloat.bigfloat_from_str("3.14159").unwrap();
  if bigfloat.bigfloat_to_str_prec(&fpi, 3) == "" { return 4; }
  if bigfloat.bigfloat_to_str_prec(&zero, 3) == "" { return 5; }

  // to_bigint
  var t15 = bigfloat.bigfloat_from_str("1.5").unwrap();
  var b15 = bigfloat.bigfloat_to_bigint(&t15);
  if bigint.bigint_to_str(&b15) != "1" { return 6; }
  var tn15 = bigfloat.bigfloat_from_str("-1.5").unwrap();
  var bn15 = bigfloat.bigfloat_to_bigint(&tn15);
  if bigint.bigint_to_str(&bn15) != "-1" { return 7; }
  if bigfloat.bigfloat_to_bigint(&zero).digits.len() != 0 { return 8; }

  // from_ratio
  if !eqv(&bigfloat.bigfloat_from_ratio(1, 4), "0.25") { return 9; }
  if !eqv(&bigfloat.bigfloat_from_ratio(-3, 4), "-0.75") { return 10; }

  // pow10
  if !eqv(&bigfloat.bigfloat_pow10(&bigfloat.bigfloat_two(), 3), "2000") { return 11; }
  if !eqv(&bigfloat.bigfloat_pow10(&one, -2), "0.01") { return 12; }

  // integer conversions
  var f19 = bigfloat.bigfloat_from_str("1.9").unwrap();
  if bigfloat.bigfloat_floor_int(&f19).unwrap() != 1 { return 13; }
  if bigfloat.bigfloat_ceil_int(&f19).unwrap() != 2 { return 14; }
  if bigfloat.bigfloat_round_int(&f19).unwrap() != 2 { return 15; }
  if bigfloat.bigfloat_trunc_int(&f19).unwrap() != 1 { return 16; }
  if bigfloat.bigfloat_floor_int(&zero).unwrap() != 0 { return 17; }
  if bigfloat.bigfloat_ceil_int(&zero).unwrap() != 0 { return 18; }
  if bigfloat.bigfloat_round_int(&zero).unwrap() != 0 { return 19; }
  if bigfloat.bigfloat_trunc_int(&zero).unwrap() != 0 { return 20; }
  var fm19 = bigfloat.bigfloat_from_str("-1.9").unwrap();
  if bigfloat.bigfloat_floor_int(&fm19).unwrap() != -2 { return 21; }
  if bigfloat.bigfloat_ceil_int(&fm19).unwrap() != -1 { return 22; }
  if bigfloat.bigfloat_trunc_int(&fm19).unwrap() != -1 { return 23; }

  return 0;
}
