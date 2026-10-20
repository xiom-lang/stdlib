// p_wave200_math.xi -- wave 200: math real-path contract invariants.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below re-evaluates a wave-200 requires/ensures at runtime, so a
// violated clause aborts the probe. Cases:
// 1. special: the invalid-domain sentinels (NaN for out-of-domain arguments,
//    +inf at the digamma pole) and finite values on the accepted domains.
// 2. numerical: the no-bracket NaN sentinels of falsi/brent/solver_single and
//    the interpolation shape sentinels.
// 3. approximation: interpolation/extrapolation shape sentinels.
// 4. topology: the documented empty-family vacuous results and the empty-tau
//    open_set/neighborhood false results.
// 5. tower: the twice/negate/of_int delegate postconditions.
// Returns 0 when every case holds.

module p_wave200_math

use xiom.math;

fn pos(x: Float64) -> Float64 {
  return x * x + 1.0;
}

fn ident(x: Int) -> Int {
  return x;
}

fn zero_d(x: Int, y: Int) -> Float64 {
  return 0.0;
}

fn main() -> Int {
  var nan = 0.0 / 0.0;

  // 1: special domain sentinels.
  if math.special.bessel_y0(-1.0) == math.special.bessel_y0(-1.0) { return 1; }
  if math.special.bessel_y1(0.0) == math.special.bessel_y1(0.0) { return 2; }
  if math.special.bessel_y(2, -1.0) == math.special.bessel_y(2, -1.0) { return 3; }
  if math.special.bessel_yn(-1, 2.0) == math.special.bessel_yn(-1, 2.0) { return 4; }
  if math.special.digamma(0.0) != 1.0 / 0.0 { return 5; }
  if math.special.legendre_q(0, 2.0) == math.special.legendre_q(0, 2.0) { return 6; }
  if math.special.hermite_h(-1, 0.5) == math.special.hermite_h(-1, 0.5) { return 7; }
  if math.special.laguerre_l(-1, 0.0, 0.5) == math.special.laguerre_l(-1, 0.0, 0.5) { return 8; }
  if math.special.jacobi_p(1, -2.0, 0.0, 0.5) == math.special.jacobi_p(1, -2.0, 0.0, 0.5) { return 9; }
  if math.special.gegenbauer_c(-1, 0.0, 0.5) == math.special.gegenbauer_c(-1, 0.0, 0.5) { return 10; }
  if math.special.spherical_harmonic(1, 2, 1.0, 0.0) == math.special.spherical_harmonic(1, 2, 1.0, 0.0) { return 11; }
  if math.special.airy_bi(nan) == math.special.airy_bi(nan) { return 12; }
  if math.special.airy_bip(nan) == math.special.airy_bip(nan) { return 13; }
  if math.special.elliptic_pi(0.0, 2.0) == math.special.elliptic_pi(0.0, 2.0) { return 14; }
  if math.special.theta_2(0.0, 0.0) == math.special.theta_2(0.0, 0.0) { return 15; }
  if math.special.theta_4(0.0, 1.0) == math.special.theta_4(0.0, 1.0) { return 16; }
  if math.special.exponential_integral(nan) == math.special.exponential_integral(nan) { return 17; }
  if math.special.cos_integral(-1.0) == math.special.cos_integral(-1.0) { return 18; }
  if math.special.hypergeometric_2f1(1.0, 1.0, 0.0, 0.5) == math.special.hypergeometric_2f1(1.0, 1.0, 0.0, 0.5) { return 19; }

  // Accepted domains (the clauses must stay satisfied and finite).
  if math.special.bessel_y0(1.0) != math.special.bessel_y0(1.0) { return 20; }
  if math.special.digamma(2.5) != math.special.digamma(2.5) { return 21; }
  if math.special.spherical_harmonic(1, 0, 0.5, 0.5) != math.special.spherical_harmonic(1, 0, 0.5, 0.5) { return 22; }
  if math.special.theta_2(0.1, 0.5) != math.special.theta_2(0.1, 0.5) { return 23; }
  if math.special.elliptic_pi(0.2, 0.5) != math.special.elliptic_pi(0.2, 0.5) { return 24; }

  // 2: numerical no-bracket + shape sentinels.
  if math.numerical.falsi(pos, -1.0, 1.0, 1.0e-9) == math.numerical.falsi(pos, -1.0, 1.0, 1.0e-9) { return 25; }
  if math.numerical.brent(pos, -1.0, 1.0, 1.0e-9) == math.numerical.brent(pos, -1.0, 1.0, 1.0e-9) { return 26; }
  if math.numerical.solver_single(pos, -1.0, 1.0, 1.0e-9) == math.numerical.solver_single(pos, -1.0, 1.0, 1.0e-9) { return 27; }
  var empty_f = Vec[Float64].new();
  var one_f = Vec[Float64].new();
  one_f.push(1.0);
  var two_f = Vec[Float64].new();
  two_f.push(1.0);
  two_f.push(2.0);
  if math.numerical.interp_linear(empty_f, empty_f, 0.0) == math.numerical.interp_linear(empty_f, empty_f, 0.0) { return 28; }
  if math.numerical.interp_polynomial(one_f, two_f, 0.0) == math.numerical.interp_polynomial(one_f, two_f, 0.0) { return 29; }
  if math.numerical.interp_spline(one_f, one_f, 0.0) == math.numerical.interp_spline(one_f, one_f, 0.0) { return 30; }
  if math.numerical.interp_cubic(one_f, two_f, 0.0) == math.numerical.interp_cubic(one_f, two_f, 0.0) { return 31; }
  if math.numerical.interp_hermite(one_f, one_f, two_f, 0.0) == math.numerical.interp_hermite(one_f, one_f, two_f, 0.0) { return 32; }
  var xs = Vec[Float64].new();
  xs.push(0.0);
  xs.push(1.0);
  var ys = Vec[Float64].new();
  ys.push(0.0);
  ys.push(1.0);
  if math.numerical.interp_linear(xs, ys, 0.5) != 0.5 { return 33; }

  // 3: approximation shape sentinels.
  if math.approximation.interpolation(one_f, two_f, 0.0) == math.approximation.interpolation(one_f, two_f, 0.0) { return 34; }
  if math.approximation.extrapolation(empty_f, empty_f, 0.0) == math.approximation.extrapolation(empty_f, empty_f, 0.0) { return 35; }
  if math.approximation.interpolation(xs, ys, 0.5) != 0.5 { return 36; }

  // 4: topology empty-family results.
  var empty_tau = Vec[Vec[Int]].new();
  var empty_set = Vec[Int].new();
  var one_set = Vec[Int].new();
  one_set.push(1);
  if math.topology.open_set(empty_tau, one_set) != false { return 37; }
  if math.topology.compactness(empty_tau, empty_set) != true { return 38; }
  if math.topology.connectedness(empty_tau, empty_set) != true { return 39; }
  if math.topology.continuity(ident, empty_tau, empty_tau) != true { return 40; }
  if math.topology.homeomorphism(ident, ident, empty_tau, empty_tau) != true { return 41; }
  if math.topology.metric_space(zero_d, empty_set) != true { return 42; }
  if math.topology.limit_point(empty_tau, one_set, 1) != true { return 43; }
  if math.topology.neighborhood(empty_tau, 1, one_set) != false { return 44; }

  // 5: tower delegate postconditions.
  if math.tower.twice[Int](21) != 42 { return 45; }
  if math.tower.negate[Int](5) != -5 { return 46; }
  if math.tower.twice[Float64](1.5) != 3.0 { return 47; }
  if math.tower.negate[Float64](2.5) != -2.5 { return 48; }
  if math.tower.of_int[Int](7) != 7 { return 49; }
  if math.tower.of_int[Float64](3) != 3.0 { return 50; }
  if math.tower.twice[Float64](nan) == math.tower.twice[Float64](nan) { return 51; }
  if math.tower.negate[Float64](nan) == math.tower.negate[Float64](nan) { return 52; }

  return 0;
}
