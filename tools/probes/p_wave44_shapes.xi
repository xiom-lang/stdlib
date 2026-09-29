// p_wave44_shapes.xi -- wave 44 verification: xiom.bigint canonical-form clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new runtime ensures clauses (canonical zero:
// digits empty implies negative false; negative implies digits non-empty).
// Value KATs go through bigint_to_str so the probe never reads struct fields.
// Returns 0 when every case holds.

module p_wave44_shapes

use xiom.bigint;

fn eq(a: &BigInt, s: Str) -> Bool {
  return bigint.bigint_to_str(a) == s;
}

fn main() -> Int {
  // constants + constructors
  if !eq(&bigint.bigint_zero(), "0") { return 1; }
  if !eq(&bigint.bigint_one(), "1") { return 2; }
  if !eq(&bigint.bigint_two(), "2") { return 3; }
  if !eq(&bigint.bigint_ten(), "10") { return 4; }
  var big = bigint.bigint_from_int(1234567890123456789);
  if !eq(&big, "1234567890123456789") { return 5; }
  var neg = bigint.bigint_from_int(-987654321);
  if !eq(&neg, "-987654321") { return 6; }
  if !eq(&bigint.bigint_from_u64(18446744073709551615), "18446744073709551615") { return 7; }

  // add / sub at the limb boundary + canonical zero
  var nine9 = bigint.bigint_from_int(999999999);
  var one = bigint.bigint_one();
  var sum = bigint.bigint_add(&nine9, &one);
  if !eq(&sum, "1000000000") { return 8; }
  var z = bigint.bigint_zero();
  var zz = bigint.bigint_add(&z, &z);
  if !eq(&zz, "0") { return 9; }
  var s = bigint.bigint_sub(&one, &bigint.bigint_two());
  if !eq(&s, "-1") { return 10; }
  var back = bigint.bigint_sub(&sum, &one);
  if !eq(&back, "999999999") { return 11; }

  // mul / div / mod
  if !eq(&bigint.bigint_mul(&nine9, &nine9), "999999998000000001") { return 12; }
  var ten = bigint.bigint_ten();
  var three = bigint.bigint_from_int(3);
  if !eq(&bigint.bigint_div(&ten, &three), "3") { return 13; }
  var mten = bigint.bigint_from_int(-10);
  if !eq(&bigint.bigint_div(&mten, &three), "-3") { return 14; }
  if !eq(&bigint.bigint_mod(&mten, &three), "2") { return 15; }
  if !eq(&bigint.bigint_mod(&z, &three), "0") { return 16; }

  // pow / sqrt
  if !eq(&bigint.bigint_pow(&bigint.bigint_two(), 10), "1024") { return 17; }
  var mtwo = bigint.bigint_from_int(-2);
  if !eq(&bigint.bigint_pow(&mtwo, 3), "-8") { return 18; }
  if !eq(&bigint.bigint_pow(&mtwo, 2), "4") { return 19; }
  if !eq(&bigint.bigint_pow(&mtwo, -1), "0") { return 20; }
  if !eq(&bigint.bigint_pow(&mtwo, 0), "1") { return 21; }
  if !eq(&bigint.bigint_sqrt(&bigint.bigint_from_int(144)), "12") { return 22; }
  if !eq(&bigint.bigint_sqrt(&bigint.bigint_two()), "1") { return 23; }

  // gcd / lcm / factorial / binomial / fibonacci
  var g = bigint.bigint_gcd(&bigint.bigint_from_int(48), &bigint.bigint_from_int(18));
  if !eq(&g, "6") { return 24; }
  if !eq(&bigint.bigint_gcd(&z, &z), "0") { return 25; }
  var g2 = bigint.bigint_gcd(&bigint.bigint_from_int(-4), &bigint.bigint_from_int(6));
  if !eq(&g2, "2") { return 26; }
  var l = bigint.bigint_lcm(&bigint.bigint_from_int(4), &bigint.bigint_from_int(6));
  if !eq(&l, "12") { return 27; }
  if !eq(&bigint.bigint_factorial(20), "2432902008176640000") { return 28; }
  if !eq(&bigint.bigint_factorial(0), "1") { return 29; }
  if !eq(&bigint.bigint_binomial(5, 2), "10") { return 30; }
  if !eq(&bigint.bigint_fibonacci(10), "55") { return 31; }
  if !eq(&bigint.bigint_fibonacci(0), "0") { return 32; }

  // shifts (decimal shift_left, arithmetic shift_right)
  if !eq(&bigint.bigint_shift_left(&one, 3), "1000") { return 33; }
  if !eq(&bigint.bigint_shift_right(&bigint.bigint_from_int(1000), 3), "125") { return 34; }
  if !eq(&bigint.bigint_shift_right(&bigint.bigint_from_int(-7), 1), "-4") { return 35; }

  // comparison / sign / predicates
  var two = bigint.bigint_two();
  if bigint.bigint_compare(&two, &three) != -1 { return 36; }
  if bigint.bigint_compare(&three, &three) != 0 { return 37; }
  if bigint.bigint_sign(&neg) != -1 { return 38; }
  if bigint.bigint_sign(&z) != 0 { return 39; }
  if bigint.bigint_sign(&three) != 1 { return 40; }
  if !bigint.bigint_is_negative(&neg) { return 41; }
  if bigint.bigint_is_negative(&z) { return 42; }
  if bigint.bigint_compare(&two, &three) >= 0 { return 43; }

  // base conversion
  if bigint.bigint_to_base(&bigint.bigint_from_int(255), 16) != "FF" { return 44; }
  if bigint.bigint_to_base(&two, 40) != "" { return 45; }
  if bigint.bigint_to_hex(&bigint.bigint_from_int(255)) != "ff" { return 46; }

  // bitwise + bit metrics
  var twelve = bigint.bigint_from_int(12);
  var tenn = bigint.bigint_from_int(10);
  if !eq(&bigint.bigint_bit_and(&twelve, &tenn), "8") { return 47; }
  if !eq(&bigint.bigint_bit_or(&twelve, &tenn), "14") { return 48; }
  if !eq(&bigint.bigint_bit_xor(&twelve, &tenn), "6") { return 49; }
  if !eq(&bigint.bigint_bit_and(&z, &z), "0") { return 50; }
  if bigint.bigint_popcount(&bigint.bigint_from_int(7)) != 3 { return 51; }
  if bigint.bigint_bit_len(&bigint.bigint_from_int(8)) != 4 { return 52; }
  if bigint.bigint_bit_len(&z) != 0 { return 53; }

  return 0;
}
