module smoke_num_precision
use xiom.num.precision_integer;
use xiom.num.precision_float;
use xiom.num.precision_rational;
use xiom.string;
use xiom.io;

fn main() -> Int {
  // ================= precision_integer =================
  // construction / round-trip
  var bi1 = precision_integer.bigint_from_int(42);
  if precision_integer.bigint_to_str(bi1) != "42" { io.println("pi: to_str 42"); return 1; }
  var bs1 = precision_integer.bigint_from_str("12345678901234567890");
  match bs1 {
    Some(b) => {
      if precision_integer.bigint_to_str(b) != "12345678901234567890" { io.println("pi: roundtrip"); return 2; }
    }
    None => { io.println("pi: from_str None"); return 2; }
  }
  var bs2 = precision_integer.bigint_from_str("abc");
  match bs2 {
    Some(_) => { io.println("pi: from_str abc Some"); return 3; }
    None => {}
  }
  var bs3 = precision_integer.bigint_from_str("");
  match bs3 {
    Some(_) => { io.println("pi: from_str empty Some"); return 3; }
    None => {}
  }
  // base conversions
  if precision_integer.bigint_to_hex(precision_integer.bigint_from_int(255)) != "ff" { io.println("pi: to_hex ff"); return 4; }
  if precision_integer.bigint_to_bin(precision_integer.bigint_from_int(10)) != "1010" { io.println("pi: to_bin 1010"); return 4; }
  if precision_integer.bigint_to_oct(precision_integer.bigint_from_int(8)) != "10" { io.println("pi: to_oct 10"); return 4; }
  // arithmetic
  var ba = precision_integer.bigint_from_int(2);
  var bb = precision_integer.bigint_from_int(3);
  if precision_integer.bigint_to_str(precision_integer.bigint_add(ba, bb)) != "5" { io.println("pi: add 2+3"); return 5; }
  if precision_integer.bigint_to_str(precision_integer.bigint_sub(precision_integer.bigint_from_int(7), precision_integer.bigint_from_int(2))) != "5" { io.println("pi: sub 7-2"); return 5; }
  if precision_integer.bigint_to_str(precision_integer.bigint_mul(precision_integer.bigint_from_int(6), precision_integer.bigint_from_int(7))) != "42" { io.println("pi: mul 6*7"); return 5; }
  var dv = precision_integer.bigint_div(precision_integer.bigint_from_int(7), precision_integer.bigint_from_int(2));
  match dv {
    Some(v) => { if precision_integer.bigint_to_str(v) != "3" { io.println("pi: div 7/2"); return 6; } }
    None => { io.println("pi: div 7/2 None"); return 6; }
  }
  var dz = precision_integer.bigint_div(precision_integer.bigint_from_int(7), precision_integer.bigint_from_int(0));
  match dz {
    Some(_) => { io.println("pi: div by zero Some"); return 7; }
    None => {}
  }
  var md = precision_integer.bigint_mod(precision_integer.bigint_from_int(7), precision_integer.bigint_from_int(3));
  match md {
    Some(v) => { if precision_integer.bigint_to_str(v) != "1" { io.println("pi: mod 7%3"); return 8; } }
    None => { io.println("pi: mod 7%3 None"); return 8; }
  }
  var mz = precision_integer.bigint_mod(precision_integer.bigint_from_int(7), precision_integer.bigint_from_int(0));
  match mz {
    Some(_) => { io.println("pi: mod by zero Some"); return 9; }
    None => {}
  }
  if precision_integer.bigint_to_str(precision_integer.bigint_pow(precision_integer.bigint_from_int(2), 10)) != "1024" { io.println("pi: pow 2^10"); return 10; }
  // sign / compare
  if precision_integer.bigint_to_str(precision_integer.bigint_neg(precision_integer.bigint_from_int(5))) != "-5" { io.println("pi: neg 5"); return 11; }
  if precision_integer.bigint_to_str(precision_integer.bigint_abs(precision_integer.bigint_from_int(-5))) != "5" { io.println("pi: abs -5"); return 11; }
  if precision_integer.bigint_compare(precision_integer.bigint_from_int(3), precision_integer.bigint_from_int(5)) != -1 { io.println("pi: cmp 3,5"); return 12; }
  if precision_integer.bigint_compare(precision_integer.bigint_from_int(5), precision_integer.bigint_from_int(3)) != 1 { io.println("pi: cmp 5,3"); return 12; }
  if precision_integer.bigint_compare(precision_integer.bigint_from_int(4), precision_integer.bigint_from_int(4)) != 0 { io.println("pi: cmp 4,4"); return 12; }
  if !precision_integer.bigint_eq(precision_integer.bigint_from_int(4), precision_integer.bigint_from_int(4)) { io.println("pi: eq 4,4"); return 12; }
  if !precision_integer.bigint_lt(precision_integer.bigint_from_int(1), precision_integer.bigint_from_int(2)) { io.println("pi: lt"); return 12; }
  if !precision_integer.bigint_gt(precision_integer.bigint_from_int(9), precision_integer.bigint_from_int(2)) { io.println("pi: gt"); return 12; }
  // bitwise / shifts
  if precision_integer.bigint_to_str(precision_integer.bigint_bit_and(precision_integer.bigint_from_int(12), precision_integer.bigint_from_int(10))) != "8" { io.println("pi: and 12&10"); return 13; }
  if precision_integer.bigint_to_str(precision_integer.bigint_bit_or(precision_integer.bigint_from_int(12), precision_integer.bigint_from_int(10))) != "14" { io.println("pi: or 12|10"); return 13; }
  if precision_integer.bigint_to_str(precision_integer.bigint_bit_xor(precision_integer.bigint_from_int(12), precision_integer.bigint_from_int(10))) != "6" { io.println("pi: xor 12^10"); return 13; }
  if precision_integer.bigint_to_str(precision_integer.bigint_shift_left(precision_integer.bigint_from_int(1), 3)) != "8" { io.println("pi: shl 1<<3"); return 14; }
  if precision_integer.bigint_to_str(precision_integer.bigint_shift_right(precision_integer.bigint_from_int(8), 3)) != "1" { io.println("pi: shr 8>>3"); return 14; }
  if precision_integer.bigint_to_str(precision_integer.bigint_shift_right(precision_integer.bigint_from_int(-8), 1)) != "-4" { io.println("pi: shr -8>>1"); return 14; }
  // number theory
  if !precision_integer.bigint_is_prime(precision_integer.bigint_from_int(97)) { io.println("pi: is_prime 97"); return 15; }
  if precision_integer.bigint_is_prime(precision_integer.bigint_from_int(100)) { io.println("pi: is_prime 100"); return 15; }
  if precision_integer.bigint_to_str(precision_integer.bigint_gcd(precision_integer.bigint_from_int(48), precision_integer.bigint_from_int(18))) != "6" { io.println("pi: gcd 48,18"); return 16; }
  if precision_integer.bigint_to_str(precision_integer.bigint_lcm(precision_integer.bigint_from_int(4), precision_integer.bigint_from_int(6))) != "12" { io.println("pi: lcm 4,6"); return 16; }
  var inv = precision_integer.bigint_mod_inverse(precision_integer.bigint_from_int(3), precision_integer.bigint_from_int(11));
  match inv {
    Some(v) => { if precision_integer.bigint_to_str(v) != "4" { io.println("pi: mod_inverse 3,11"); return 17; } }
    None => { io.println("pi: mod_inverse 3,11 None"); return 17; }
  }
  var invz = precision_integer.bigint_mod_inverse(precision_integer.bigint_from_int(2), precision_integer.bigint_from_int(4));
  match invz {
    Some(_) => { io.println("pi: mod_inverse 2,4 Some"); return 17; }
    None => {}
  }
  if precision_integer.bigint_to_str(precision_integer.bigint_mod_pow(precision_integer.bigint_from_int(2), precision_integer.bigint_from_int(10), precision_integer.bigint_from_int(1000))) != "24" { io.println("pi: mod_pow 2^10 mod 1000"); return 18; }
  if precision_integer.bigint_to_str(precision_integer.bigint_factorial(5)) != "120" { io.println("pi: factorial 5"); return 19; }
  if precision_integer.bigint_to_str(precision_integer.bigint_binomial(10, 3)) != "120" { io.println("pi: binomial 10,3"); return 19; }

  // ================= precision_float =================
  var pf1 = precision_float.bigfloat_from_str("3.14");
  match pf1 {
    Some(b) => {
      if precision_float.bigfloat_to_str(b) != "3.14" { io.println("pf: roundtrip 3.14"); return 20; }
    }
    None => { io.println("pf: from_str 3.14 None"); return 20; }
  }
  var pf2 = precision_float.bigfloat_from_str("abc");
  match pf2 {
    Some(_) => { io.println("pf: from_str abc Some"); return 21; }
    None => {}
  }
  var pf3 = precision_float.bigfloat_from_float(1.5);
  if precision_float.bigfloat_to_str(pf3) != "1.5" { io.println("pf: from_float 1.5"); return 22; }
  // arithmetic: 1.5 + 2.25 = 3.75, 1.5 * 2.25 = 3.375, 5 - 3.5 = 1.5
  var pa = precision_float.bigfloat_from_str("1.5");
  var pb = precision_float.bigfloat_from_str("2.25");
  match pa {
    Some(x) => {
      match pb {
        Some(y) => {
          if precision_float.bigfloat_to_str(precision_float.bigfloat_add(x, y)) != "3.75" { io.println("pf: add 1.5+2.25"); return 23; }
          if precision_float.bigfloat_to_str(precision_float.bigfloat_mul(x, y)) != "3.375" { io.println("pf: mul 1.5*2.25"); return 23; }
          if precision_float.bigfloat_to_str(precision_float.bigfloat_neg(x)) != "-1.5" { io.println("pf: neg 1.5"); return 23; }
          if precision_float.bigfloat_to_str(precision_float.bigfloat_abs(precision_float.bigfloat_neg(x))) != "1.5" { io.println("pf: abs -1.5"); return 23; }
          if precision_float.bigfloat_compare(x, y) != -1 { io.println("pf: compare 1.5,2.25"); return 23; }
        }
        None => { io.println("pf: from_str 2.25 None"); return 23; }
      }
    }
    None => { io.println("pf: from_str 1.5 None"); return 23; }
  }
  var p5a = precision_float.bigfloat_from_str("5");
  var p5b = precision_float.bigfloat_from_str("3.5");
  match p5a {
    Some(x) => {
      match p5b {
        Some(y) => {
          if precision_float.bigfloat_to_str(precision_float.bigfloat_sub(x, y)) != "1.5" { io.println("pf: sub 5-3.5"); return 24; }
        }
        None => { io.println("pf: from_str 3.5 None"); return 24; }
      }
    }
    None => { io.println("pf: from_str 5 None"); return 24; }
  }
  var p1 = precision_float.bigfloat_from_str("1");
  var p4 = precision_float.bigfloat_from_str("4");
  match p1 {
    Some(x) => {
      match p4 {
        Some(y) => {
          var q = precision_float.bigfloat_div(x, y);
          match q {
            Some(v) => { if precision_float.bigfloat_to_str(v) != "0.25" { io.println("pf: div 1/4"); return 25; } }
            None => { io.println("pf: div 1/4 None"); return 25; }
          }
        }
        None => { io.println("pf: from_str 4 None"); return 25; }
      }
    }
    None => { io.println("pf: from_str 1 None"); return 25; }
  }
  var pz = precision_float.bigfloat_from_str("0");
  var pzq = precision_float.bigfloat_from_str("1");
  match pz {
    Some(z) => {
      match pzq {
        Some(one) => {
          var qz = precision_float.bigfloat_div(one, z);
          match qz {
            Some(_) => { io.println("pf: div by zero Some"); return 26; }
            None => {}
          }
        }
        None => { io.println("pf: from_str 1 None"); return 26; }
      }
    }
    None => { io.println("pf: from_str 0 None"); return 26; }
  }
  // sqrt: sqrt(4) = 2; sqrt(-1) = None
  var ps = precision_float.bigfloat_from_str("4");
  match ps {
    Some(x) => {
      var r = precision_float.bigfloat_sqrt(x);
      match r {
        Some(v) => { if precision_float.bigfloat_to_str(v) != "2" { io.println("pf: sqrt 4"); return 27; } }
        None => { io.println("pf: sqrt 4 None"); return 27; }
      }
    }
    None => { io.println("pf: from_str 4 None"); return 27; }
  }
  var pn = precision_float.bigfloat_from_str("-1");
  match pn {
    Some(x) => {
      var r = precision_float.bigfloat_sqrt(x);
      match r {
        Some(_) => { io.println("pf: sqrt -1 Some"); return 28; }
        None => {}
      }
    }
    None => { io.println("pf: from_str -1 None"); return 28; }
  }
  // ln(1) = 0; ln(0) and ln(-1) = None; log10(1) = 0; exp(0) = 1
  var pL1 = precision_float.bigfloat_from_str("1");
  match pL1 {
    Some(x) => {
      var r = precision_float.bigfloat_ln(x);
      match r {
        Some(v) => { if precision_float.bigfloat_to_str(v) != "0" { io.println("pf: ln 1"); return 29; } }
        None => { io.println("pf: ln 1 None"); return 29; }
      }
      var g = precision_float.bigfloat_log10(x);
      match g {
        Some(v) => { if precision_float.bigfloat_to_str(v) != "0" { io.println("pf: log10 1"); return 29; } }
        None => { io.println("pf: log10 1 None"); return 29; }
      }
      var e0r = precision_float.bigfloat_from_str("0");
      match e0r {
        Some(z) => {
          var e0 = precision_float.bigfloat_exp(z);
          if precision_float.bigfloat_to_str(e0) != "1" { io.println("pf: exp 0"); return 29; }
        }
        None => { io.println("pf: from_str 0 None"); return 29; }
      }
    }
    None => { io.println("pf: from_str 1 None"); return 29; }
  }
  var pL0 = precision_float.bigfloat_from_str("0");
  match pL0 {
    Some(x) => {
      var r = precision_float.bigfloat_ln(x);
      match r {
        Some(_) => { io.println("pf: ln 0 Some"); return 30; }
        None => {}
      }
    }
    None => { io.println("pf: from_str 0 None"); return 30; }
  }
  // pow: 10^0 = 1 and 1^5 = 1 (exact short-circuits)
  var pw1 = precision_float.bigfloat_from_str("10");
  var pw2 = precision_float.bigfloat_from_str("0");
  var pw3 = precision_float.bigfloat_from_str("1");
  var pw4 = precision_float.bigfloat_from_str("5");
  match pw1 {
    Some(b10) => {
      match pw2 {
        Some(z) => {
          if precision_float.bigfloat_to_str(precision_float.bigfloat_pow(b10, z)) != "1" { io.println("pf: pow 10^0"); return 31; }
        }
        None => { io.println("pf: from_str 0 None"); return 31; }
      }
    }
    None => { io.println("pf: from_str 10 None"); return 31; }
  }
  match pw3 {
    Some(b1) => {
      match pw4 {
        Some(e5) => {
          if precision_float.bigfloat_to_str(precision_float.bigfloat_pow(b1, e5)) != "1" { io.println("pf: pow 1^5"); return 31; }
        }
        None => { io.println("pf: from_str 5 None"); return 31; }
      }
    }
    None => { io.println("pf: from_str 1 None"); return 31; }
  }
  // pi / e prefixes
  var ppi = precision_float.bigfloat_pi(30);
  var ppis = precision_float.bigfloat_to_str(ppi);
  if !string.str_starts_with(ppis, "3.1415926") { io.println("pf: pi prefix"); return 32; }
  var pee = precision_float.bigfloat_e(30);
  var pees = precision_float.bigfloat_to_str(pee);
  if !string.str_starts_with(pees, "2.718281828") { io.println("pf: e prefix"); return 32; }
  // with_precision: 3.14159 rounded to 3 significant digits = 3.14
  var pw5 = precision_float.bigfloat_from_str("3.14159");
  match pw5 {
    Some(x) => {
      var r = precision_float.bigfloat_with_precision(x, 3);
      if precision_float.bigfloat_to_str(r) != "3.14" { io.println("pf: with_precision 3"); return 33; }
    }
    None => { io.println("pf: from_str 3.14159 None"); return 33; }
  }

  // ================= precision_rational =================
  var rn = precision_rational.bigrat_new(precision_integer.bigint_from_int(1), precision_integer.bigint_from_int(2));
  match rn {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "1/2" { io.println("pr: new 1/2"); return 40; }
    }
    None => { io.println("pr: new 1/2 None"); return 40; }
  }
  var rz = precision_rational.bigrat_new(precision_integer.bigint_from_int(1), precision_integer.bigint_from_int(0));
  match rz {
    Some(_) => { io.println("pr: new den 0 Some"); return 41; }
    None => {}
  }
  var rs = precision_rational.bigrat_from_str("3/4");
  match rs {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "3/4" { io.println("pr: from_str 3/4"); return 42; }
    }
    None => { io.println("pr: from_str 3/4 None"); return 42; }
  }
  var rd = precision_rational.bigrat_from_str("0.5");
  match rd {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "1/2" { io.println("pr: from_str 0.5"); return 43; }
    }
    None => { io.println("pr: from_str 0.5 None"); return 43; }
  }
  var rneg = precision_rational.bigrat_from_str("-1/2");
  match rneg {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "-1/2" { io.println("pr: from_str -1/2"); return 44; }
    }
    None => { io.println("pr: from_str -1/2 None"); return 44; }
  }
  var rint = precision_rational.bigrat_from_str("3");
  match rint {
    Some(r) => {
      if precision_rational.bigrat_to_str(r) != "3" { io.println("pr: from_str 3"); return 45; }
    }
    None => { io.println("pr: from_str 3 None"); return 45; }
  }
  var rbad1 = precision_rational.bigrat_from_str("1/0");
  match rbad1 {
    Some(_) => { io.println("pr: from_str 1/0 Some"); return 46; }
    None => {}
  }
  var rbad2 = precision_rational.bigrat_from_str("abc");
  match rbad2 {
    Some(_) => { io.println("pr: from_str abc Some"); return 46; }
    None => {}
  }
  var rbad3 = precision_rational.bigrat_from_str("");
  match rbad3 {
    Some(_) => { io.println("pr: from_str empty Some"); return 46; }
    None => {}
  }
  // from_int / accessors
  if precision_rational.bigrat_to_str(precision_rational.bigrat_from_int(7)) != "7" { io.println("pr: from_int 7"); return 47; }
  var racc = precision_rational.bigrat_from_str("3/4");
  match racc {
    Some(r) => {
      if precision_integer.bigint_to_str(precision_rational.bigrat_numerator(r)) != "3" { io.println("pr: numerator 3/4"); return 48; }
      if precision_integer.bigint_to_str(precision_rational.bigrat_denominator(r)) != "4" { io.println("pr: denominator 3/4"); return 48; }
    }
    None => { io.println("pr: from_str 3/4 None"); return 48; }
  }
  // arithmetic
  var rA = precision_rational.bigrat_from_str("1/2");
  var rB = precision_rational.bigrat_from_str("1/3");
  match rA {
    Some(x) => {
      match rB {
        Some(y) => {
          if precision_rational.bigrat_to_str(precision_rational.bigrat_add(x, y)) != "5/6" { io.println("pr: add 1/2+1/3"); return 49; }
          if precision_rational.bigrat_to_str(precision_rational.bigrat_mul(x, y)) != "1/6" { io.println("pr: mul 1/2*1/3"); return 49; }
          if precision_rational.bigrat_compare(x, y) != 1 { io.println("pr: compare 1/2,1/3"); return 49; }
        }
        None => { io.println("pr: from_str 1/3 None"); return 49; }
      }
    }
    None => { io.println("pr: from_str 1/2 None"); return 49; }
  }
  var rC = precision_rational.bigrat_from_str("3/4");
  var rD = precision_rational.bigrat_from_str("1/4");
  match rC {
    Some(x) => {
      match rD {
        Some(y) => {
          if precision_rational.bigrat_to_str(precision_rational.bigrat_sub(x, y)) != "1/2" { io.println("pr: sub 3/4-1/4"); return 50; }
        }
        None => { io.println("pr: from_str 1/4 None"); return 50; }
      }
    }
    None => { io.println("pr: from_str 3/4 None"); return 50; }
  }
  var rE = precision_rational.bigrat_from_str("1/2");
  var rF = precision_rational.bigrat_from_str("1/4");
  match rE {
    Some(x) => {
      match rF {
        Some(y) => {
          var q = precision_rational.bigrat_div(x, y);
          match q {
            Some(v) => { if precision_rational.bigrat_to_str(v) != "2" { io.println("pr: div 1/2 / 1/4"); return 51; } }
            None => { io.println("pr: div None"); return 51; }
          }
        }
        None => { io.println("pr: from_str 1/4 None"); return 51; }
      }
    }
    None => { io.println("pr: from_str 1/2 None"); return 51; }
  }
  var rZ = precision_rational.bigrat_from_str("0");
  match rZ {
    Some(z) => {
      var qz = precision_rational.bigrat_div(precision_rational.bigrat_from_int(1), z);
      match qz {
        Some(_) => { io.println("pr: div by zero Some"); return 52; }
        None => {}
      }
    }
    None => { io.println("pr: from_str 0 None"); return 52; }
  }
  // neg / abs / recip / reduce
  var rG = precision_rational.bigrat_from_str("1/2");
  match rG {
    Some(x) => {
      if precision_rational.bigrat_to_str(precision_rational.bigrat_neg(x)) != "-1/2" { io.println("pr: neg 1/2"); return 53; }
      if precision_rational.bigrat_to_str(precision_rational.bigrat_abs(precision_rational.bigrat_neg(x))) != "1/2" { io.println("pr: abs -1/2"); return 53; }
    }
    None => { io.println("pr: from_str 1/2 None"); return 53; }
  }
  var rH = precision_rational.bigrat_from_str("2/3");
  match rH {
    Some(x) => {
      var r = precision_rational.bigrat_recip(x);
      match r {
        Some(v) => { if precision_rational.bigrat_to_str(v) != "3/2" { io.println("pr: recip 2/3"); return 54; } }
        None => { io.println("pr: recip 2/3 None"); return 54; }
      }
    }
    None => { io.println("pr: from_str 2/3 None"); return 54; }
  }
  var rI = precision_rational.bigrat_from_str("4/6");
  match rI {
    Some(x) => {
      if precision_rational.bigrat_to_str(precision_rational.bigrat_reduce(x)) != "2/3" { io.println("pr: reduce 4/6"); return 55; }
      if !precision_rational.bigrat_is_reduced(x) { io.println("pr: is_reduced 4/6 reduced"); return 55; }
    }
    None => { io.println("pr: from_str 4/6 None"); return 55; }
  }
  // predicates
  var rJ = precision_rational.bigrat_from_str("1/2");
  var rK = precision_rational.bigrat_from_str("4");
  var rL = precision_rational.bigrat_from_str("2/4");
  match rJ {
    Some(h) => {
      match rK {
        Some(four) => {
          if !precision_rational.bigrat_is_integer(four) { io.println("pr: is_integer 4"); return 56; }
          if precision_rational.bigrat_is_integer(h) { io.println("pr: is_integer 1/2"); return 56; }
          if precision_rational.bigrat_is_zero(h) { io.println("pr: is_zero 1/2"); return 56; }
          match rL {
            Some(l) => {
              var zz = precision_rational.bigrat_from_str("0");
              match zz {
                Some(zv) => {
                  if !precision_rational.bigrat_is_zero(zv) { io.println("pr: is_zero 0"); return 56; }
                }
                None => { io.println("pr: from_str 0 None"); return 56; }
              }
              if !precision_rational.bigrat_eq(h, l) { io.println("pr: eq 1/2, 2/4"); return 56; }
              if precision_rational.bigrat_compare(l, h) != 0 { io.println("pr: compare 2/4,1/2"); return 56; }
            }
            None => { io.println("pr: from_str 2/4 None"); return 56; }
          }
        }
        None => { io.println("pr: from_str 4 None"); return 56; }
      }
    }
    None => { io.println("pr: from_str 1/2 None"); return 56; }
  }
  // to_float
  var rM = precision_rational.bigrat_from_str("1/2");
  match rM {
    Some(h) => {
      var tv = precision_rational.bigrat_to_float(h);
      var td = tv - 0.5;
      if td < 0.0 { td = -td; }
      if td >= 1.0e-9 { io.println("pr: to_float 1/2"); return 57; }
    }
    None => { io.println("pr: from_str 1/2 None"); return 57; }
  }
  // to_integer
  var rN = precision_rational.bigrat_from_str("6/3");
  match rN {
    Some(six3) => {
      var ti = precision_rational.bigrat_to_integer(six3);
      match ti {
        Some(v) => { if precision_integer.bigint_to_str(v) != "2" { io.println("pr: to_integer 6/3"); return 58; } }
        None => { io.println("pr: to_integer 6/3 None"); return 58; }
      }
    }
    None => { io.println("pr: from_str 6/3 None"); return 58; }
  }
  var rO = precision_rational.bigrat_from_str("1/2");
  match rO {
    Some(h) => {
      var ti = precision_rational.bigrat_to_integer(h);
      match ti {
        Some(_) => { io.println("pr: to_integer 1/2 Some"); return 59; }
        None => {}
      }
    }
    None => { io.println("pr: from_str 1/2 None"); return 59; }
  }
  io.println("smoke_num_precision: OK");
  return 0;
}
