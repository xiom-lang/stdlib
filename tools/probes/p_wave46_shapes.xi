// p_wave46_shapes.xi -- wave 46 verification: xiom.bigfloat core clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (canonical form:
// non-negative significand; empty significand implies sign false; sign true
// implies non-empty significand). KATs go through bigfloat_to_str.
// Returns 0 when every case holds.

module p_wave46_shapes

use xiom.num.bigfloat;

fn eqv(a: &BigFloat, s: Str) -> Bool {
  return bigfloat.bigfloat_to_str(a) == s;
}

fn main() -> Int {
  if !eqv(&bigfloat.bigfloat_zero(), "0") { return 1; }
  if !eqv(&bigfloat.bigfloat_one(), "1") { return 2; }
  if !eqv(&bigfloat.bigfloat_two(), "2") { return 3; }
  if !eqv(&bigfloat.bigfloat_ten(), "10") { return 4; }
  if !eqv(&bigfloat.bigfloat_half(), "0.5") { return 5; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_pi()).len() < 10 { return 6; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_e()).len() < 10 { return 7; }

  var m42 = bigfloat.bigfloat_from_int(-42);
  if !eqv(&m42, "-42") { return 8; }
  var seven = bigfloat.bigfloat_from_int(7);
  if !eqv(&seven, "7") { return 9; }
  if !eqv(&bigfloat.bigfloat_with_precision(5, 30), "5") { return 10; }
  if bigfloat.bigfloat_precision(&bigfloat.bigfloat_with_precision(5, 30)) != 30 { return 11; }

  var one = bigfloat.bigfloat_one();
  var two = bigfloat.bigfloat_two();
  if !eqv(&bigfloat.bigfloat_add(&one, &two), "3") { return 12; }
  if !eqv(&bigfloat.bigfloat_sub(&one, &two), "-1") { return 13; }
  if !eqv(&bigfloat.bigfloat_mul(&two, &bigfloat.bigfloat_from_int(3)), "6") { return 14; }
  if !eqv(&bigfloat.bigfloat_div(&one, &two), "0.5") { return 15; }
  if !eqv(&bigfloat.bigfloat_neg(&two), "-2") { return 16; }
  if !eqv(&bigfloat.bigfloat_abs(&m42), "42") { return 17; }
  if !eqv(&bigfloat.bigfloat_inv(&two), "0.5") { return 18; }
  if !eqv(&bigfloat.bigfloat_sqrt(&bigfloat.bigfloat_from_int(4)), "2") { return 19; }
  if !eqv(&bigfloat.bigfloat_pow(&two, 10), "1024") { return 20; }
  var f125 = bigfloat.bigfloat_from_str("1.25").unwrap();
  if !eqv(&bigfloat.bigfloat_fract(&f125), "0.25") { return 21; }
  var mode = bigfloat.bigfloat_get_round_mode();
  var r = bigfloat.bigfloat_with_rounding(&bigfloat.bigfloat_pi(), mode, 5);
  if bigfloat.bigfloat_to_str(&r) != "3.1416" { return 22; }

  if !bigfloat.bigfloat_is_zero(&bigfloat.bigfloat_zero()) { return 23; }
  if bigfloat.bigfloat_is_zero(&one) { return 24; }
  if !bigfloat.bigfloat_is_negative(&m42) { return 25; }
  if !bigfloat.bigfloat_is_one(&one) { return 26; }
  if bigfloat.bigfloat_sign(&m42) != -1 { return 27; }
  if bigfloat.bigfloat_compare(&one, &two) != -1 { return 28; }
  if bigfloat.bigfloat_compare(&two, &two) != 0 { return 29; }
  if bigfloat.bigfloat_compare(&two, &one) != 1 { return 30; }
  if bigfloat.bigfloat_to_str(&one) == "" { return 31; }

  if bigfloat.bigfloat_from_str("").is_ok { return 32; }
  var f15 = bigfloat.bigfloat_from_str("1.5");
  if !f15.is_ok { return 33; }
  var f15v = f15.unwrap();
  if !eqv(&f15v, "1.5") { return 34; }
  if bigfloat.bigfloat_to_float64(&bigfloat.bigfloat_zero()).is_some() == false { return 35; }
  if bigfloat.bigfloat_to_float64(&bigfloat.bigfloat_zero()).unwrap() != 0.0 { return 36; }

  return 0;
}
