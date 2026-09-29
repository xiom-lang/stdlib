// p_wave45_shapes.xi -- wave 45 verification: xiom.bigint remainder surface.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses. Covers parsing
// (empty/invalid -> Err), zero-fits conversions, parity/prime predicates,
// next_prime, div_mod / ext_gcd / pow_mod / sqrt_rem tuples, and the exact
// compare wrappers. Returns 0 when every case holds.

module p_wave45_shapes

use xiom.bigint;

fn eqv(a: &BigInt, s: Str) -> Bool {
  return bigint.bigint_to_str(a) == s;
}

fn main() -> Int {
  var zero = bigint.bigint_zero();
  var two = bigint.bigint_two();
  var seven = bigint.bigint_from_int(7);
  var ten = bigint.bigint_ten();

  // parsing
  if bigint.bigint_from_str("").is_ok { return 1; }
  var p = bigint.bigint_from_str("-123");
  if !p.is_ok { return 2; }
  if !eqv(&p.unwrap(), "-123") { return 3; }
  if bigint.bigint_from_base("", 10).is_ok { return 4; }
  var h = bigint.bigint_from_hex("ff");
  if !h.is_ok { return 5; }
  if !eqv(&h.unwrap(), "255") { return 6; }

  // zero fits every conversion
  if !bigint.bigint_to_int(&zero).is_ok { return 7; }
  if bigint.bigint_to_int(&zero).unwrap() != 0 { return 8; }
  if !bigint.bigint_to_u64(&zero).is_ok { return 9; }
  if !bigint.bigint_to_u128(&zero).is_ok { return 10; }
  if !bigint.bigint_to_i128(&zero).is_ok { return 11; }
  var huge = bigint.bigint_pow(&ten, 30);
  if bigint.bigint_to_int(&huge).is_ok { return 12; }

  // parity / one / prime
  if !bigint.bigint_is_even(&zero) { return 13; }
  if !bigint.bigint_is_even(&ten) { return 14; }
  if bigint.bigint_is_odd(&ten) { return 15; }
  if !bigint.bigint_is_odd(&seven) { return 16; }
  if !bigint.bigint_is_one(&bigint.bigint_one()) { return 17; }
  if bigint.bigint_is_one(&two) { return 18; }
  if !bigint.bigint_is_prime(&seven) { return 19; }
  if bigint.bigint_is_prime(&bigint.bigint_from_int(4)) { return 20; }
  if bigint.bigint_is_prime(&bigint.bigint_from_int(-7)) { return 21; }
  if !eqv(&bigint.bigint_next_prime(&ten), "11") { return 22; }
  if !eqv(&bigint.bigint_next_prime(&bigint.bigint_one()), "2") { return 23; }
  if !eqv(&bigint.bigint_next_prime(&bigint.bigint_from_int(-5)), "2") { return 24; }

  // div_mod / sqrt_rem tuples
  var dm = bigint.bigint_div_mod(&bigint.bigint_from_int(17), &bigint.bigint_from_int(5));
  var q = dm.0;
  var r = dm.1;
  if !eqv(&q, "3") { return 25; }
  if !eqv(&r, "2") { return 26; }
  var sr = bigint.bigint_sqrt_rem(&bigint.bigint_from_int(144));
  var s0 = sr.0;
  var s1 = sr.1;
  if !eqv(&s0, "12") { return 27; }
  if !eqv(&s1, "0") { return 28; }
  var sr2 = bigint.bigint_sqrt_rem(&ten);
  var s2 = sr2.0;
  var s3 = sr2.1;
  if !eqv(&s2, "3") { return 29; }
  if !eqv(&s3, "1") { return 30; }

  // ext_gcd: g == gcd(12, 18) == 6 (the Bezout identity is exercised in the smoke)
  var eg = bigint.bigint_ext_gcd(&bigint.bigint_from_int(12), &bigint.bigint_from_int(18));
  var g = eg.0;
  if !eqv(&g, "6") { return 31; }

  // pow_mod
  if !eqv(&bigint.bigint_pow_mod(&two, &ten, &bigint.bigint_from_int(1000)), "24") { return 32; }
  if !eqv(&bigint.bigint_pow_mod(&two, &zero, &seven), "1") { return 33; }

  // exact compare wrappers
  var three = bigint.bigint_from_int(3);
  if !bigint.bigint_eq(&two, &two) { return 34; }
  if bigint.bigint_eq(&two, &three) { return 35; }
  if !bigint.bigint_lt(&two, &three) { return 36; }
  if bigint.bigint_lt(&three, &two) { return 37; }
  if !bigint.bigint_le(&three, &three) { return 38; }
  if bigint.bigint_le(&bigint.bigint_from_int(4), &three) { return 39; }
  if !bigint.bigint_gt(&three, &two) { return 40; }
  if bigint.bigint_gt(&two, &three) { return 41; }
  if !bigint.bigint_ge(&three, &three) { return 42; }
  if bigint.bigint_ge(&two, &three) { return 43; }

  return 0;
}
