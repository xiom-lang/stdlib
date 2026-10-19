// p_wave188_num_contracts.xi -- wave 188 lock: xiom.num contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime requires/ensures clauses, so a
// clause that is false on a real return aborts this probe. Rows (0 = all hold):
//  1  -- fraction_new normalizes sign/reduction, keeps den > 0, zero is 0/1
//  2  -- fraction_from_str payload keeps den > 0 (parser invariant)
//  3  -- modular add/sub/mul stay in [0, m) even when the i64 product wraps
//  4  -- modular zero/degenerate laws: m == 1, exp < 0, non-invertible zero
//  5  -- Euclidean remainder is non-negative; division-by-zero returns 0
//  6  -- clamp results stay inside [lo, hi] (integer and floating point)
//  7  -- float floor/ceil/trunc/fract contract bounds, NaN propagation
//  8  -- checked zero-identity laws and saturating clamps
//  9  -- parse/format domains: empty input, invalid base, zero formatting
// 10  -- number-theory domain laws: primes, divisors, totient, combinatorics
// 11  -- Int128 shift/conversion boundaries and zero formatting
// 12  -- float<->int conversion Option and payload invariants
// 13  -- lerp/remap/inverse-lerp range and degenerate laws
// 14  -- fraction arithmetic zero laws and reciprocal/pow degenerate edges
// Returns 0 when every case holds.

module p_wave188_num_contracts

use xiom.num;

