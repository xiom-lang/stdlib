// XIOM stdlib fuzz smoke -- bigint/bigfloat mutation harness (roadmap A3).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Deterministic mutation fuzzing for the arbitrary-precision parsers and
// formatters. Contract:
//   - no parse/format crash, abort or hang on any input;
//   - an accepted value round-trips through its canonical writer and
//     re-parses to the same value (bigint: str/hex/base36; bigfloat:
//     scientific notation);
//   - arithmetic invariants hold on bounded accepted values:
//     a+0==a, a-a==0, a*1==a, a*0==0, div_mod identity and |r| < |b|,
//     v+0==v, v-v==0, v*1==v, v*0==0, neg(neg(v))==v, abs(v)>=0.
// Seeds and iteration count come from XIOM_FUZZ_SEED / XIOM_FUZZ_ITERS so the
// nightly workflow can broaden the corpus without changing the source. The
// defaults are cheap enough for the normal smoke corpus.
// Returns 0 on success, a unique error code on failure.

module smoke_fuzz_bignum
use xiom.bigint;
use xiom.num.bigfloat;
use xiom.string;
use xiom.io;
use xiom.env;

fn next_seed(s: Int) -> Int {
  (s * 1103515245 + 12345) % 2147483648
}

fn pick(alphabet: Str, idx: Int) -> Str {
  string.str_slice(alphabet, idx, idx + 1)
}

fn random_from(seed: Int, len: Int, alphabet: Str) -> Str {
  let n = string.str_len(alphabet);
  var s = seed;
  var out = "";
  var i = 0;
  while i < len {
    s = next_seed(s);
    out = out + pick(alphabet, s % n);
    i = i + 1;
  };
  out
}

fn mutate(seed: Int, sample: Str, alphabet: Str) -> Str {
  let len = string.str_len(sample);
  if len == 0 { return sample; };
  var s = seed;
  s = next_seed(s);
  let mode = s % 4;
  s = next_seed(s);
  let pos = s % len;
  if mode == 0 {
    return string.str_slice(sample, 0, pos);
  };
  if mode == 1 {
    s = next_seed(s);
    let ch = pick(alphabet, s % string.str_len(alphabet));
    return string.str_slice(sample, 0, pos) + ch + string.str_slice(sample, pos + 1, len);
  };
  if mode == 2 {
    let ch = pick(sample, pos);
    return string.str_slice(sample, 0, pos) + ch + string.str_slice(sample, pos, len);
  };
  let ch = pick(sample, pos);
  return string.str_slice(sample, 0, pos) + ch + ch + string.str_slice(sample, pos, len);
}

fn env_int(name: Str, dflt: Int) -> Int {
  let raw = env.var_or(name, "");
  var result = dflt;
  if raw != "" {
    match string.str_to_int(raw) {
      Ok(n) => { if n > 0 { result = n; } },
      Err(_) => {},
    };
  };
  result
}

fn is_digit(ch: Str) -> Bool {
  if ch == "0" { return true; }
  if ch == "1" { return true; }
  if ch == "2" { return true; }
  if ch == "3" { return true; }
  if ch == "4" { return true; }
  if ch == "5" { return true; }
  if ch == "6" { return true; }
  if ch == "7" { return true; }
  if ch == "8" { return true; }
  if ch == "9" { return true; }
  return false;
}

// Keep bigfloat exponents in a bounded range before doing arithmetic or
// fixed-notation work; 1e999999 is safe to parse but not safe to materialize.
fn bounded_exp(s: Str) -> Bool {
  var i = 0;
  let n = string.str_len(s);
  while i < n {
    let ch = string.str_slice(s, i, i + 1);
    if ch == "e" || ch == "E" {
      var j = i + 1;
      if j < n {
        let sg = string.str_slice(s, j, j + 1);
        if sg == "+" || sg == "-" { j = j + 1; };
      };
      var count = 0;
      while j < n {
        if !is_digit(string.str_slice(s, j, j + 1)) { break; };
        count = count + 1;
        j = j + 1;
      };
      if count == 0 || count > 2 { return false; };
      i = j;
    } else {
      i = i + 1;
    };
  };
  return true;
}

