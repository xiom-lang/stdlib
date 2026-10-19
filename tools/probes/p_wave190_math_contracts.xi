// p_wave190_math_contracts.xi -- wave 190: math analysis/numerical contracts.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Every call below evaluates the new runtime ensures clauses (a violation
// aborts the probe). Cases:
// 1. special: gamma positivity, incomplete gamma/beta in [0,1], erf in
//    [-1,1], elliptic K/E interval, Bessel J bounds and I sign parity.
// 2. roots: integer floor-root sentinels, cbrt sign law, norm positivity.
// 3. inverse trig: asin/acos/atan/atan2 principal ranges.
// 4. hyperbolic: tanh range and sinh/asinh/atanh sign laws.
// 5. numerical: spline coefficient lengths, univariate optimizer interval,
//    multi-variable optimizer shape.
// 6. differential equations: Euler/RK4/BDF trajectory length n + 1.
// 7. precision: positive digit/width metadata on Int and Float64.
// 8. control theory: Nyquist/Bode lengths, root-locus bound, Kalman shape.
// Returns 0 when every case holds.

module p_wave190_math_contracts

use xiom.math;
use xiom.io;

fn lin(x: Float64) -> Float64 {
  return x;
}

fn rhs(t: Float64, y: Float64) -> Float64 {
  return y;
}

fn flat_cost(v: &Vec[Int]) -> Float64 {
  return 0.0;
}

fn unit_tf(w: Float64) -> Float64 {
  return 1.0 / (1.0 + w * w);
}

