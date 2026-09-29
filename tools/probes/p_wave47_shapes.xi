// p_wave47_shapes.xi -- wave 47 verification: xiom.num.bigfloat transcendentals.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the canonical-form ensures clauses on the
// _finish-normalized transcendental results. KATs use bigfloat_to_float64
// where a numeric comparison is clearer. Returns 0 when every case holds.

module p_wave47_shapes

use xiom.num.bigfloat;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn fl(a: &BigFloat) -> Float64 {
  return bigfloat.bigfloat_to_float64(a).unwrap();
}

fn main() -> Int {
  var zero = bigfloat.bigfloat_zero();
  var one = bigfloat.bigfloat_one();
  var two = bigfloat.bigfloat_two();
  var pi = bigfloat.bigfloat_pi();
  var halfpi = bigfloat.bigfloat_div(&pi, &two);

  // exp / ln / logs
  if !near(fl(&bigfloat.bigfloat_exp(&zero)), 1.0, 1e-12) { return 1; }
  if !near(fl(&bigfloat.bigfloat_exp(&one)), 2.718281828459045, 1e-12) { return 2; }
  if !near(fl(&bigfloat.bigfloat_ln(&bigfloat.bigfloat_e())), 1.0, 1e-12) { return 3; }
  if !near(fl(&bigfloat.bigfloat_log10(&bigfloat.bigfloat_from_int(100))), 2.0, 1e-12) { return 4; }
  if !near(fl(&bigfloat.bigfloat_log2(&bigfloat.bigfloat_from_int(8))), 3.0, 1e-12) { return 5; }
  if !near(fl(&bigfloat.bigfloat_exp2(&bigfloat.bigfloat_ten())), 1024.0, 1e-9) { return 6; }

  // trig
  if !near(fl(&bigfloat.bigfloat_sin(&zero)), 0.0, 1e-12) { return 7; }
  if !near(fl(&bigfloat.bigfloat_cos(&zero)), 1.0, 1e-12) { return 8; }
  if !near(fl(&bigfloat.bigfloat_tan(&zero)), 0.0, 1e-12) { return 9; }
  if !near(fl(&bigfloat.bigfloat_sin(&halfpi)), 1.0, 1e-12) { return 10; }
  if !near(fl(&bigfloat.bigfloat_atan(&one)), 0.7853981633974483, 1e-12) { return 11; }
  if !near(fl(&bigfloat.bigfloat_atan2(&one, &one)), 0.7853981633974483, 1e-12) { return 12; }

  // powers / roots
  if !near(fl(&bigfloat.bigfloat_pow_bf(&two, &bigfloat.bigfloat_ten())), 1024.0, 1e-9) { return 13; }
  if !near(fl(&bigfloat.bigfloat_cbrt(&bigfloat.bigfloat_from_int(27))), 3.0, 1e-12) { return 14; }
  if !near(fl(&bigfloat.bigfloat_hypot(&bigfloat.bigfloat_from_int(3), &bigfloat.bigfloat_from_int(4))), 5.0, 1e-12) { return 15; }
  if !near(fl(&bigfloat.bigfloat_sqrt(&bigfloat.bigfloat_from_int(2))), 1.4142135623730951, 1e-12) { return 16; }

  // hyperbolic + inverse
  if !near(fl(&bigfloat.bigfloat_sinh(&zero)), 0.0, 1e-12) { return 17; }
  if !near(fl(&bigfloat.bigfloat_cosh(&zero)), 1.0, 1e-12) { return 18; }
  if !near(fl(&bigfloat.bigfloat_tanh(&zero)), 0.0, 1e-12) { return 19; }
  if !near(fl(&bigfloat.bigfloat_asinh(&zero)), 0.0, 1e-12) { return 20; }
  if !near(fl(&bigfloat.bigfloat_atanh(&zero)), 0.0, 1e-12) { return 21; }
  if !near(fl(&bigfloat.bigfloat_acos(&one)), 0.0, 1e-12) { return 22; }
  if !near(fl(&bigfloat.bigfloat_acosh(&one)), 0.0, 1e-12) { return 23; }
  if !near(fl(&bigfloat.bigfloat_asin(&one)), 1.5707963267948966, 1e-12) { return 24; }

  // explicit precision / strings
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_pi_with_precision(20)).len() < 10 { return 25; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_e_with_precision(20)).len() < 10 { return 26; }
  if bigfloat.bigfloat_to_str_sci(&bigfloat.bigfloat_from_int(1234), 3) == "" { return 27; }

  return 0;
}