fn check_bigint_value(v: BigInt) -> Int {
  let s = xiom.bigint.bigint_to_str(&v);
  if s == "" {
    io.println("fuzz-bignum: bigint_to_str empty");
    return 110;
  };
  match xiom.bigint.bigint_from_str(s) {
    Ok(v2) => {
      if !xiom.bigint.bigint_eq(&v, &v2) {
        io.println("fuzz-bignum: bigint str round-trip: " + s);
        return 111;
      }
    },
    Err(_) => {
      io.println("fuzz-bignum: canonical bigint rejected: " + s);
      return 112;
    },
  };
  let zero = xiom.bigint.bigint_is_zero(&v);
  if zero != (s == "0") {
    io.println("fuzz-bignum: bigint zero/str mismatch: " + s);
    return 113;
  };
  let sign = xiom.bigint.bigint_sign(&v);
  if sign < -1 || sign > 1 { return 114; }
  if zero && sign != 0 { return 114; }
  if !zero && sign == 0 { return 114; }
  if xiom.bigint.bigint_is_negative(&v) != (sign == -1) { return 115; }

  let h = xiom.bigint.bigint_to_hex(&v);
  match xiom.bigint.bigint_from_hex(h) {
    Ok(hv) => {
      if !xiom.bigint.bigint_eq(&v, &hv) {
        io.println("fuzz-bignum: bigint hex round-trip: " + s);
        return 116;
      }
    },
    Err(_) => {
      io.println("fuzz-bignum: canonical hex rejected: " + h);
      return 117;
    },
  };

  let b36 = xiom.bigint.bigint_to_base(&v, 36);
  match xiom.bigint.bigint_from_base(b36, 36) {
    Ok(bv) => {
      if !xiom.bigint.bigint_eq(&v, &bv) {
        io.println("fuzz-bignum: bigint base36 round-trip: " + s);
        return 118;
      }
    },
    Err(_) => {
      io.println("fuzz-bignum: canonical base36 rejected: " + b36);
      return 119;
    },
  };

  if string.str_len(s) <= 128 {
    let z = xiom.bigint.bigint_zero();
    let one = xiom.bigint.bigint_one();
    if !xiom.bigint.bigint_eq(&xiom.bigint.bigint_add(&v, &z), &v) { return 120; }
    if !xiom.bigint.bigint_is_zero(&xiom.bigint.bigint_sub(&v, &v)) { return 121; }
    if !xiom.bigint.bigint_eq(&xiom.bigint.bigint_mul(&v, &one), &v) { return 122; }
    if !xiom.bigint.bigint_is_zero(&xiom.bigint.bigint_mul(&v, &z)) { return 123; }
    let d = xiom.bigint.bigint_from_int(97);
    let dm = xiom.bigint.bigint_div_mod(&v, &d);
    let check = xiom.bigint.bigint_add(&xiom.bigint.bigint_mul(&dm.0, &d), &dm.1);
    if !xiom.bigint.bigint_eq(&check, &v) {
      io.println("fuzz-bignum: bigint div_mod identity: " + s);
      return 124;
    };
    let ar = xiom.bigint.bigint_abs(&dm.1);
    if xiom.bigint.bigint_compare(&ar, &d) >= 0 {
      io.println("fuzz-bignum: bigint remainder bound: " + s);
      return 125;
    };
  };
  return 0;
}

fn check_bigint_parsers(input: Str) -> Int {
  match xiom.bigint.bigint_from_str(input) {
    Ok(v) => {
      let rc = check_bigint_value(v);
      if rc != 0 { return rc; }
    },
    Err(_) => {},
  };
  match xiom.bigint.bigint_from_hex(input) {
    Ok(v) => {
      let rc = check_bigint_value(v);
      if rc != 0 { return rc; }
    },
    Err(_) => {},
  };
  var bases = Vec[Int].new();
  bases.push(2);
  bases.push(8);
  bases.push(16);
  bases.push(36);
  var i = 0;
  while i < bases.len() {
    match xiom.bigint.bigint_from_base(input, bases[i]) {
      Ok(v) => {
        let rc = check_bigint_value(v);
        if rc != 0 { return rc; }
      },
      Err(_) => {},
    };
    i = i + 1;
  };
  return 0;
}

fn check_bigfloat_value(v: BigFloat) -> Int {
  let sci = xiom.num.bigfloat.bigfloat_to_str_sci(&v, 24);
  if sci == "" { return 130; }
  match xiom.num.bigfloat.bigfloat_from_str(sci) {
    Ok(v2) => {
      let sci2 = xiom.num.bigfloat.bigfloat_to_str_sci(&v2, 24);
      if sci != sci2 {
        io.println("fuzz-bignum: bigfloat sci round-trip: " + sci + " vs " + sci2);
        return 131;
      }
    },
    Err(_) => {
      io.println("fuzz-bignum: canonical bigfloat rejected: " + sci);
      return 132;
    },
  };
  let sign = xiom.num.bigfloat.bigfloat_sign(&v);
  if sign < -1 || sign > 1 { return 133; }
  if xiom.num.bigfloat.bigfloat_is_zero(&v) != (sign == 0) { return 133; }
  if xiom.num.bigfloat.bigfloat_precision(&v) <= 0 { return 134; }

  let bi = xiom.num.bigfloat.bigfloat_to_bigint(&v);
  if xiom.bigint.bigint_to_str(&bi) == "" { return 135; }
  match xiom.num.bigfloat.bigfloat_to_float64(&v) {
    Some(_) => {},
    None => {},
  };

  if string.str_len(sci) <= 96 {
    let z = xiom.num.bigfloat.bigfloat_zero();
    let one = xiom.num.bigfloat.bigfloat_one();
    if !xiom.num.bigfloat.bigfloat_eq(&xiom.num.bigfloat.bigfloat_add(&v, &z), &v) { return 136; }
    if !xiom.num.bigfloat.bigfloat_eq(&xiom.num.bigfloat.bigfloat_sub(&v, &v), &z) { return 137; }
    if !xiom.num.bigfloat.bigfloat_eq(&xiom.num.bigfloat.bigfloat_mul(&v, &one), &v) { return 138; }
    if !xiom.num.bigfloat.bigfloat_eq(&xiom.num.bigfloat.bigfloat_mul(&v, &z), &z) { return 139; }
    if !xiom.num.bigfloat.bigfloat_eq(&xiom.num.bigfloat.bigfloat_neg(&xiom.num.bigfloat.bigfloat_neg(&v)), &v) { return 140; }
    if !xiom.num.bigfloat.bigfloat_ge(&xiom.num.bigfloat.bigfloat_abs(&v), &z) { return 141; }
  };
  return 0;
}

