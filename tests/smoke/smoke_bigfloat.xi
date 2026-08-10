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
          // literals rounded to 6 decimals — docs/COMPILER_BUGS.md BUG 10)
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
  return 0;
}
