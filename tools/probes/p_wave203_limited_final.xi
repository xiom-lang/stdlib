// p_wave203_limited_final.xi -- wave 203: final contract-limited clause pass.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-203 requires/ensures at runtime, so a
// violated clause aborts the probe. This wave adds only real-path laws; the
// stubs (compiler-limited matrix/AVX-512 paths, os documented Err stubs,
// opaque iterator closures) stay clause-free and are listed in the report.
// Cases:
// 1. math.algebra: egcd gcd bound, mod_inverse payload range/inverse law,
//    crt shape guard.
// 2. math.arithmetic: mod_inverse m=0/m=1/range laws, div_ceil/div_floor/
//    div_trunc boundary laws.
// 3. number systems: empty-string Err, radix values, roman payload laws.
// 4. number theory: next_prime/pollard_rho/p_1_factor/euler_phi/mobius/
//    jordan_totient/carmichael/prime_pi/radical boundary laws.
// 5. queueing: NaN/zero/inf domain sentinels and non-negative waiting time.
// 6. integral/transcendental: zero-width integral, power/root/gamma/lambert
//    sentinels and special values.
// 7. trig/math/angular/primitives: zero-input identities and round bounds.
// 8. iter: TakeIter/SkipIter counter state laws and EnumerateIter.map index
//    preservation (the only remaining defensible iterator laws).
// Returns 0 when every case holds.

module p_wave203_limited_final

use xiom.iter;
use xiom.math;

fn add(a: Int, b: Int) -> Int {
  return a + b;
}

fn dbl(x: Int) -> Int {
  return x * 2;
}

fn is_even(x: &Int) -> Bool {
  return *x % 2 == 0;
}

fn is_pos(x: &Int) -> Bool {
  return *x > 0;
}

fn idx_plus(p: (Int, Int)) -> Int {
  return p.0 + p.1;
}