fn check_bigfloat_parser(input: Str) -> Int {
  match xiom.num.bigfloat.bigfloat_from_str(input) {
    Ok(v) => {
      // The scientific writer is bounded, so the round-trip is safe even for
      // an accepted huge exponent; materializing/arithmetic is gated below.
      if bounded_exp(input) {
        return check_bigfloat_value(v);
      };
      let sci = xiom.num.bigfloat.bigfloat_to_str_sci(&v, 24);
      if sci == "" { return 130; }
      match xiom.num.bigfloat.bigfloat_from_str(sci) {
        Ok(v2) => {
          if xiom.num.bigfloat.bigfloat_to_str_sci(&v2, 24) != sci {
            io.println("fuzz-bignum: bigfloat sci round-trip (unbounded): " + sci);
            return 131;
          };
        },
        Err(_) => { return 132; },
      };
      return 0;
    },
    Err(_) => {},
  };
  return 0;
}

fn gen_bigint(seed: Int) -> Str {
  var s = seed;
  s = next_seed(s);
  let mode = s % 5;
  if mode == 0 {
    return random_from(s, s % 40, "0123456789abcdefABCDEFxXbo+-_ .eE\t\n");
  };
  if mode == 1 {
    return mutate(s, "123456789012345678901234567890", "0123456789+-xX_ ");
  };
  if mode == 2 {
    return mutate(s, "-0xDEADBEEF", "0123456789abcdefABCDEFxX+-");
  };
  if mode == 3 {
    return mutate(s, "0b1010", "01b+-_");
  };
  var out = "";
  s = next_seed(s);
  if s % 3 == 0 { out = "-"; };
  s = next_seed(s);
  let len = s % 40;
  var i = 0;
  while i < len {
    s = next_seed(s);
    out = out + pick("0123456789", s % 10);
    i = i + 1;
  };
  if out == "" || out == "-" { out = out + "0"; };
  return out;
}

fn gen_bigfloat(seed: Int) -> Str {
  var s = seed;
  s = next_seed(s);
  let mode = s % 4;
  if mode == 0 {
    return random_from(s, s % 24, "0123456789.eE+- ");
  };
  if mode == 1 {
    return mutate(s, "3.14159", "0123456789.eE+-");
  };
  if mode == 2 {
    return mutate(s, "-1.5e-10", "0123456789.eE+-");
  };
  var out = "";
  s = next_seed(s);
  if s % 3 == 0 { out = "-"; };
  s = next_seed(s);
  let ip = s % 100000;
  s = next_seed(s);
  let fp = s % 100000;
  s = next_seed(s);
  let expo = (s % 41) - 20;
  out = out + ip.to_str();
  if s % 2 == 0 { out = out + "." + fp.to_str(); };
  if s % 5 == 0 { out = out + "e" + expo.to_str(); };
  return out;
}

fn main() -> Int {
  let iters = env_int("XIOM_FUZZ_ITERS", 120);
  let base = env_int("XIOM_FUZZ_SEED", 20261106);
  var run = 0;
  while run < 3 {
    var seed = base + run * 7919;
    var i = 0;
    while i < iters {
      seed = next_seed(seed);
      let bi = gen_bigint(seed);
      let rc1 = check_bigint_parsers(bi);
      if rc1 != 0 {
        io.println("fuzz-bignum: bigint input=" + bi);
        return rc1;
      };
      seed = next_seed(seed);
      let bf = gen_bigfloat(seed);
      let rc2 = check_bigfloat_parser(bf);
      if rc2 != 0 {
        io.println("fuzz-bignum: bigfloat input=" + bf);
        return rc2;
      };
      i = i + 1;
    };
    run = run + 1;
  };
  io.println("fuzz-bignum: 3 seeds x " + iters.to_str() + " inputs OK");
  return 0;
}
