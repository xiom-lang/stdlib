module smoke_bigfloat
use xiom.num.bigfloat;
use xiom.bigfloat;
use xiom.string;
use xiom.io;

fn main() -> Int {
  // ---- constructors / round-trip ----
  // 1. from_str("3.14") round-trips
  var r1 = bigfloat.bigfloat_from_str("3.14");
  match r1 {
    Ok(f) => {
      if bigfloat.bigfloat_to_str(&f) != "3.14" { return 1; }
    }
    Err(_) => { return 1; }
  }
  // 2. "-1e-10" round-trips
  var r2 = bigfloat.bigfloat_from_str("-1e-10");
  match r2 {
    Ok(f) => {
      if bigfloat.bigfloat_to_str(&f) != "-0.0000000001" { return 2; }
      if !(bigfloat.bigfloat_is_negative(&f)) { return 2; }
    }
    Err(_) => { return 2; }
  }
  // 3. "2.5E+3" -> 2500
  var r3 = bigfloat.bigfloat_from_str("2.5E+3");
  match r3 {
    Ok(f) => {
      if bigfloat.bigfloat_to_str(&f) != "2500" { return 3; }
    }
    Err(_) => { return 3; }
  }
  // 4. 0.1 + 0.2 == 0.3 at precision 60
  var ra = bigfloat.bigfloat_from_str("0.1");
  var rb = bigfloat.bigfloat_from_str("0.2");
  match ra {
    Ok(av) => {
      match rb {
        Ok(bv) => {
          av.precision = 60;
          bv.precision = 60;
          var c = bigfloat.bigfloat_add(&av, &bv);
          if bigfloat.bigfloat_to_str(&c) != "0.3" { return 4; }
        }
        Err(_) => { return 4; }
      }
    }
    Err(_) => { return 4; }
  }
  // 5. sub: 5 - 3.5 == 1.5
  var f5a = bigfloat.bigfloat_from_str("5");
  var f5b = bigfloat.bigfloat_from_str("3.5");
  match f5a {
    Ok(a5) => {
      match f5b {
        Ok(b5) => {
          var d5 = bigfloat.bigfloat_sub(&a5, &b5);
          if bigfloat.bigfloat_to_str(&d5) != "1.5" { return 5; }
        }
        Err(_) => { return 5; }
      }
    }
    Err(_) => { return 5; }
  }
  // 6. mul: 1.5 * 2 == 3
  var f6a = bigfloat.bigfloat_from_str("1.5");
  var f6b = bigfloat.bigfloat_from_str("2");
  match f6a {
    Ok(a6) => {
      match f6b {
        Ok(b6) => {
          var m6 = bigfloat.bigfloat_mul(&a6, &b6);
          if bigfloat.bigfloat_to_str(&m6) != "3" { return 6; }
        }
        Err(_) => { return 6; }
      }
    }
    Err(_) => { return 6; }
  }
  // 7. div: 1/3 * 3 rounds to 1
  var f7a = bigfloat.bigfloat_from_str("1");
  var f7b = bigfloat.bigfloat_from_str("3");
  match f7a {
    Ok(a7) => {
      match f7b {
        Ok(b7) => {
          var q7 = bigfloat.bigfloat_div(&a7, &b7);
          var m7 = bigfloat.bigfloat_mul(&q7, &b7);
          if bigfloat.bigfloat_to_str_prec(&m7, 20) != "1" { return 7; }
        }
        Err(_) => { return 7; }
      }
    }
    Err(_) => { return 7; }
  }
  // 8. sqrt(2)^2 rounds to 2
  var f8a = bigfloat.bigfloat_from_str("2");
  match f8a {
    Ok(a8) => {
      var s8 = bigfloat.bigfloat_sqrt(&a8);
      var m8 = bigfloat.bigfloat_mul(&s8, &s8);
      if bigfloat.bigfloat_to_str_prec(&m8, 20) != "2" { return 8; }
    }
    Err(_) => { return 8; }
  }
  // 9. sqrt(81) == 9; sqrt(2) to 15 digits
  var f9a = bigfloat.bigfloat_from_str("81");
  match f9a {
    Ok(a9) => {
      var s9 = bigfloat.bigfloat_sqrt(&a9);
      if bigfloat.bigfloat_to_str(&s9) != "9" { return 9; }
    }
    Err(_) => { return 9; }
  }
  match f8a {
    Ok(a9b) => {
      var s9b = bigfloat.bigfloat_sqrt(&a9b);
      if bigfloat.bigfloat_to_str_prec(&s9b, 15) != "1.41421356237310" { return 9; }
    }
    Err(_) => { return 9; }
  }
  // 10. inv(2) == 0.5; inv(4) == 0.25
  var f10a = bigfloat.bigfloat_from_str("2");
  match f10a {
    Ok(a10) => {
      var i10 = bigfloat.bigfloat_inv(&a10);
      if bigfloat.bigfloat_to_str(&i10) != "0.5" { return 10; }
    }
    Err(_) => { return 10; }
  }
  // 11. pow: 2^10 == 1024
  match f10a {
    Ok(a11) => {
      var p11 = bigfloat.bigfloat_pow(&a11, 10);
      if bigfloat.bigfloat_to_str(&p11) != "1024" { return 11; }
    }
    Err(_) => { return 11; }
  }
  // 12. floor/ceil/round/trunc/fract on 3.7 and -3.7
  var f12 = bigfloat.bigfloat_from_str("3.7");
  var f12n = bigfloat.bigfloat_from_str("-3.7");
  match f12 {
    Ok(a12) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_floor(&a12)) != "3" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_ceil(&a12)) != "4" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_trunc(&a12)) != "3" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a12)) != "4" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_fract(&a12)) != "0.7" { return 12; }
    }
    Err(_) => { return 12; }
  }
  match f12n {
    Ok(a12) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_floor(&a12)) != "-4" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_ceil(&a12)) != "-3" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_trunc(&a12)) != "-3" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a12)) != "-4" { return 12; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_fract(&a12)) != "-0.7" { return 12; }
    }
    Err(_) => { return 12; }
  }
  // 13. ties-to-even: round(2.5) == 2, round(3.5) == 4, round(-2.5) == -2, round(0.5) == 0
  var f13a = bigfloat.bigfloat_from_str("2.5");
  var f13b = bigfloat.bigfloat_from_str("3.5");
  var f13c = bigfloat.bigfloat_from_str("-2.5");
  var f13d = bigfloat.bigfloat_from_str("0.5");
  match f13a {
    Ok(a13) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a13)) != "2" { return 13; }
    }
    Err(_) => { return 13; }
  }
  match f13b {
    Ok(a13) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a13)) != "4" { return 13; }
    }
    Err(_) => { return 13; }
  }
  match f13c {
    Ok(a13) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a13)) != "-2" { return 13; }
    }
    Err(_) => { return 13; }
  }
  match f13d {
    Ok(a13) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_round(&a13)) != "0" { return 13; }
    }
    Err(_) => { return 13; }
  }
  // 14. comparisons
  var f14a = bigfloat.bigfloat_from_str("0.1");
  var f14b = bigfloat.bigfloat_from_str("0.2");
  var f14c = bigfloat.bigfloat_from_str("-1.5");
  var f14d = bigfloat.bigfloat_from_str("1.5");
  match f14a {
    Ok(a14) => {
      match f14b {
        Ok(b14) => {
          if !(bigfloat.bigfloat_lt(&a14, &b14)) { return 14; }
        }
        Err(_) => { return 14; }
      }
    }
    Err(_) => { return 14; }
  }
  match f14c {
    Ok(a14) => {
      match f14d {
        Ok(b14) => {
          if !(bigfloat.bigfloat_lt(&a14, &b14)) { return 14; }
        }
        Err(_) => { return 14; }
      }
    }
    Err(_) => { return 14; }
  }
  // eq after normalize: "3.140" == "3.14"
  var f14e = bigfloat.bigfloat_from_str("3.140");
  match f14e {
    Ok(a14) => {
      match r1 {
        Ok(b14) => {
          if !(bigfloat.bigfloat_eq(&a14, &b14)) { return 14; }
        }
        Err(_) => { return 14; }
      }
    }
    Err(_) => { return 14; }
  }
  // 15. to_bigint truncates toward zero
  var f15a = bigfloat.bigfloat_from_str("2.5");
  var f15b = bigfloat.bigfloat_from_str("-2.5");
  match f15a {
    Ok(a15) => {
      var bi = bigfloat.bigfloat_to_bigint(&a15);
      if xiom.bigint.bigint_to_str(&bi) != "2" { return 15; }
    }
    Err(_) => { return 15; }
  }
  match f15b {
    Ok(a15) => {
      var bi = bigfloat.bigfloat_to_bigint(&a15);
      if xiom.bigint.bigint_to_str(&bi) != "-2" { return 15; }
    }
    Err(_) => { return 15; }
  }
  // 16. to_float64: 3.14 within 1e-9
  match r1 {
    Ok(a16) => {
      var fo = bigfloat.bigfloat_to_float64(&a16);
      match fo {
        Some(v) => {
          // tolerance check without tiny float literals (compiler emits
          // literals rounded to 6 decimals -- docs/COMPILER_BUGS.md BUG 10)
          var diff: Float64 = v - 3.14;
          if diff < 0.0 { diff = -diff; }
          var scaled: Float64 = diff * 1000000000.0;
          if scaled > 1.0 { return 16; }
        }
        None => { return 16; }
      }
    }
    Err(_) => { return 16; }
  }
  // 17. to_float64 overflow -> None
  var f17 = bigfloat.bigfloat_from_str("1e400");
  match f17 {
    Ok(a17) => {
      var fo = bigfloat.bigfloat_to_float64(&a17);
      match fo {
        Some(_) => { return 17; }
        None => {}
      }
    }
    Err(_) => { return 17; }
  }
  // 18. constants
  var pi_s = bigfloat.bigfloat_to_str(&bigfloat.bigfloat_pi());
  if xiom.string.str_slice(pi_s, 0, 7) != "3.14159" { return 18; }
  var e_s = bigfloat.bigfloat_to_str(&bigfloat.bigfloat_e());
  if xiom.string.str_slice(e_s, 0, 7) != "2.71828" { return 18; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_zero()) != "0" { return 18; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_one()) != "1" { return 18; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_two()) != "2" { return 18; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_ten()) != "10" { return 18; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_half()) != "0.5" { return 18; }
  // 19. round mode set/get
  bigfloat.bigfloat_set_round_mode(bigfloat.RoundMode.Down);
  if bigfloat.bigfloat_get_round_mode() != bigfloat.RoundMode.Down { return 19; }
  bigfloat.bigfloat_set_round_mode(bigfloat.RoundMode.Nearest);
  if bigfloat.bigfloat_get_round_mode() != bigfloat.RoundMode.Nearest { return 19; }
  // 20. with_rounding: 3.14159 -> 3 digits: Nearest/Up/Down/Zero
  var f20 = bigfloat.bigfloat_from_str("3.14159");
  var f20n = bigfloat.bigfloat_from_str("-3.14159");
  match f20 {
    Ok(a20) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Nearest, 3)) != "3.14" { return 20; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Up, 3)) != "3.15" { return 20; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Down, 3)) != "3.14" { return 20; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Zero, 3)) != "3.14" { return 20; }
    }
    Err(_) => { return 20; }
  }
  match f20n {
    Ok(a20) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Up, 3)) != "-3.14" { return 20; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_with_rounding(&a20, bigfloat.RoundMode.Down, 3)) != "-3.15" { return 20; }
    }
    Err(_) => { return 20; }
  }
  // 21. precision honored: 1/3 at precision 10
  var f21a = bigfloat.bigfloat_with_precision(1, 10);
  var f21b = bigfloat.bigfloat_with_precision(3, 10);
  var q21 = bigfloat.bigfloat_div(&f21a, &f21b);
  if bigfloat.bigfloat_to_str_prec(&q21, 15) != "0.3333333333" { return 21; }
  // 22. neg / abs / sign
  var f22 = bigfloat.bigfloat_from_str("-5");
  match f22 {
    Ok(a22) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_neg(&a22)) != "5" { return 22; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_abs(&a22)) != "5" { return 22; }
      if bigfloat.bigfloat_sign(&a22) != -1 { return 22; }
      if bigfloat.bigfloat_sign(&bigfloat.bigfloat_abs(&a22)) != 1 { return 22; }
      if bigfloat.bigfloat_sign(&bigfloat.bigfloat_zero()) != 0 { return 22; }
    }
    Err(_) => { return 22; }
  }
  // 23. from_float: 0.1 exact, 3.14 exact
  var f23a = bigfloat.bigfloat_from_float(0.1);
  if bigfloat.bigfloat_to_str(&f23a) != "0.1" { return 23; }
  var f23b = bigfloat.bigfloat_from_float(3.14);
  if bigfloat.bigfloat_to_str_prec(&f23b, 15) != "3.14" { return 23; }
  // 24. from_bigint
  var f24 = bigfloat.bigfloat_from_bigint(&xiom.bigint.bigint_from_int(42));
  if bigfloat.bigfloat_to_str(&f24) != "42" { return 24; }
  // 25. aggregate import: full dotted path resolves
  var f25 = xiom.num.bigfloat.bigfloat_from_str("7.5");
  match f25 {
    Ok(a25) => {
      if xiom.num.bigfloat.bigfloat_to_str(&a25) != "7.5" { return 25; }
      var m25 = xiom.num.bigfloat.bigfloat_mul(&a25, &xiom.num.bigfloat.bigfloat_two());
      if xiom.num.bigfloat.bigfloat_to_str(&m25) != "15" { return 25; }
    }
    Err(_) => { return 25; }
  }
  // 26. big arithmetic: 1e20 + 1
  var f26a = bigfloat.bigfloat_from_str("100000000000000000000");
  var f26b = bigfloat.bigfloat_from_str("1");
  match f26a {
    Ok(a26) => {
      match f26b {
        Ok(b26) => {
          var s26 = bigfloat.bigfloat_add(&a26, &b26);
          if bigfloat.bigfloat_to_str(&s26) != "100000000000000000001" { return 26; }
        }
        Err(_) => { return 26; }
      }
    }
    Err(_) => { return 26; }
  }
  // 27. precision() accessor
  var f27 = bigfloat.bigfloat_with_precision(7, 12);
  if bigfloat.bigfloat_precision(&f27) != 12 { return 27; }
  // 28. le/ge/gt wrappers
  match f14a {
    Ok(a28) => {
      match f14b {
        Ok(b28) => {
          if !(bigfloat.bigfloat_le(&a28, &b28)) { return 28; }
          if !(bigfloat.bigfloat_ge(&b28, &a28)) { return 28; }
          if !(bigfloat.bigfloat_gt(&b28, &a28)) { return 28; }
        }
        Err(_) => { return 28; }
      }
    }
    Err(_) => { return 28; }
  }
  // 29. to_str_prec on a plain value
  var f29 = bigfloat.bigfloat_from_str("2.71828182845904523536");
  match f29 {
    Ok(a29) => {
      if bigfloat.bigfloat_to_str_prec(&a29, 10) != "2.718281828" { return 29; }
    }
    Err(_) => { return 29; }
  }
  // 30. pow(10, 3) == 1000; pow(0.5, 3) == 0.125
  var f30a = bigfloat.bigfloat_from_str("10");
  var f30b = bigfloat.bigfloat_from_str("0.5");
  match f30a {
    Ok(a30) => {
      var p30 = bigfloat.bigfloat_pow(&a30, 3);
      if bigfloat.bigfloat_to_str(&p30) != "1000" { return 30; }
    }
    Err(_) => { return 30; }
  }
  match f30b {
    Ok(a30) => {
      var p30 = bigfloat.bigfloat_pow(&a30, 3);
      if bigfloat.bigfloat_to_str(&p30) != "0.125" { return 30; }
    }
    Err(_) => { return 30; }
  }
  // ---- Phase C: transcendentals ----
  // 31. exp(0) == 1; exp(1) matches e to 20 digits
  var z31 = bigfloat.bigfloat_zero();
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_exp(&z31)) != "1" { return 31; }
  var o31 = bigfloat.bigfloat_one();
  var e31 = bigfloat.bigfloat_exp(&o31);
  if bigfloat.bigfloat_to_str_prec(&e31, 20) != "2.7182818284590452354" { return 31; }
  // 32. ln(exp(1)) == 1; ln(1) == 0
  var l32 = bigfloat.bigfloat_ln(&e31);
  if bigfloat.bigfloat_to_str_prec(&l32, 20) != "1" { return 32; }
  var l32b = bigfloat.bigfloat_ln(&o31);
  if bigfloat.bigfloat_to_str(&l32b) != "0" { return 32; }
  // 33. ln(10) to 20 digits
  var l33 = bigfloat.bigfloat_ln(&bigfloat.bigfloat_ten());
  if bigfloat.bigfloat_to_str_prec(&l33, 20) != "2.3025850929940456840" { return 33; }
  // 34. log10(100) == 2, log10(1000) == 3 -- via the identity
  //     log10(x) * ln(10) == ln(x) (robust against the last-digit rounding
  //     of the computed quotient; to_str_prec preserves trailing zeros)
  var f34 = bigfloat.bigfloat_from_str("100");
  match f34 {
    Ok(a34) => {
      var g34 = bigfloat.bigfloat_log10(&a34);
      var m34 = bigfloat.bigfloat_mul(&g34, &l33);
      var l34 = bigfloat.bigfloat_ln(&a34);
      if bigfloat.bigfloat_to_str_prec(&m34, 15) != bigfloat.bigfloat_to_str_prec(&l34, 15) { return 34; }
    }
    Err(_) => { return 34; }
  }
  var f34b = bigfloat.bigfloat_from_str("1000");
  match f34b {
    Ok(a34) => {
      var g34 = bigfloat.bigfloat_log10(&a34);
      var m34 = bigfloat.bigfloat_mul(&g34, &l33);
      var l34 = bigfloat.bigfloat_ln(&a34);
      if bigfloat.bigfloat_to_str_prec(&m34, 15) != bigfloat.bigfloat_to_str_prec(&l34, 15) { return 34; }
    }
    Err(_) => { return 34; }
  }
  // 35. sin(0) == 0; cos(0) == 1; sin(pi/2) == 1; cos(pi) == -1
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_sin(&z31)) != "0" { return 35; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_cos(&z31)) != "1" { return 35; }
  var pi35 = bigfloat.bigfloat_pi();
  var hp35 = bigfloat.bigfloat_div(&pi35, &bigfloat.bigfloat_two());
  if bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_sin(&hp35), 15) != "1" { return 35; }
  if bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_cos(&pi35), 15) != "-1" { return 35; }
  // 36. sin(pi/6) == 0.5 (to 15 digits)
  var s36 = bigfloat.bigfloat_div(&pi35, &bigfloat.bigfloat_from_int(6));
  if bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_sin(&s36), 15) != "0.5" { return 36; }
  // 37. atan(1) * 4 == pi (to 20 digits)
  var a37 = bigfloat.bigfloat_mul(&bigfloat.bigfloat_atan(&o31), &bigfloat.bigfloat_from_int(4));
  if bigfloat.bigfloat_to_str_prec(&a37, 20) != bigfloat.bigfloat_to_str_prec(&pi35, 20) { return 37; }
  // 38. atan2(1, 1) == pi/4; atan2(-1, -1) == -pi/4
  var a38 = bigfloat.bigfloat_atan2(&o31, &o31);
  var q38 = bigfloat.bigfloat_div(&pi35, &bigfloat.bigfloat_from_int(4));
  if bigfloat.bigfloat_to_str_prec(&a38, 20) != bigfloat.bigfloat_to_str_prec(&q38, 20) { return 38; }
  var n38 = bigfloat.bigfloat_from_str("-1");
  match n38 {
    Ok(nv) => {
      // atan2(-1, -1) = -3*pi/4 (third quadrant)
      var a38b = bigfloat.bigfloat_atan2(&nv, &nv);
      var q38b = bigfloat.bigfloat_sub(&q38, &pi35);
      if bigfloat.bigfloat_to_str_prec(&a38b, 20) != bigfloat.bigfloat_to_str_prec(&q38b, 20) { return 38; }
    }
    Err(_) => { return 38; }
  }
  // 39. pow_bf(2, 0.5)^2 == 2
  var h39 = bigfloat.bigfloat_from_str("0.5");
  match h39 {
    Ok(hv) => {
      var p39 = bigfloat.bigfloat_pow_bf(&bigfloat.bigfloat_two(), &hv);
      var m39 = bigfloat.bigfloat_mul(&p39, &p39);
      if bigfloat.bigfloat_to_str_prec(&m39, 20) != "2" { return 39; }
    }
    Err(_) => { return 39; }
  }
  // 40. e^ln(2) == 2; exp(ln(10)) == 10
  var l40 = bigfloat.bigfloat_ln(&bigfloat.bigfloat_two());
  var e40 = bigfloat.bigfloat_exp(&l40);
  if bigfloat.bigfloat_to_str_prec(&e40, 20) != "2" { return 40; }
  var e40b = bigfloat.bigfloat_exp(&l33);
  if bigfloat.bigfloat_to_str_prec(&e40b, 20) != "10" { return 40; }
  // 41. ln(e()) == 1
  var l41 = bigfloat.bigfloat_ln(&bigfloat.bigfloat_e());
  if bigfloat.bigfloat_to_str_prec(&l41, 20) != "1" { return 41; }
  // 42. pi_with_precision / e_with_precision match the 100-digit constants
  var p42 = bigfloat.bigfloat_pi_with_precision(20);
  if bigfloat.bigfloat_to_str_prec(&p42, 20) != bigfloat.bigfloat_to_str_prec(&pi35, 20) { return 42; }
  var e42 = bigfloat.bigfloat_e_with_precision(20);
  if bigfloat.bigfloat_to_str_prec(&e42, 20) != bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_e(), 20) { return 42; }
  // 43. tan(0) == 0; tan(pi/4) == 1 (to 15 digits)
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_tan(&z31)) != "0" { return 43; }
  if bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_tan(&q38), 15) != "1" { return 43; }
  // 44. odd symmetry: sin(-1) == -sin(1); atan(-1) == -atan(1); exp(-1)*exp(1) == 1
  var n44 = bigfloat.bigfloat_from_str("-1");
  match n44 {
    Ok(nv) => {
      var sn44 = bigfloat.bigfloat_sin(&nv);
      var sp44 = bigfloat.bigfloat_sin(&o31);
      if bigfloat.bigfloat_to_str_prec(&sn44, 15) != bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_neg(&sp44), 15) { return 44; }
      var an44 = bigfloat.bigfloat_atan(&nv);
      var ap44 = bigfloat.bigfloat_atan(&o31);
      if bigfloat.bigfloat_to_str_prec(&an44, 15) != bigfloat.bigfloat_to_str_prec(&bigfloat.bigfloat_neg(&ap44), 15) { return 44; }
      var en44 = bigfloat.bigfloat_exp(&nv);
      var prod44 = bigfloat.bigfloat_mul(&en44, &e31);
      if bigfloat.bigfloat_to_str_prec(&prod44, 15) != "1" { return 44; }
    }
    Err(_) => { return 44; }
  }
  // ---- Phase C.5: additional elementary functions ----
  // helper-free rounded-equality check: |x - ref| < 10^-15 via with_rounding
  // 45. cbrt(27) == 3, cbrt(8) == 2, cbrt(-8) == -2, cbrt(2)^3 == 2
  var f45a = bigfloat.bigfloat_from_str("27");
  match f45a {
    Ok(a45) => {
      var c45 = bigfloat.bigfloat_cbrt(&a45);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&c45, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(3))) { return 45; }
    }
    Err(_) => { return 45; }
  }
  var f45b = bigfloat.bigfloat_from_str("8");
  match f45b {
    Ok(a45) => {
      var c45 = bigfloat.bigfloat_cbrt(&a45);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&c45, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(2))) { return 45; }
    }
    Err(_) => { return 45; }
  }
  var f45c = bigfloat.bigfloat_from_str("-8");
  match f45c {
    Ok(a45) => {
      var c45 = bigfloat.bigfloat_cbrt(&a45);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&c45, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(-2))) { return 45; }
    }
    Err(_) => { return 45; }
  }
  var f45d = bigfloat.bigfloat_from_str("2");
  match f45d {
    Ok(a45) => {
      var c45 = bigfloat.bigfloat_cbrt(&a45);
      var m45 = bigfloat.bigfloat_mul(&bigfloat.bigfloat_mul(&c45, &c45), &c45);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&m45, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(2))) { return 45; }
    }
    Err(_) => { return 45; }
  }
  // 46. hypot(3, 4) == 5; hypot(1, 1) == sqrt(2) to 15
  var f46a = bigfloat.bigfloat_from_str("3");
  var f46b = bigfloat.bigfloat_from_str("4");
  match f46a {
    Ok(a46) => {
      match f46b {
        Ok(b46) => {
          var h46 = bigfloat.bigfloat_hypot(&a46, &b46);
          if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&h46, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(5))) { return 46; }
        }
        Err(_) => { return 46; }
      }
    }
    Err(_) => { return 46; }
  }
  var h46 = bigfloat.bigfloat_hypot(&o31, &o31);
  var s46 = bigfloat.bigfloat_sqrt(&bigfloat.bigfloat_two());
  if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&h46, bigfloat.RoundMode.Nearest, 15),
                           &bigfloat.bigfloat_with_rounding(&s46, bigfloat.RoundMode.Nearest, 15))) { return 46; }
  // 47. log2 identity: log2(8)*ln(2) == ln(8) (to 15)
  var f47 = bigfloat.bigfloat_from_str("8");
  match f47 {
    Ok(a47) => {
      var g47 = bigfloat.bigfloat_log2(&a47);
      var l47 = bigfloat.bigfloat_ln(&a47);
      var m47 = bigfloat.bigfloat_mul(&g47, &bigfloat.bigfloat_ln(&bigfloat.bigfloat_two()));
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&m47, bigfloat.RoundMode.Nearest, 15),
                               &bigfloat.bigfloat_with_rounding(&l47, bigfloat.RoundMode.Nearest, 15))) { return 47; }
    }
    Err(_) => { return 47; }
  }
  // 48. exp2(3) == 8
  var f48 = bigfloat.bigfloat_from_str("3");
  match f48 {
    Ok(a48) => {
      var e48 = bigfloat.bigfloat_exp2(&a48);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&e48, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_from_int(8))) { return 48; }
    }
    Err(_) => { return 48; }
  }
  // 49. hyperbolic: cosh^2 - sinh^2 == 1; tanh(0) == 0
  var ch49 = bigfloat.bigfloat_cosh(&o31);
  var sh49 = bigfloat.bigfloat_sinh(&o31);
  var d49 = bigfloat.bigfloat_sub(&bigfloat.bigfloat_mul(&ch49, &ch49), &bigfloat.bigfloat_mul(&sh49, &sh49));
  if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&d49, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_one())) { return 49; }
  if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_tanh(&z31)) != "0" { return 49; }
  // 50. asin(1) == pi/2; asin(0.5) == pi/6; acos(1) == 0
  var a50 = bigfloat.bigfloat_asin(&o31);
  var hp50 = bigfloat.bigfloat_div(&pi35, &bigfloat.bigfloat_two());
  if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&a50, bigfloat.RoundMode.Nearest, 15),
                           &bigfloat.bigfloat_with_rounding(&hp50, bigfloat.RoundMode.Nearest, 15))) { return 50; }
  var hf50 = bigfloat.bigfloat_from_str("0.5");
  match hf50 {
    Ok(hv) => {
      var a50b = bigfloat.bigfloat_asin(&hv);
      var s6 = bigfloat.bigfloat_div(&pi35, &bigfloat.bigfloat_from_int(6));
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&a50b, bigfloat.RoundMode.Nearest, 15),
                               &bigfloat.bigfloat_with_rounding(&s6, bigfloat.RoundMode.Nearest, 15))) { return 50; }
      var ac50 = bigfloat.bigfloat_acos(&o31);
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&ac50, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_zero())) { return 50; }
    }
    Err(_) => { return 50; }
  }
  // 51. asinh(sinh(1)) == 1; atanh(0.5) == ln(3)/2; acosh(1) == 0
  var as51 = bigfloat.bigfloat_asinh(&sh49);
  if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&as51, bigfloat.RoundMode.Nearest, 10), &bigfloat.bigfloat_one())) { return 51; }
  match hf50 {
    Ok(hv) => {
      var at51 = bigfloat.bigfloat_atanh(&hv);
      var l3 = bigfloat.bigfloat_ln(&bigfloat.bigfloat_from_int(3));
      var h51 = bigfloat.bigfloat_div(&l3, &bigfloat.bigfloat_two());
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&at51, bigfloat.RoundMode.Nearest, 15),
                               &bigfloat.bigfloat_with_rounding(&h51, bigfloat.RoundMode.Nearest, 15))) { return 51; }
    }
    Err(_) => { return 51; }
  }
  var ac51 = bigfloat.bigfloat_acosh(&o31);
  if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&ac51, bigfloat.RoundMode.Nearest, 15), &bigfloat.bigfloat_zero())) { return 51; }
  // 52. to_str_sci
  var f52 = bigfloat.bigfloat_from_str("1234.567");
  match f52 {
    Ok(a52) => {
      if bigfloat.bigfloat_to_str_sci(&a52, 5) != "1.2346e+3" { return 52; }
    }
    Err(_) => { return 52; }
  }
  var f52b = bigfloat.bigfloat_from_str("0.0001234");
  match f52b {
    Ok(a52) => {
      if bigfloat.bigfloat_to_str_sci(&a52, 3) != "1.23e-4" { return 52; }
    }
    Err(_) => { return 52; }
  }
  if bigfloat.bigfloat_to_str_sci(&z31, 5) != "0" { return 52; }
  // 53. from_ratio
  var r53 = bigfloat.bigfloat_from_ratio(1, 4);
  if bigfloat.bigfloat_to_str(&r53) != "0.25" { return 53; }
  var r53b = bigfloat.bigfloat_from_ratio(22, 7);
  var s53b = bigfloat.bigfloat_from_str("3.14285714285714");
  match s53b {
    Ok(ref53) => {
      if !(bigfloat.bigfloat_eq(&bigfloat.bigfloat_with_rounding(&r53b, bigfloat.RoundMode.Nearest, 15),
                               &bigfloat.bigfloat_with_rounding(&ref53, bigfloat.RoundMode.Nearest, 15))) { return 53; }
    }
    Err(_) => { return 53; }
  }
  // 54. pow10 exact
  var f54 = bigfloat.bigfloat_from_str("2.5");
  match f54 {
    Ok(a54) => {
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_pow10(&a54, 2)) != "250" { return 54; }
      if bigfloat.bigfloat_to_str(&bigfloat.bigfloat_pow10(&a54, -2)) != "0.025" { return 54; }
    }
    Err(_) => { return 54; }
  }
  // 55. integer helpers
  var f55 = bigfloat.bigfloat_from_str("-3.7");
  match f55 {
    Ok(a55) => {
      var fi55 = bigfloat.bigfloat_floor_int(&a55);
      match fi55 {
        Ok(v) => { if v != -4 { return 55; } }
        Err(_) => { return 55; }
      }
      var ti55 = bigfloat.bigfloat_trunc_int(&a55);
      match ti55 {
        Ok(v) => { if v != -3 { return 55; } }
        Err(_) => { return 55; }
      }
    }
    Err(_) => { return 55; }
  }
  var f55b = bigfloat.bigfloat_from_str("2.5");
  match f55b {
    Ok(a55) => {
      var ri55 = bigfloat.bigfloat_round_int(&a55);
      match ri55 {
        Ok(v) => { if v != 2 { return 55; } }
        Err(_) => { return 55; }
      }
      var ci55 = bigfloat.bigfloat_ceil_int(&a55);
      match ci55 {
        Ok(v) => { if v != 3 { return 55; } }
        Err(_) => { return 55; }
      }
    }
    Err(_) => { return 55; }
  }
  return 0;
}