fn main() -> Int {
  var nan = 0.0 / 0.0;

  // 1: fraction construction normalizes sign and reduction.
  var f = num.fraction_new(6, -8);
  if f.num != -3 || f.den != 4 { return 1; }
  var zf = num.fraction_new(0, -5);
  if zf.num != 0 || zf.den != 1 { return 2; }
  var dz = num.fraction_new(7, 0);
  if dz.num != 0 || dz.den != 1 { return 3; }

  // 2: fraction_from_str only yields normalized payloads.
  var p = num.fraction_from_str("3/-4");
  if !p.is_some { return 4; }
  if p.value.num != -3 || p.value.den != 4 { return 5; }
  var pe = num.fraction_from_str("");
  if pe.is_some { return 6; }

  // 3: modular results stay in [0, m) even through overflow.
  var r1 = num.mod_add(9223372036854775807, 9223372036854775807, 1000);
  if r1 < 0 || r1 >= 1000 { return 7; }
  var r2 = num.mod_sub(-9223372036854775807 - 1, 9223372036854775807, 97);
  if r2 < 0 || r2 >= 97 { return 8; }
  var r3 = num.mod_mul(9223372036854775807, 9223372036854775807, 1000);
  if r3 < 0 || r3 >= 1000 { return 9; }

  // 4: modular degenerate laws.
  if num.mod_pow(2, 10, 1) != 0 { return 10; }
  if num.mod_pow(2, -1, 7) != 0 { return 11; }
  var inv0 = num.mod_inverse(0, 7);
  if inv0.is_some { return 12; }
  var inv1 = num.mod_inverse(5, 1);
  if !inv1.is_some { return 13; }
  if inv1.value != 0 { return 14; }

  // 5: Euclidean remainder/division shapes.
  if num.i64_mod_euclid(-7, 2) != 1 { return 15; }
  if num.i64_mod_euclid(7, -2) != 1 { return 16; }
  if num.i64_mod_euclid(-7, -2) != 1 { return 17; }
  if num.i64_mod_euclid(5, 0) != 0 { return 18; }
  if num.i64_div_floor(7, 0) != 0 { return 19; }
  if num.i64_div_ceil(7, 0) != 0 { return 20; }
  if num.i64_div_round(0, 7) != 0 { return 21; }

  // 6: clamp range laws (float clamp propagates NaN).
  if num.i64_clamp(9, 1, 3) != 3 { return 22; }
  if num.i64_clamp(-9, 1, 3) != 1 { return 23; }
  if num.i64_clamp(2, 1, 3) != 2 { return 24; }
  if (num.u64_clamp(9 as UInt64, 1 as UInt64, 3 as UInt64) as Int) != 3 { return 25; }
  if (num.u64_clamp(0 as UInt64, 1 as UInt64, 3 as UInt64) as Int) != 1 { return 26; }
  var fc = num.f64_clamp(nan, 0.0, 1.0);
  if fc == fc { return 27; }
  if num.f64_clamp(9.0, 0.0, 3.0) != 3.0 { return 28; }

  // 7: float rounding contract bounds.
  if num.f64_floor(3.9) != 3.0 { return 29; }
  if num.f64_floor(-3.9) != -4.0 { return 30; }
  if num.f64_ceil(3.1) != 4.0 { return 31; }
  if num.f64_ceil(-3.1) != -3.0 { return 32; }
  if num.f64_trunc(-3.9) != -3.0 { return 33; }
  if num.f64_trunc(0.5) != 0.0 { return 34; }
  var fr = num.f64_fract(2.75);
  if fr != 0.75 { return 35; }
  var frn = num.f64_fract(-2.75);
  if frn != -0.75 { return 36; }
  if (num.f32_floor(3.9 as Float32) as Float64) != 3.0 { return 37; }
  if (num.f32_ceil(-3.1 as Float32) as Float64) != -3.0 { return 38; }
  if (num.f32_trunc(0.5 as Float32) as Float64) != 0.0 { return 39; }
  var nfloor = num.f64_floor(nan);
  if nfloor == nfloor { return 40; }
  var nfract = num.f32_fract(nan as Float32);
  if (nfract as Float64) == (nfract as Float64) { return 41; }

  // 8: checked/saturating identity and clamp laws.
  match num.checked_add(5, 0) {
    Some(v) => { if v != 5 { return 42; } }
    None => { return 43; }
  };
  match num.checked_mul(0, 7) {
    Some(v) => { if v != 0 { return 44; } }
    None => { return 45; }
  };
  match num.checked_div(5, 0) {
    Some(_) => { return 46; }
    None => {}
  };
  if num.saturating_add(9223372036854775807, 1) != 9223372036854775807 { return 47; }
  if num.saturating_sub(-9223372036854775807 - 1, 1) != -9223372036854775807 - 1 { return 48; }
  if num.saturating_mul(0, -5) != 0 { return 49; }
  if num.i64_add_sat(2, 3) != 5 { return 50; }
  if num.i64_mul_sat(1, -5) != -5 { return 51; }
  if (num.u64_sub_sat(1 as UInt64, 2 as UInt64) as Int) != 0 { return 52; }

  // 9: parse/format domains.
  match num.parse_int("") {
    Ok(_) => { return 53; }
    Err(_) => {}
  };
  match num.parse_float("") {
    Ok(_) => { return 54; }
    Err(_) => {}
  };
  if num.to_base(0, 10) != "0" { return 55; }
  if num.to_base(5, 1) != "" { return 56; }
  if num.to_base(5, 40) != "" { return 57; }
  var fb = num.from_base("", 10);
  if fb.is_some { return 58; }

  // 10: number-theory domain laws.
  if !num.is_prime(2) { return 59; }
  if num.is_prime(1) { return 60; }
  if num.is_prime(-7) { return 61; }
  if num.next_prime(0) != 2 { return 62; }
  if num.nth_prime(0) != 0 { return 63; }
  if num.nth_prime(1) != 2 { return 64; }
  if num.prime_factors(1).len() != 0 { return 65; }
  if num.divisors(0).len() != 0 { return 66; }
  if num.euler_totient(12) != 4 { return 67; }
  if num.factorial(0) != 1 { return 68; }
  if num.factorial(-1) != 0 { return 69; }
  if num.binomial(5, 0) != 1 { return 70; }
  if num.binomial(3, 5) != 0 { return 71; }
  if num.digit_count(0) != 1 { return 72; }
  if num.digit_sum(0) != 0 { return 73; }
  if num.digital_root(12345) != 6 { return 74; }
  if num.signum(-3) != -1 { return 75; }
  if num.signum(0) != 0 { return 76; }
  if num.signum(3) != 1 { return 77; }

  // 11: Int128 boundaries.
  if num.i128_shl(1 as Int128, 128) != (0 as Int128) { return 78; }
  if num.i128_shr((0 as Int128) - (1 as Int128), 128) != (0 as Int128) - (1 as Int128) { return 79; }
  var o0 = num.i128_to_i64(0 as Int128);
  if !o0.is_some { return 80; }
  if o0.value != 0 { return 81; }
  var oshift = num.i128_to_i64(num.i128_shl(1 as Int128, 64));
  if oshift.is_some { return 82; }
  if num.i128_to_str(0 as Int128) != "0" { return 83; }
  var rs = num.i128_from_str("");
  if rs.is_ok { return 84; }
  var rsg = num.i128_from_str("+");
  if rsg.is_ok { return 85; }

  // 12: float<->int conversion Option and payload laws.
  if num.int_from_f64_trunc(nan).is_some { return 86; }
  var it = num.int_from_f64_trunc(3.9);
  if !it.is_some { return 87; }
  if it.value != 3 { return 88; }
  if num.u64_from_f64_trunc(-1.0).is_some { return 89; }
  var uz = num.u64_from_f64_trunc(0.0);
  if !uz.is_some { return 90; }
  if (uz.value as Int) != 0 { return 91; }
  if num.i32_from_f64_trunc(2147483648.0).is_some { return 92; }
  if num.i64_from_u64(18446744073709551615 as UInt64).is_some { return 93; }
  var i5 = num.i64_from_u64(5 as UInt64);
  if !i5.is_some { return 94; }
  if i5.value != 5 { return 95; }

  // 13: lerp/remap/inverse range laws.
  if num.f64_inverse_lerp(0.0, 10.0, 20.0) != 1.0 { return 96; }
  if num.f64_inverse_lerp(0.0, 10.0, -5.0) != 0.0 { return 97; }
  if num.f64_inverse_lerp(4.0, 4.0, 9.0) != 0.0 { return 98; }
  if num.f64_remap(5.0, 1.0, 1.0, 7.0, 9.0) != 7.0 { return 99; }
  if num.i64_lerp(0, 10, 5) != 10 { return 100; }
  if num.i64_lerp(0, 10, -5) != 0 { return 101; }

  // 14: fraction arithmetic zero laws and degenerate edges.
  var a = num.fraction_new(1, 2);
  var b = num.fraction_new(1, 3);
  var s = num.fraction_add(&a, &b);
  if s.num != 5 || s.den != 6 { return 102; }
  var d = num.fraction_sub(&a, &b);
  if d.num != 1 || d.den != 6 { return 103; }
  var m = num.fraction_mul(&a, &b);
  if m.num != 1 || m.den != 6 { return 104; }
  var q = num.fraction_div(&a, &b);
  if q.num != 3 || q.den != 2 { return 105; }
  var r = num.fraction_reciprocal(&a);
  if r.num != 2 || r.den != 1 { return 106; }
  var z0 = num.fraction_new(0, 7);
  var rz = num.fraction_reciprocal(&z0);
  if rz.num != 0 || rz.den != 1 { return 107; }
  var p1 = num.fraction_pow_int(a, 0);
  if p1.num != 1 || p1.den != 1 { return 108; }
  var pmin = num.fraction_pow_int(a, -9223372036854775807 - 1);
  if pmin.num != 0 || pmin.den != 1 { return 109; }
  var tof = num.fraction_to_float(num.fraction_new(3, 3));
  if tof != 1.0 { return 110; }
  if num.fraction_to_str(num.fraction_new(-7, 2)) != "-7/2" { return 111; }

  return 0;
}