fn main() -> Int {
  var pi = 3.141592653589793;
  var half_pi = 1.5707963267948966;

  // 1: special-function domains and ranges.
  if (!(math.special.gamma(5.0) > 0.0)) { return 1; }
  if (!(math.special.gamma(0.5) > 0.0)) { return 2; }
  var ig = math.special.incomplete_gamma(2.0, 1.5);
  if (!(ig >= 0.0) || !(ig <= 1.0)) { return 3; }
  var ib = math.special.incomplete_beta(2.0, 3.0, 0.5);
  if (!(ib >= 0.0) || !(ib <= 1.0)) { return 4; }
  var ef = math.special.erf(1.0);
  if (!(ef >= -1.0) || !(ef <= 1.0)) { return 5; }
  if (!(math.special.elliptic_k(0.5) >= half_pi)) { return 6; }
  var ee = math.special.elliptic_e(0.5);
  if (!(ee >= 1.0) || !(ee <= half_pi)) { return 7; }
  var j0 = math.special.bessel_j0(1.0);
  var j1 = math.special.bessel_j1(1.0);
  if (!(j0 >= -1.0) || !(j0 <= 1.0)) { return 8; }
  if (!(j1 >= -1.0) || !(j1 <= 1.0)) { return 9; }
  if (!(math.special.bessel_i(1, 2.0) >= 0.0)) { return 10; }
  if (!(math.special.bessel_i(1, -2.0) <= 0.0)) { return 11; }
  if (!(math.special.zeta(2.0) >= 1.0)) { return 12; }

  // 2: roots sentinels, sign law, norms.
  if (math.roots.integer_sqrt(-9) != -1) { return 13; }
  if (math.roots.integer_cbrt(-9) != -1) { return 14; }
  if (math.roots.integer_sqrt(17) != 4) { return 15; }
  if (math.roots.integer_cbrt(28) != 3) { return 16; }
  if (!(math.roots.cbrt(-27.0) < 0.0)) { return 17; }
  if (!(math.roots.cbrt_pure(27.0) > 0.0)) { return 18; }
  if (!(math.roots.norm2(3.0, 4.0) >= 0.0)) { return 19; }
  if (!(math.roots.norm3(1.0, 2.0, 2.0) >= 0.0)) { return 20; }

  // 3: inverse-trig principal ranges.
  var asv = math.inverse_trig.asin(0.5);
  var ac = math.inverse_trig.acos(0.5);
  var at = math.inverse_trig.atan(1000.0);
  var a2 = math.inverse_trig.atan2(1.0, -1.0);
  if (!(asv >= -half_pi) || !(asv <= half_pi)) { return 21; }
  if (!(ac >= 0.0) || !(ac <= pi)) { return 22; }
  if (!(at >= -half_pi) || !(at <= half_pi)) { return 23; }
  if (!(a2 >= -pi) || !(a2 <= pi)) { return 24; }
  if (!(math.inverse_trig.asin_pure(-0.5) >= -half_pi)) { return 25; }
  if (!(math.inverse_trig.acos_pure(0.25) <= pi)) { return 26; }
  if (!(math.inverse_trig.atan2_degrees(1.0, 1.0) <= 180.0)) { return 27; }

  // 4: hyperbolic range and sign laws.
  var th = math.hyperbolic.tanh(3.0);
  if (!(th >= -1.0) || !(th <= 1.0)) { return 28; }
  if (!(math.hyperbolic.sinh(2.0) > 0.0)) { return 29; }
  if (!(math.hyperbolic.sinh(-2.0) < 0.0)) { return 30; }
  if (!(math.hyperbolic.asinh(-2.0) < 0.0)) { return 31; }
  if (!(math.hyperbolic.atanh(0.5) > 0.0)) { return 32; }
  if (!(math.hyperbolic.tanh_pure(-30.0) >= -1.0)) { return 33; }

  // 5: spline shapes and optimizer invariants.
  var xs = Vec[Float64].new();
  xs.push(0.0);
  xs.push(1.0);
  xs.push(2.0);
  var ys = Vec[Float64].new();
  ys.push(0.0);
  ys.push(2.0);
  ys.push(4.0);
  if (math.numerical.spline_linear(&xs, &ys).len() != 4) { return 34; }
  if (math.numerical.spline_cubic(&xs, &ys).len() != 8) { return 35; }
  if (math.numerical.spline_b_spline(&xs, &ys, 1).len() != 3) { return 36; }
  var wts = Vec[Float64].new();
  wts.push(1.0);
  wts.push(1.0);
  wts.push(1.0);
  if (math.numerical.spline_nurbs(&xs, &ys, &wts, 3).len() != 3) { return 37; }
  var gx = math.numerical.optimize_golden(lin, -4.0, 3.0, 1e-9);
  if (!(gx >= -4.0) || !(gx <= 3.0)) { return 38; }
  var tx = math.numerical.optimize_ternary(lin, -4.0, 3.0, 1e-9);
  if (!(tx >= -4.0) || !(tx <= 3.0)) { return 39; }
  var x0 = Vec[Float64].new();
  x0.push(1.0);
  x0.push(2.0);
  var opt = math.numerical.optimize_lbfgs(lin_scalar, lin_grad, &x0, 4, 1e-9);
  if (opt.len() != 2) { return 40; }

  // 6: ODE trajectory lengths.
  var eul = math.differential_equations.solve_ode_euler(rhs, 1.0, 0.0, 1.0, 4);
  if (eul.len() != 5) { return 41; }
  var rk4 = math.differential_equations.solve_ode_rk4(rhs, 1.0, 0.0, 1.0, 4);
  if (rk4.len() != 5) { return 42; }
  var bdf = math.differential_equations.solve_ode_bdf(rhs, 1.0, 0.0, 1.0, 4);
  if (bdf.len() != 5) { return 43; }

  // 7: precision metadata.
  if (math.precision.digits[Int]() <= 0) { return 44; }
  if (math.precision.bit_width[Float64]() <= 0) { return 45; }
  if (math.precision.byte_width[Int]() <= 0) { return 46; }
  if (math.precision.exponent_bias[Float64]() < 0) { return 47; }
  if (math.precision.min_exponent[Float64]() > 0) { return 48; }

  // 8: control-theory shapes.
  var freqs = Vec[Float64].new();
  freqs.push(0.1);
  freqs.push(1.0);
  freqs.push(10.0);
  if (math.control_theory.nyquist_plot(unit_tf, &freqs).len() != 3) { return 49; }
  if (math.control_theory.bode_plot(unit_tf, &freqs).len() != 3) { return 50; }
  var num = Vec[Float64].new();
  num.push(1.0);
  var den = Vec[Float64].new();
  den.push(1.0);
  den.push(1.0);
  var gains = Vec[Float64].new();
  gains.push(0.5);
  gains.push(2.0);
  if (math.control_theory.root_locus(&num, &den, &gains).len() > 4) { return 51; }
  var xh = Vec[Float64].new();
  xh.push(1.0);
  xh.push(2.0);
  var mat = Vec[Vec[Float64]].new();
  var mrow1 = Vec[Float64].new();
  mrow1.push(1.0);
  mrow1.push(0.0);
  var mrow2 = Vec[Float64].new();
  mrow2.push(0.0);
  mrow2.push(1.0);
  mat.push(mrow1);
  mat.push(mrow2);
  if (math.control_theory.kalman_filter(&mat, &mat, &mat, &xh, &xh).len() != 2) { return 52; }

  // 9: simulated-annealing / ant-colony shape invariants.
  var sa = math.optimization.simulated_annealing(lin_scalar, &x0, 1.0, cooling);
  if (sa.len() != 2) { return 53; }
  var ac = math.optimization.ant_colony(flat_cost, 4, 2);
  if (ac.len() != 4) { return 54; }

  io.println("p_wave190_math_contracts: OK");
  return 0;
}

fn lin_scalar(x: &Vec[Float64]) -> Float64 {
  return x[0] + x[1];
}

fn lin_grad(x: &Vec[Float64]) -> Vec[Float64] {
  var g = Vec[Float64].new();
  g.push(1.0);
  g.push(1.0);
  return g;
}

fn cooling(t: Float64, i: Float64) -> Float64 {
  return t * 0.5;
}

