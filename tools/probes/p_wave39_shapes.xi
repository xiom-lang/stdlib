// p_wave39_shapes.xi -- wave 39 verification: algebra + transcendental clauses
// and the signed-zero fix for the angular conversion clauses.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call evaluates the new/fixed runtime ensures clauses. Cases:
// 1. algebra identities (gcd/lcm/egcd, Legendre/Jacobi values and ranges,
//    binomial/factorial/primorial/nth_prime, integer_sqrt,
//    next_power_of_two, is_power_of_two, is_perfect_square).
// 2. transcendental identities and domain NaN (sqrt/cbrt/exp/exp2/expm1/
//    ln/log2/log10/log1p, erf/erfc ranges and values; the erfc-based
//    approximation is good to ~1.2e-7, so its cases use looser tolerances).
// 3. signed-zero regression for the ten angular conversions and the
//    rounding family (-0.0 must satisfy the new >= / <= clause branches).
// Returns 0 when every case holds.

module p_wave39_shapes

use xiom.math;

fn near(a: Float64, b: Float64, tol: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < tol;
}

fn is_nan(x: Float64) -> Bool {
  return x != x;
}

fn main() -> Int {
  var inf = 1.0 / 0.0;
  var nan = 0.0 / 0.0;

  // 1: algebra.
  if math.algebra.gcd(12, 18) != 6 { return 1; }
  if math.algebra.gcd(0, 0) != 0 { return 2; }
  if math.algebra.lcm(4, 6) != 12 { return 3; }
  var e = math.algebra.egcd(12, 18);
  if e.0 != 6 { return 4; }
  if 12 * e.1 + 18 * e.2 != 6 { return 5; }
  if math.algebra.legendre_symbol(2, 7) != 1 { return 6; }
  if math.algebra.legendre_symbol(3, 7) != -1 { return 7; }
  if math.algebra.legendre_symbol(14, 7) != 0 { return 8; }
  if math.algebra.jacobi_symbol(2, 7) != 1 { return 9; }
  if math.algebra.jacobi_symbol(1, 8) != 0 { return 10; }
  if math.algebra.binomial(5, 2) != 10 { return 11; }
  if math.algebra.binomial(3, 5) != 0 { return 12; }
  if math.algebra.factorial(5) != 120 { return 13; }
  if math.algebra.factorial(30) != 0 { return 14; }
  if math.algebra.primorial(5) != 2310 { return 15; }
  if math.algebra.nth_prime(5) != 11 { return 16; }
  if math.algebra.integer_sqrt(144) != 12 { return 17; }
  if math.algebra.integer_sqrt(-1) != -1 { return 18; }
  if math.algebra.next_power_of_two(5) != 8 { return 19; }
  if math.algebra.next_power_of_two(0) != 1 { return 20; }
  if math.algebra.is_power_of_two(16) == false { return 21; }
  if math.algebra.is_power_of_two(0) { return 22; }
  if math.algebra.is_perfect_square(49) == false { return 23; }
  if math.algebra.is_perfect_square(2) { return 24; }

  // 2: transcendental.
  if !near(math.transcendental.sqrt(9.0), 3.0, 1e-9) { return 25; }
  if !is_nan(math.transcendental.sqrt(-1.0)) { return 26; }
  if !near(math.transcendental.cbrt(-8.0), -2.0, 1e-9) { return 27; }
  if !near(math.transcendental.exp(0.0), 1.0, 1e-9) { return 28; }
  if !near(math.transcendental.exp2(10.0), 1024.0, 1e-9) { return 29; }
  if !near(math.transcendental.expm1(0.0), 0.0, 1e-9) { return 30; }
  if !near(math.transcendental.ln(1.0), 0.0, 1e-9) { return 31; }
  if !is_nan(math.transcendental.ln(0.0)) { return 32; }
  if !near(math.transcendental.log2(8.0), 3.0, 1e-9) { return 33; }
  if !near(math.transcendental.log10(1000.0), 3.0, 1e-9) { return 34; }
  if !near(math.transcendental.log1p(0.0), 0.0, 1e-9) { return 35; }
  if math.transcendental.log1p(-1.0) != -inf { return 36; }
  if !near(math.transcendental.erf(0.0), 0.0, 1e-6) { return 37; }
  if !near(math.transcendental.erf(1.0), 0.8427007, 1e-5) { return 38; }
  if !near(math.transcendental.erfc(0.0), 1.0, 1e-6) { return 39; }
  var e3 = math.transcendental.erfc(3.0);
  if e3 <= 0.0 || e3 >= 0.0001 { return 40; }

  // 3: signed zero (angular clause fix) and rounding signed zero.
  if 1.0 / math.angular.to_radians(-0.0) != -inf { return 41; }
  if 1.0 / math.angular.to_radians(0.0) != inf { return 42; }
  if 1.0 / math.angular.to_degrees(-0.0) != -inf { return 43; }
  if 1.0 / math.angular.to_gradians(-0.0) != -inf { return 44; }
  if 1.0 / math.angular.from_gradians(-0.0) != -inf { return 45; }
  if 1.0 / math.angular.to_mils(-0.0) != -inf { return 46; }
  if 1.0 / math.angular.from_mils(-0.0) != -inf { return 47; }
  if 1.0 / math.angular.to_arcmin(-0.0) != -inf { return 48; }
  if 1.0 / math.angular.from_arcmin(-0.0) != -inf { return 49; }
  if 1.0 / math.angular.to_arcsec(-0.0) != -inf { return 50; }
  if 1.0 / math.angular.from_arcsec(-0.0) != -inf { return 51; }
  if 1.0 / math.rounding.floor(-0.0) != -inf { return 52; }
  if 1.0 / math.rounding.trunc(-0.0) != -inf { return 53; }
  if 1.0 / math.rounding.fract(-0.0) != inf { return 54; }

  // NOTE: sqrt(NaN) is not probed: math.roots.sqrt passes NaN to math.sqrt,
  // whose runtime requires x >= 0.0 aborts instead of returning NaN (open
  // stdlib finding, recorded in the session doc; not a clause violation
  // because the call never returns).

  return 0;
}
