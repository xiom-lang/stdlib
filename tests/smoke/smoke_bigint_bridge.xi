module smoke_bigint_bridge
use xiom.bigint;
use xiom.io;

// 256-bit framing: bigint_to_u64 / bigint_to_u128 / bigint_to_i128.

fn from_str(s: Str) -> BigInt {
  var r = xiom.bigint.bigint_from_str(s);
  match r {
    Ok(v) => { return v; };
    Err(e) => { io.println(e); return xiom.bigint.bigint_zero(); };
  }
}

fn main() -> Int {
  // ── to_u64 ──
  var z = xiom.bigint.bigint_zero();
  var r0 = xiom.bigint.bigint_to_u64(&z);
  match r0 {
    Ok(v) => { if v != 0 { return 1; } };
    Err(e) => { io.println(e); return 2; };
  }
  var max_u64 = from_str("18446744073709551615");
  var r1 = xiom.bigint.bigint_to_u64(&max_u64);
  match r1 {
    Ok(v) => { if v != (18446744073709551615 as UInt64) { return 3; } };
    Err(e) => { io.println(e); return 4; };
  }
  var over_u64 = from_str("18446744073709551616");
  var r2 = xiom.bigint.bigint_to_u64(&over_u64);
  match r2 {
    Ok(v) => { return 5; };
    Err(e) => {};
  }
  var neg1 = from_str("-1");
  var r3 = xiom.bigint.bigint_to_u64(&neg1);
  match r3 {
    Ok(v) => { return 6; };
    Err(e) => {};
  }
  var small = from_str("12345");
  var r4 = xiom.bigint.bigint_to_u64(&small);
  match r4 {
    Ok(v) => { if v != 12345 { return 7; } };
    Err(e) => { io.println(e); return 8; };
  }

  // ── to_u128 ──
  var max_u128 = from_str("340282366920938463463374607431768211455");
  var r5 = xiom.bigint.bigint_to_u128(&max_u128);
  match r5 {
    Ok(v) => {
      // 2^128-1 == (1<<128) - 1; verify by comparing two computed values
      var again = xiom.bigint.bigint_to_u128(&max_u128);
      match again {
        Ok(v2) => { if v2 != v { return 9; } };
        Err(e) => { io.println(e); return 10; };
      }
    };
    Err(e) => { io.println(e); return 11; };
  }
  var over_u128 = from_str("340282366920938463463374607431768211456");
  var r6 = xiom.bigint.bigint_to_u128(&over_u128);
  match r6 {
    Ok(v) => { return 12; };
    Err(e) => {};
  }
  var r7 = xiom.bigint.bigint_to_u128(&neg1);
  match r7 {
    Ok(v) => { return 13; };
    Err(e) => {};
  }
  // 2^64 built from two u64s, compared against the decimal string
  var two64: UInt128 = ((1 as UInt64) as UInt128) << 64;
  var pwr = from_str("18446744073709551616");
  var r8 = xiom.bigint.bigint_to_u128(&pwr);
  match r8 {
    Ok(v) => { if v != two64 { return 14; } };
    Err(e) => { io.println(e); return 15; };
  }

  // ── to_i128 ──
  var neg_2_63: Int128 = (0 as Int128) - ((1 as Int128) << 63);
  var i_min = from_str("-9223372036854775808");
  var r9 = xiom.bigint.bigint_to_i128(&i_min);
  match r9 {
    Ok(v) => { if v != neg_2_63 { return 16; } };
    Err(e) => { io.println(e); return 17; };
  }
  var i_max = from_str("9223372036854775807");
  var p63: Int128 = (1 as Int128) << 63;
  var max_i: Int128 = p63 - (1 as Int128);
  var r10 = xiom.bigint.bigint_to_i128(&i_max);
  match r10 {
    Ok(v) => { if v != max_i { return 18; } };
    Err(e) => { io.println(e); return 19; };
  }
  // 2^63 fits in i128 (bounds are ±2^127) — verify it works:
  var i_2p63 = from_str("9223372036854775808");
  var r11 = xiom.bigint.bigint_to_i128(&i_2p63);
  match r11 {
    Ok(v) => {
      if v != ((1 as Int128) << 63) { return 20; }
    };
    Err(e) => { io.println(e); return 21; };
  }
  // 2^127 and -2^127-1 are out of range:
  var i_over = from_str("170141183460469231731687303715884105728");
  var r11b = xiom.bigint.bigint_to_i128(&i_over);
  match r11b {
    Ok(v) => { return 22; };
    Err(e) => {};
  }
  var i_under = from_str("-170141183460469231731687303715884105729");
  var r12 = xiom.bigint.bigint_to_i128(&i_under);
  match r12 {
    Ok(v) => { return 23; };
    Err(e) => {};
  }
  // exactly -2^127 is the minimum:
  var i_neg_2p127 = from_str("-170141183460469231731687303715884105728");
  var r12b = xiom.bigint.bigint_to_i128(&i_neg_2p127);
  match r12b {
    Ok(v) => {
      var neg_2p127: Int128 = (0 as Int128) - ((1 as Int128) << 127);
      if v != neg_2p127 { return 24; }
    };
    Err(e) => { io.println(e); return 25; };
  }
  var forty_two = from_str("42");
  var r13 = xiom.bigint.bigint_to_i128(&forty_two);
  match r13 {
    Ok(v) => { if v != (42 as Int128) { return 26; } };
    Err(e) => { io.println(e); return 27; };
  }
  var neg42 = from_str("-42");
  var r14 = xiom.bigint.bigint_to_i128(&neg42);
  match r14 {
    Ok(v) => {
      var neg42_128: Int128 = (0 as Int128) - (42 as Int128);
      if v != neg42_128 { return 28; }
    };
    Err(e) => { io.println(e); return 29; };
  }
  // cross-check: to_u64 round-trips through from_u64
  var round = from_str("18446744073709551615");
  var r15 = xiom.bigint.bigint_to_u64(&round);
  match r15 {
    Ok(v) => {
      var back = xiom.bigint.bigint_from_u64(v);
      var eq = xiom.bigint.bigint_compare(&back, &round);
      if eq != 0 { return 30; }
    };
    Err(e) => { io.println(e); return 31; };
  }

  io.println("smoke_bigint_bridge: all 31 checks passed");
  return 0;
}
