// p_wave183_regress_shapes.xi -- wave-183 regression contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-183 xiom.stats.regress degenerate-input contracts:
// zeroed slope/intercept/R2 rows, NaN correlation on short/mismatched
// inputs, polynomial output shape by degree, NaN exponential fit, and
// residual shape.
// Expected: rc 0.

module p_wave183_regress_shapes

use xiom.stats.regress;
use xiom.math;
use xiom.io;

fn main() -> Int {
  var empty: Vec[Float64] = Vec[Float64].new();
  var one: Vec[Float64] = Vec[Float64].new();
  one.push(1.0);
  var two: Vec[Float64] = Vec[Float64].new();
  two.push(1.0); two.push(2.0);
  var three: Vec[Float64] = Vec[Float64].new();
  three.push(1.0); three.push(2.0); three.push(3.0);

  if regress.slope(&empty, &empty) != 0.0 { return 1; }
  if regress.slope(&one, &one) != 0.0 { return 2; }
  if regress.intercept(&empty, &empty) != 0.0 { return 3; }
  if regress.intercept(&one, &two) != 0.0 { return 4; }
  if regress.r_squared(&one, &one) != 0.0 { return 5; }
  var lr0 = regress.linear_regression(&empty, &empty);
  if lr0.slope != 0.0 || lr0.intercept != 0.0 || lr0.r2 != 0.0 { return 6; }
  var lr1 = regress.linear_regression(&one, &one);
  if lr1.slope != 0.0 || lr1.r2 != 0.0 { return 7; }
  if !math.is_nan(regress.pearson_correlation(&one, &one)) { return 8; }
  if !math.is_nan(regress.pearson_correlation(&one, &two)) { return 9; }
  if !math.is_nan(regress.spearman_correlation(&one, &one)) { return 10; }
  if !math.is_nan(regress.spearman_correlation(&one, &two)) { return 11; }
  if regress.polynomial_regression(&two, &two, 0).len() != 0 { return 12; }
  if regress.polynomial_regression(&two, &two, 3).len() != 0 { return 13; }
  if regress.polynomial_regression(&two, &two, 1).len() != 2 { return 14; }
  var p2 = regress.polynomial_regression(&three, &three, 2).len();
  if p2 != 0 && p2 != 3 { return 15; }
  var ef = regress.exponential_fit(&empty, &empty);
  if !math.is_nan(ef.0) || !math.is_nan(ef.1) { return 16; }
  if regress.residuals(&one, &two, 0.0, 0.0).len() != 0 { return 17; }
  if regress.residuals(&two, &two, 0.0, 0.0).len() != 2 { return 18; }

  io.println("p_wave183_regress_shapes: OK");
  return 0;
}
