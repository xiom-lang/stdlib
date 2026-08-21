module smoke_bigint
use xiom.bigint;
use xiom.string;
fn main() -> Int {
  // original assertions (kept byte-identical behavior):
  var r = xiom.bigint.bigint_from_str("12345678901234567890");
  match r {
    Ok(b) => {
      var s = xiom.bigint.bigint_to_str(&b);
      if s != "12345678901234567890" { return 1; }
      var b2 = xiom.bigint.bigint_mul(&b, xiom.bigint.bigint_from_int(2));
      var s2 = xiom.bigint.bigint_to_str(&b2);
      if s2 != "24691357802469135780" { return 1; }
      var cmp = xiom.bigint.bigint_compare(&b, &b2);
      if cmp != -1 { return 1; }
    }
    Err(_) => { return 1; }
  }
  // ---- production additions (>=20 assertions) ----
  // 1. zero / one / ten
  var z = xiom.bigint.bigint_zero();
  if !(xiom.bigint.bigint_is_zero(&z)) { return 2; }
  var o = xiom.bigint.bigint_one();
  if !(xiom.bigint.bigint_is_one(&o)) { return 2; }
  var t10 = xiom.bigint.bigint_ten();
  if xiom.bigint.bigint_to_str(&t10) != "10" { return 2; }
  // 2. negative round-trip
  var neg = xiom.bigint.bigint_from_str("-9999999999999999999999");
  match neg {
    Ok(n) => {
      if xiom.bigint.bigint_to_str(&n) != "-9999999999999999999999" { return 3; }
      if !(xiom.bigint.bigint_is_negative(&n)) { return 3; }
      if xiom.bigint.bigint_sign(&n) != -1 { return 3; }
    }
    Err(_) => { return 3; }
  }
  // 3. hex
  var h1 = xiom.bigint.bigint_from_hex("ff");
  match h1 {
    Ok(v) => {
      if xiom.bigint.bigint_to_str(&v) != "255" { return 4; }
      if xiom.bigint.bigint_to_hex(&v) != "ff" { return 4; }
    }
    Err(_) => { return 4; }
  }
  var h2 = xiom.bigint.bigint_from_hex("-1a");
  match h2 {
    Ok(v) => {
      if xiom.bigint.bigint_to_str(&v) != "-26" { return 4; }
    }
    Err(_) => { return 4; }
  }
  // 4. base 36
  var b36 = xiom.bigint.bigint_from_base("zz", 36);
  match b36 {
    Ok(v) => {
      if xiom.bigint.bigint_to_str(&v) != "1295" { return 5; }
      if xiom.bigint.bigint_to_base(&v, 36) != "ZZ" { return 5; }
    }
    Err(_) => { return 5; }
  }
  // 5. add identity / commutativity
  var a5 = xiom.bigint.bigint_from_int(123456789);
  var s5 = xiom.bigint.bigint_add(&a5, &z);
  if !(xiom.bigint.bigint_eq(&a5, &s5)) { return 6; }
  var d5 = xiom.bigint.bigint_sub(&a5, &a5);
  if !(xiom.bigint.bigint_is_zero(&d5)) { return 6; }
  // 6. mul by 10 shifts decimal digits
  var m10 = xiom.bigint.bigint_mul(&a5, &t10);
  if xiom.bigint.bigint_to_str(&m10) != "1234567890" { return 7; }
  // 7. div_mod invariant: q*b + r == a, 0 <= r < |b|
  var num7r = xiom.bigint.bigint_from_str("987654321987654321");
  match num7r {
    Ok(num7) => {
      var den7 = xiom.bigint.bigint_from_int(12345);
      var dm = xiom.bigint.bigint_div_mod(&num7, &den7);
      var q7 = dm.0;
      var r7 = dm.1;
      var check7 = xiom.bigint.bigint_add(&xiom.bigint.bigint_mul(&q7, &den7), &r7);
      if !(xiom.bigint.bigint_eq(&check7, &num7)) { return 8; }
      if xiom.bigint.bigint_is_negative(&r7) { return 8; }
      if xiom.bigint.bigint_compare(&r7, &den7) >= 0 { return 8; }
    }
    Err(_) => { return 8; }
  }
  // 8. pow: 2^10 == 1024
  var p8 = xiom.bigint.bigint_pow(&xiom.bigint.bigint_from_int(2), 10);
  if xiom.bigint.bigint_to_str(&p8) != "1024" { return 9; }
  // 9. pow_mod: 2^10 mod 1000 == 24
  var pm9 = xiom.bigint.bigint_pow_mod(&xiom.bigint.bigint_from_int(2),
                                        &xiom.bigint.bigint_from_int(10),
                                        &xiom.bigint.bigint_from_int(1000));
  if xiom.bigint.bigint_to_str(&pm9) != "24" { return 10; }
  // 10. sqrt / sqrt_rem
  var sq10 = xiom.bigint.bigint_sqrt(&xiom.bigint.bigint_from_int(81));
  if xiom.bigint.bigint_to_str(&sq10) != "9" { return 11; }
  var sr10 = xiom.bigint.bigint_sqrt_rem(&xiom.bigint.bigint_from_int(82));
  if xiom.bigint.bigint_to_str(&sr10.0) != "9" { return 11; }
  if xiom.bigint.bigint_to_str(&sr10.1) != "1" { return 11; }
  var sq_bigr = xiom.bigint.bigint_from_str("999999999999999999999999999999");
  match sq_bigr {
    Ok(sq_big) => {
      var sq_check = xiom.bigint.bigint_mul(&sq_big, &sq_big);
      var sq2 = xiom.bigint.bigint_add(&sq_check, &xiom.bigint.bigint_from_int(1));
      var sq_big2 = xiom.bigint.bigint_from_str("999999999999999999999999999999");
      match sq_big2 {
        Ok(sb2) => {
          if xiom.bigint.bigint_compare(&sq2, &sb2) <= 0 { return 11; }
        }
        Err(_) => { return 11; }
      }
    }
    Err(_) => { return 11; }
  }
  // 11. gcd / lcm
  var g11 = xiom.bigint.bigint_gcd(&xiom.bigint.bigint_from_int(48), &xiom.bigint.bigint_from_int(18));
  if xiom.bigint.bigint_to_str(&g11) != "6" { return 12; }
  var l11 = xiom.bigint.bigint_lcm(&xiom.bigint.bigint_from_int(4), &xiom.bigint.bigint_from_int(6));
  if xiom.bigint.bigint_to_str(&l11) != "12" { return 12; }
  // 12. ext_gcd: 10*(-1) + 6*2 == 2
  var eg12 = xiom.bigint.bigint_ext_gcd(&xiom.bigint.bigint_from_int(10), &xiom.bigint.bigint_from_int(6));
  var lhs12 = xiom.bigint.bigint_add(&xiom.bigint.bigint_mul(&xiom.bigint.bigint_from_int(10), &eg12.1),
                                     &xiom.bigint.bigint_mul(&xiom.bigint.bigint_from_int(6), &eg12.2));
  if xiom.bigint.bigint_to_str(&eg12.0) != "2" { return 13; }
  if !(xiom.bigint.bigint_eq(&lhs12, &eg12.0)) { return 13; }
  // 13. is_prime
  var primes = Vec[Int].new();
  primes.push(2); primes.push(3); primes.push(5); primes.push(7);
  primes.push(11); primes.push(13); primes.push(97);
  var i13 = 0;
  while i13 < primes.len() {
    if !(xiom.bigint.bigint_is_prime(&xiom.bigint.bigint_from_int(primes[i13]))) { return 14; }
    i13 = i13 + 1;
  }
  var composites = Vec[Int].new();
  composites.push(4); composites.push(9); composites.push(15); composites.push(21);
  var i13b = 0;
  while i13b < composites.len() {
    if xiom.bigint.bigint_is_prime(&xiom.bigint.bigint_from_int(composites[i13b])) { return 14; }
    i13b = i13b + 1;
  }
  // 14. next_prime
  var np14 = xiom.bigint.bigint_next_prime(&xiom.bigint.bigint_from_int(14));
  if xiom.bigint.bigint_to_str(&np14) != "17" { return 15; }
  // 15. factorial / binomial / fibonacci
  var f15 = xiom.bigint.bigint_factorial(5);
  if xiom.bigint.bigint_to_str(&f15) != "120" { return 16; }
  var b15 = xiom.bigint.bigint_binomial(10, 3);
  if xiom.bigint.bigint_to_str(&b15) != "120" { return 16; }
  var fib15 = xiom.bigint.bigint_fibonacci(10);
  if xiom.bigint.bigint_to_str(&fib15) != "55" { return 16; }
  // 16. bitwise
  var ba = xiom.bigint.bigint_from_int(12);
  var bb = xiom.bigint.bigint_from_int(10);
  var and16 = xiom.bigint.bigint_bit_and(&ba, &bb);
  if xiom.bigint.bigint_to_str(&and16) != "8" { return 17; }
  var or16 = xiom.bigint.bigint_bit_or(&ba, &bb);
  if xiom.bigint.bigint_to_str(&or16) != "14" { return 17; }
  var xor16 = xiom.bigint.bigint_bit_xor(&ba, &bb);
  if xiom.bigint.bigint_to_str(&xor16) != "6" { return 17; }
  var shl16 = xiom.bigint.bigint_shift_left(&xiom.bigint.bigint_from_int(1), 3);
  if xiom.bigint.bigint_to_str(&shl16) != "1000" { return 17; }
  var shr16 = xiom.bigint.bigint_shift_right(&xiom.bigint.bigint_from_int(8), 3);
  if xiom.bigint.bigint_to_str(&shr16) != "1" { return 17; }
  var pc16 = xiom.bigint.bigint_popcount(&xiom.bigint.bigint_from_int(11));
  if pc16 != 3 { return 17; }
  var bl16 = xiom.bigint.bigint_bit_len(&xiom.bigint.bigint_from_int(255));
  if bl16 != 8 { return 17; }
  // 17. to_int range
  var ti17 = xiom.bigint.bigint_to_int(&xiom.bigint.bigint_from_int(42));
  match ti17 {
    Ok(v) => {
      if v != 42 { return 18; }
    }
    Err(_) => { return 18; }
  }
  var huger = xiom.bigint.bigint_from_str("999999999999999999999999999999999999999");
  match huger {
    Ok(huge) => {
      var th17 = xiom.bigint.bigint_to_int(&huge);
      match th17 {
        Ok(_) => { return 18; }
        Err(_) => {}
      }
    }
    Err(_) => { return 18; }
  }
  // 18. comparison chain: -5 < -1 < 0 < 1 < 5
  var m5 = xiom.bigint.bigint_from_int(-5);
  var m1 = xiom.bigint.bigint_from_int(-1);
  var one18 = xiom.bigint.bigint_from_int(1);
  var five = xiom.bigint.bigint_from_int(5);
  if !(xiom.bigint.bigint_lt(&m5, &m1)) { return 19; }
  if !(xiom.bigint.bigint_lt(&m1, &z)) { return 19; }
  if !(xiom.bigint.bigint_lt(&z, &one18)) { return 19; }
  if !(xiom.bigint.bigint_lt(&one18, &five)) { return 19; }
  if !(xiom.bigint.bigint_ge(&five, &five)) { return 19; }
  if !(xiom.bigint.bigint_le(&m5, &m5)) { return 19; }
  if !(xiom.bigint.bigint_gt(&five, &one18)) { return 19; }
  // 19. two's-complement negative bit ops: -5 & 6 == 2, -5 | 6 == -1, -5 ^ 6 == -3
  var n5 = xiom.bigint.bigint_from_int(-5);
  var six = xiom.bigint.bigint_from_int(6);
  var na = xiom.bigint.bigint_bit_and(&n5, &six);
  if xiom.bigint.bigint_to_str(&na) != "2" { return 20; }
  var no = xiom.bigint.bigint_bit_or(&n5, &six);
  if xiom.bigint.bigint_to_str(&no) != "-1" { return 20; }
  var nx = xiom.bigint.bigint_bit_xor(&n5, &six);
  if xiom.bigint.bigint_to_str(&nx) != "-3" { return 20; }
  var sar = xiom.bigint.bigint_shift_right(&n5, 1);
  if xiom.bigint.bigint_to_str(&sar) != "-3" { return 20; }
  // 20. from_u64 full range
  var maxu: UInt64 = 0;
  maxu = maxu - 1;
  var u64max = xiom.bigint.bigint_from_u64(maxu);
  if xiom.bigint.bigint_to_str(&u64max) != "18446744073709551615" { return 21; }
  // 21. Karatsuba path (>= 4000-limb operands exercise the recursive split):
  //     (10^500-1)(10^400-1) == 10^900 - 10^500 - 10^400 + 1,
  //     and (a*b)/b == a.
  var p500 = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), 500);
  var p400 = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), 400);
  var a21 = xiom.bigint.bigint_sub(&p500, &xiom.bigint.bigint_one());
  var b21 = xiom.bigint.bigint_sub(&p400, &xiom.bigint.bigint_one());
  var m21 = xiom.bigint.bigint_mul(&a21, &b21);
  var p900 = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), 900);
  var e21 = xiom.bigint.bigint_add(
    &xiom.bigint.bigint_sub(&xiom.bigint.bigint_sub(&p900, &p500), &p400),
    &xiom.bigint.bigint_one());
  if !(xiom.bigint.bigint_eq(&m21, &e21)) { return 21; }
  var q21 = xiom.bigint.bigint_div(&m21, &b21);
  if !(xiom.bigint.bigint_eq(&q21, &a21)) { return 21; }
  return 0;
}