fn one(_x: Float64) -> Float64 {
  return 1.0;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;

  // 1: algebra real-path laws.
  let eg = math.algebra.egcd(240, 46);
  if eg.0 != 2 { return 1; }
  match math.algebra.mod_inverse(3, 7) {
    Some(v) => { if v != 5 { return 2; } },
    None => { return 3; },
  };
  match math.algebra.mod_inverse(9, 1) {
    Some(v) => { if v != 0 { return 4; } },
    None => { return 5; },
  };
  if math.algebra.mod_inverse(3, 0).is_some { return 6; }
  match math.algebra.crt(&Vec[Int].new(), &Vec[Int].new()) {
    Some(_) => { return 7; },
    None => {},
  };

  // 2: arithmetic boundary laws.
  match math.arithmetic.mod_inverse(3, 7) {
    Some(v) => { if v != 5 { return 8; } },
    None => { return 9; },
  };
  match math.arithmetic.mod_inverse(42, 1) {
    Some(v) => { if v != 0 { return 10; } },
    None => { return 11; },
  };
  if math.arithmetic.mod_inverse(3, 0).is_some { return 12; }
  if math.arithmetic.div_ceil(7, 2) != 4 { return 13; }
  if math.arithmetic.div_ceil(-7, 2) != -3 { return 14; }
  if math.arithmetic.div_ceil(7, 0) != 0 { return 15; }
  if math.arithmetic.div_floor(7, 2) != 3 { return 16; }
  if math.arithmetic.div_floor(-7, 2) != -4 { return 17; }
  if math.arithmetic.div_floor(7, 0) != 0 { return 18; }
  if math.arithmetic.div_trunc(7, 2) != 3 { return 19; }
  if math.arithmetic.div_trunc(-7, 2) != -3 { return 20; }
  if math.arithmetic.div_trunc(7, 1) != 7 { return 21; }

  // 3: number systems.
  if !math.number_systems.binary_to_int("").is_err { return 22; }
  if math.number_systems.binary_to_int("1010").value != 10 { return 23; }
  if !math.number_systems.octal_to_int("").is_err { return 24; }
  if math.number_systems.octal_to_int("17").value != 15 { return 25; }
  if !math.number_systems.hex_to_int("").is_err { return 26; }
  if math.number_systems.hex_to_int("ff").value != 255 { return 27; }
  if !math.number_systems.roman_to_int("").is_err { return 28; }
  if math.number_systems.roman_to_int("XIV").value != 14 { return 29; }
  if math.number_systems.roman_to_int("ZZ").is_ok { return 30; }
  if math.number_systems.roman_to_int("ZZ").error.len() == 0 { return 31; }

  // 4: number theory.
  if math.number_theory.next_prime(1) != 2 { return 32; }
  if math.number_theory.next_prime(17) != 19 { return 33; }
  let huge = 9223372036854775807;
  if math.number_theory.next_prime(huge - 1) != 0 { return 34; }
  if math.number_theory.pollard_rho(1) != 1 { return 35; }
  if math.number_theory.pollard_rho(97) != 97 { return 36; }
  let pr = math.number_theory.pollard_rho(91);
  if pr != 7 && pr != 13 { return 37; }
  if math.number_theory.p_1_factor(1) != 1 { return 38; }
  if math.number_theory.p_1_factor(97) != 97 { return 39; }
  let pf = math.number_theory.p_1_factor(91);
  if pf != 7 && pf != 13 { return 40; }
  if math.number_theory.euler_phi(0) != 0 { return 41; }
  if math.number_theory.euler_phi(10) != 4 { return 42; }
  if math.number_theory.mobius(0) != 0 { return 43; }
  if math.number_theory.mobius(30) != -1 { return 44; }
  if math.number_theory.jordan_totient(0, 2) != 0 { return 45; }
  if math.number_theory.jordan_totient(1, 0) != 1 { return 46; }
  if math.number_theory.jordan_totient(10, 2) != 72 { return 47; }
  if math.number_theory.carmichael(0) != 0 { return 48; }
  if math.number_theory.carmichael(1) != 1 { return 49; }
  if math.number_theory.carmichael(15) != 4 { return 50; }
  if math.number_theory.prime_pi(1) != 0 { return 51; }
  if math.number_theory.prime_pi(10) != 4 { return 52; }
  if math.number_theory.radical(-12) != -12 { return 53; }
  if math.number_theory.radical(12) != 6 { return 54; }

  // 5: queueing sentinels.
  let h0 = math.queueing.heavy_traffic(0.0, 1.0, 1);
  if h0 == h0 { return 55; }
  let h1 = math.queueing.heavy_traffic(1.0, 2.0, 2);
  if h1 < 0.0 { return 56; }
  let h2 = math.queueing.heavy_traffic(3.0, 1.0, 2);
  if h2 != 1.0 / 0.0 { return 57; }
  let d0 = math.queueing.diffusion_approx(1.0, 2.0, 5.0);
  if d0 != 0.0 { return 58; }
  let d1 = math.queueing.diffusion_approx(1.0, 2.0, -1.0);
  if d1 == d1 { return 59; }

  // 6: integral and transcendental.
  if math.integral.integrate_gauss_legendre(one, 2.0, 2.0, 4) != 0.0 { return 60; }
  if math.transcendental.pow(2.0, 3.0) != 8.0 { return 61; }
  if math.transcendental.pow_int(2.0, 0) != 1.0 { return 62; }
  if math.transcendental.root(9.0, 2) != 3.0 { return 63; }
  if math.transcendental.gamma(1.0) != 1.0 { return 64; }
  if math.transcendental.gamma(2.0) != 1.0 { return 65; }
  if math.transcendental.gamma(0.5) <= 1.0 { return 66; }
  if math.transcendental.lgamma(1.0).1 != 1 { return 67; }
  if math.transcendental.lgamma(2.0).1 != 1 { return 68; }
  if math.transcendental.lambert_w(0.0) != 0.0 { return 69; }
  let lw = math.transcendental.lambert_w(-1.0);
  if lw == lw { return 70; }

  // 7: trig/math/angular/primitives.
  if math.trig.tan(0.0) != 0.0 { return 71; }
  if math.trig.sinh(0.0) != 0.0 { return 72; }
  if math.trig.atanh(0.0) != 0.0 { return 73; }
  if math.trig.degrees(0.0) != 0.0 { return 74; }
  if math.trig.radians(0.0) != 0.0 { return 75; }
  if math.trig.tan_deg(0.0) != 0.0 { return 76; }
  if math.round(0.4) != 0 { return 77; }
  if math.round(-0.4) != 0 { return 78; }
  if math.round(0.5) != 1 { return 79; }
  if math.round(-0.5) != -1 { return 80; }
  if math.round(2.5) != 3 { return 81; }
  if math.round(-2.5) != -3 { return 82; }
  if math.angular.angle_lerp(1.0, 2.0, 0.0) != 1.0 { return 83; }
  if math.primitives.lerp(1.0, 2.0, 0.0) != 1.0 { return 84; }

  // 8: iter counter state laws (the clauses check the receivers).
  var tc = iter.range(1, 6).take(3).collect();
  if tc.len() != 3 { return 85; }
  if iter.range(1, 6).take(3).fold(0, add) != 6 { return 86; }
  if iter.range(1, 6).take(3).count() != 3 { return 87; }
  if iter.range(1, 6).take(3).sum() != 6 { return 88; }
  if iter.range(1, 6).take(3).product() != 6 { return 89; }
  match iter.range(1, 6).take(3).max() {
    Some(v) => { if v != 3 { return 90; } },
    None => { return 91; },
  };
  match iter.range(1, 6).take(3).min() {
    Some(v) => { if v != 1 { return 92; } },
    None => { return 93; },
  };
  match iter.range(1, 6).take(3).find(is_even) {
    Some(v) => { if v != 2 { return 94; } },
    None => { return 95; },
  };
  if !iter.range(1, 6).take(3).all(is_pos) { return 96; }
  if !iter.range(1, 6).take(3).any(is_even) { return 97; }
  match iter.range(1, 6).take(3).nth(1) {
    Some(v) => { if v != 2 { return 98; } },
    None => { return 99; },
  };
  match iter.range(1, 6).take(3).last() {
    Some(v) => { if v != 3 { return 100; } },
    None => { return 101; },
  };
  var tm = iter.range(1, 6).take(3).map(dbl).collect();
  if tm.len() != 3 { return 102; }
  var tf = iter.range(1, 6).take(3).filter(is_even).collect();
  if tf.len() != 1 { return 103; }

  var sc = iter.range(1, 6).skip(2).collect();
  if sc.len() != 3 { return 104; }
  if iter.range(1, 6).skip(2).fold(0, add) != 12 { return 105; }
  if iter.range(1, 6).skip(2).count() != 3 { return 106; }
  if iter.range(1, 6).skip(2).sum() != 12 { return 107; }
  if iter.range(1, 6).skip(2).product() != 60 { return 108; }
  match iter.range(1, 6).skip(2).max() {
    Some(v) => { if v != 5 { return 109; } },
    None => { return 110; },
  };
  match iter.range(1, 6).skip(2).min() {
    Some(v) => { if v != 3 { return 111; } },
    None => { return 112; },
  };
  match iter.range(1, 6).skip(2).find(is_even) {
    Some(v) => { if v != 4 { return 113; } },
    None => { return 114; },
  };
  if !iter.range(1, 6).skip(2).all(is_pos) { return 115; }
  if !iter.range(1, 6).skip(2).any(is_even) { return 116; }
  match iter.range(1, 6).skip(2).nth(1) {
    Some(v) => { if v != 4 { return 117; } },
    None => { return 118; },
  };
  match iter.range(1, 6).skip(2).last() {
    Some(v) => { if v != 5 { return 119; } },
    None => { return 120; },
  };
  var sm = iter.range(1, 6).skip(2).map(dbl).collect();
  if sm.len() != 3 { return 121; }
  var sf = iter.range(1, 6).skip(2).filter(is_even).collect();
  if sf.len() != 1 { return 122; }

  // EnumerateIter.map is exercised for the index-preservation clause only;
  // the tuple payload path itself is compiler-limited (tuple fn ABI), so the
  // probe checks the produced count, not the tuple values.
  var em = iter.range(10, 13).enumerate().map(idx_plus).collect();
  if em.len() != 3 { return 123; }

  // Silence unused-variable diagnostics for the sentinels.
  let _ = nan;
  return 0;
}

