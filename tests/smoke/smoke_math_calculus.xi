// Smoke: xiom.math.calculus + xiom.math.differential.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success.
//
// NOTE: the checks use INTERVAL COMPARISONS instead of difference-based
// tolerance, because arithmetic on a value returned by a catalog-module
// function traps with 0xC000001D (BUG 20 AVX-512 codegen on Zen 2), while
// relational comparisons are safe. Scalar differences, quadrature
// delegation, and the vector-calculus functions implemented 2026-09-24 are
// exercised below; the limit functions remain documented stubs.
use xiom.math;
use xiom.io;

fn sq(x: Float64) -> Float64 {
  return x * x;
}

fn sphere2(x: &Vec[Float64]) -> Float64 {
  return x[0] * x[0] + x[1] * x[1];
}

fn cub(x: Float64) -> Float64 {
  return x * x * x;
}

fn fourth(x: Float64) -> Float64 {
  return x * x * x * x;
}

// lo <= x <= hi (comparisons only - safe on catalog-returned floats).
fn in_range(x: Float64, lo: Float64, hi: Float64) -> Bool {
  if x < lo { return false; }
  if x > hi { return false; }
  return true;
}

fn main() -> Int {
  // calculus scalar derivatives
  var d1 = math.calculus.derivative(sq, 3.0, 1e-5);
  if !in_range(d1, 5.999, 6.001) { io.println("derivative"); return 1; }
  var d2 = math.calculus.derivative_2nd(cub, 2.0, 1e-4);
  if !in_range(d2, 11.999, 12.001) { io.println("derivative-2nd"); return 2; }
  var d3 = math.calculus.derivative_3rd(fourth, 1.0, 1e-3);
  if !in_range(d3, 23.999, 24.001) { io.println("derivative-3rd"); return 3; }

  // calculus integration (delegations)
  var it = math.calculus.integrate(sq, 0.0, 1.0);
  if !in_range(it, 0.3333, 0.3334) { io.println("integrate"); return 4; }
  var itt = math.calculus.integrate_trapezoid(sq, 0.0, 1.0, 100);
  if !in_range(itt, 0.3333, 0.3334) { io.println("integrate-trap"); return 5; }
  var its = math.calculus.integrate_simpson(fourth, 0.0, 1.0, 8);
  if !in_range(its, 0.1999, 0.2001) { io.println("integrate-simp"); return 6; }

  // differential module derivatives
  var dd1 = math.differential.derivative(sq, 3.0, 1e-5);
  if !in_range(dd1, 5.999, 6.001) { io.println("derivative-diff"); return 7; }
  var dd2 = math.differential.derivative2(cub, 2.0, 1e-4);
  if !in_range(dd2, 11.999, 12.001) { io.println("derivative2"); return 8; }
  var dd3 = math.differential.derivative3(fourth, 1.0, 1e-3);
  if !in_range(dd3, 23.999, 24.001) { io.println("derivative3"); return 9; }
  var fd = math.differential.finite_difference(sq, 3.0, 1e-5);
  if !in_range(fd, 5.999, 6.001) { io.println("finite-difference"); return 10; }

  // Gauss-Legendre delegation (unblocked 2026-09-24; cross-module deleg works)
  var ig = math.calculus.integrate_gauss(sq, 0.0, 1.0, 4);
  if !in_range(ig, 0.3333, 0.3334) { io.println("integrate-gauss"); return 11; }

  // vector calculus (implemented 2026-09-24 with push-only perturbations)
  var gx: Vec[Float64] = Vec[Float64].new();
  gx.push(1.0); gx.push(2.0);
  var gv = math.differential.gradient(sphere2, &gx);
  if gv.len() != 2 { io.println("gradient-len"); return 12; }
  if !in_range(gv[0], 1.999, 2.001) { io.println("gradient-0"); return 12; }
  if !in_range(gv[1], 3.999, 4.001) { io.println("gradient-1"); return 12; }
  var pd = math.differential.partial_derivative(sphere2, &gx, 1, 1e-5);
  if !in_range(pd, 3.999, 4.001) { io.println("partial"); return 12; }
  if math.differential.partial_derivative(sphere2, &gx, 9, 1e-5) != 0.0 { io.println("partial-oob"); return 12; }
  var rr = math.differential.richardson(sq, 3.0, 1e-3, 1e-6);
  if !in_range(rr, 5.999, 6.001) { io.println("richardson"); return 12; }
  if math.differential.richardson(sq, 3.0, 1e-3, 0.0) != 0.0 { io.println("richardson-tol"); return 12; }

  io.println("smoke_math_calculus: OK");
  return 0;
}
