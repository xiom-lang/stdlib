// kat_num_bigint.xi -- arbitrary-precision integer known-answer tests
// Expected values computed with python 3.x arbitrary integers (oracle).
// Locks: from_str/to_str round trips, mul, doubling chains, div_mod
// identity, and sign handling.
module kat_num_bigint
use xiom.num.bigint;
use xiom.io;

fn expect(tag: Str, b: &BigInt, want: Str, code: Int) -> Int {
  var got = bigint_to_str(b);
  if got != want {
    io.println("bigint " + tag + ": " + got);
    return code;
  }
  return 0;
}

fn main() -> Int {
  // ---- factorial(20) via repeated mul ----
  var f = bigint_from_int(1);
  var i = 2;
  while i <= 20 {
    var fi = bigint_from_int(i);
    f = bigint_mul(&f, &fi);
    i += 1;
  }
  var r = expect("fact20", &f, "2432902008176640000", 1);
  if r != 0 { return r; }

  // ---- 2^100 and 2^128 via doubling chains ----
  var p = bigint_from_int(1);
  i = 0;
  while i < 100 {
    p = bigint_add(&p, &p);
    i += 1;
  }
  r = expect("2^100", &p, "1267650600228229401496703205376", 2);
  if r != 0 { return r; }

  i = 0;
  while i < 28 {
    p = bigint_add(&p, &p);
    i += 1;
  }
  r = expect("2^128", &p, "340282366920938463463374607431768211456", 3);
  if r != 0 { return r; }

  // ---- (2^64-1)^2 ----
  var m = bigint_from_str("18446744073709551615");
  match m {
    Ok(mv) => {
      var sq = bigint_mul(&mv, &mv);
      r = expect("sq(2^64-1)", &sq, "340282366920938463426481119284349108225", 4);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("from_str err " + e); return 5; }
  }

  // ---- div_mod identity on 10^30 / 123456789 ----
  var a = bigint_from_str("1000000000000000000000000000000");
  var b = bigint_from_str("123456789");
  match a {
    Ok(av) => {
      match b {
        Ok(bv) => {
          var qr = bigint_div_mod(&av, &bv);
          r = expect("q", &qr.0, "8100000073710000670761", 6);
          if r != 0 { return r; }
          r = expect("r", &qr.1, "753571", 7);
          if r != 0 { return r; }
          // identity: q*b + r == a
          var qb = bigint_mul(&qr.0, &bv);
          var back = bigint_add(&qb, &qr.1);
          r = expect("divmod-identity", &back, "1000000000000000000000000000000", 8);
          if r != 0 { return r; }
        }
        Err(e) => { io.println("from_str err " + e); return 9; }
      }
    }
    Err(e) => { io.println("from_str err " + e); return 10; }
  }

  // ---- sign handling ----
  match bigint_from_str("-42") {
    Ok(neg) => {
      r = expect("neg-literal", &neg, "-42", 11);
      if r != 0 { return r; }
      var zero = bigint_from_int(0);
      var d = bigint_sub(&zero, &neg);
      r = expect("0-(-42)", &d, "42", 12);
      if r != 0 { return r; }
      var nn = bigint_sub(&neg, &neg);
      r = expect("neg-neg", &nn, "0", 13);
      if r != 0 { return r; }
    }
    Err(e) => { io.println("from_str neg err " + e); return 14; }
  }

  io.println("OK");
  return 0;
}
