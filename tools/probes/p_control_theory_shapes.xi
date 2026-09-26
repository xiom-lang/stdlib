// p_control_theory_shapes.xi -- verification for the control_theory state-space
// predicates (queue B, part 1).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Cases (A = [[0, 1], [-2, -3]] unless stated):
// 1. observability(A, C=[[1,0]]) is true (O = [[1,0],[0,1]], rank 2).
// 2. observability(I2, C=[[1,0]]) is false (O = [[1,0],[1,0]], rank 1).
// 3. guards: empty A, non-square A, C width mismatch, empty C -> false.
// 4. controllability(A, B=[[0],[1]]) is true (K = [[0,1],[1,-3]]).
// 5. controllability(I2, B=[[1],[1]]) is false (rank 1).
// 5b. controllability(A, B=[[1],[2]]) is true.
// 6. multi-input controllability(A, B=I2) is true.
// 7. guards: B height mismatch, B zero columns, empty B -> false.
// Every call evaluates the new runtime clause (!result || a.len() > 0).
// Returns 0 when every case holds.

module p_control_theory_shapes

use xiom.math;

fn main() -> Int {
  var a = Vec[Vec[Float64]].new();
  var a0 = Vec[Float64].new();
  a0.push(0.0);
  a0.push(1.0);
  a.push(a0);
  var a1 = Vec[Float64].new();
  a1.push(-2.0);
  a1.push(-3.0);
  a.push(a1);

  var i2 = Vec[Vec[Float64]].new();
  var i0 = Vec[Float64].new();
  i0.push(1.0);
  i0.push(0.0);
  i2.push(i0);
  var i1 = Vec[Float64].new();
  i1.push(0.0);
  i1.push(1.0);
  i2.push(i1);

  var c10 = Vec[Vec[Float64]].new();
  var c0 = Vec[Float64].new();
  c0.push(1.0);
  c0.push(0.0);
  c10.push(c0);

  var b01 = Vec[Vec[Float64]].new();
  var b0 = Vec[Float64].new();
  b0.push(0.0);
  b01.push(b0);
  var b1 = Vec[Float64].new();
  b1.push(1.0);
  b01.push(b1);

  var b11 = Vec[Vec[Float64]].new();
  var f0 = Vec[Float64].new();
  f0.push(1.0);
  b11.push(f0);
  var f1 = Vec[Float64].new();
  f1.push(1.0);
  b11.push(f1);

  var b12 = Vec[Vec[Float64]].new();
  var g0 = Vec[Float64].new();
  g0.push(1.0);
  b12.push(g0);
  var g1 = Vec[Float64].new();
  g1.push(2.0);
  b12.push(g1);

  var empty_m = Vec[Vec[Float64]].new();
  var empty_c = Vec[Vec[Float64]].new();

  // 1-3: observability
  if !math.control_theory.observability(&a, &c10) { return 1; }
  if math.control_theory.observability(&i2, &c10) { return 2; }
  if math.control_theory.observability(&empty_m, &c10) { return 3; }
  if math.control_theory.observability(&a, &empty_c) { return 4; }
  var narrow = Vec[Vec[Float64]].new();
  var n0 = Vec[Float64].new();
  n0.push(1.0);
  narrow.push(n0);
  if math.control_theory.observability(&a, &narrow) { return 5; }
  var non_square = Vec[Vec[Float64]].new();
  var ns0 = Vec[Float64].new();
  ns0.push(1.0);
  ns0.push(0.0);
  ns0.push(0.0);
  non_square.push(ns0);
  var ns1 = Vec[Float64].new();
  ns1.push(0.0);
  ns1.push(1.0);
  ns1.push(0.0);
  non_square.push(ns1);
  if math.control_theory.observability(&non_square, &c10) { return 6; }

  // 4-7: controllability
  if !math.control_theory.controllability(&a, &b01) { return 7; }
  if math.control_theory.controllability(&i2, &b11) { return 8; }
  if !math.control_theory.controllability(&a, &b12) { return 9; }
  if !math.control_theory.controllability(&a, &i2) { return 10; }
  if math.control_theory.controllability(&empty_m, &b01) { return 11; }
  if math.control_theory.controllability(&a, &empty_c) { return 12; }

  return 0;
}
