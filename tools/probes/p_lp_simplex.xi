// p_lp_simplex.xi -- verification for optimization.lp_simplex (queue B part 2).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Cases:
// 1. min -3x - 2y s.t. x+y <= 4, x <= 2, y <= 3  ->  (2, 2) within 1e-9.
// 2. min -x s.t. x <= 2  ->  2.
// 3. guards -> empty: empty c, empty A, b length mismatch, ragged A,
//    negative rhs (no Phase I).
// 4. unbounded min -x s.t. -x <= 1 -> empty.
// Every call evaluates the clause result.len() == 0 || result.len() == c.len().
// Returns 0 when every case holds.

module p_lp_simplex

use xiom.math;

fn near(a: Float64, b: Float64) -> Bool {
  var d = a - b;
  if d < 0.0 { d = -d; }
  return d < 0.000000001;
}

fn main() -> Int {
  var c = Vec[Float64].new();
  c.push(-3.0);
  c.push(-2.0);
  var a = Vec[Vec[Float64]].new();
  var r0 = Vec[Float64].new();
  r0.push(1.0);
  r0.push(1.0);
  a.push(r0);
  var r1 = Vec[Float64].new();
  r1.push(1.0);
  r1.push(0.0);
  a.push(r1);
  var r2 = Vec[Float64].new();
  r2.push(0.0);
  r2.push(1.0);
  a.push(r2);
  var b = Vec[Float64].new();
  b.push(4.0);
  b.push(2.0);
  b.push(3.0);

  // 1: known LP
  var x = math.optimization.lp_simplex(&c, &a, &b);
  if x.len() != 2 { return 1; }
  if !near(x[0], 2.0) { return 2; }
  if !near(x[1], 2.0) { return 3; }

  // 2: simple bound
  var cu = Vec[Float64].new();
  cu.push(-1.0);
  var ab = Vec[Vec[Float64]].new();
  var ab0 = Vec[Float64].new();
  ab0.push(1.0);
  ab.push(ab0);
  var bb = Vec[Float64].new();
  bb.push(2.0);
  var xb = math.optimization.lp_simplex(&cu, &ab, &bb);
  if xb.len() != 1 { return 4; }
  if !near(xb[0], 2.0) { return 5; }

  // 3: guards
  var empty = Vec[Float64].new();
  var empty_a = Vec[Vec[Float64]].new();
  if math.optimization.lp_simplex(&empty, &a, &b).len() != 0 { return 6; }
  if math.optimization.lp_simplex(&c, &empty_a, &b).len() != 0 { return 7; }
  var short_b = Vec[Float64].new();
  short_b.push(1.0);
  if math.optimization.lp_simplex(&c, &a, &short_b).len() != 0 { return 8; }
  var neg_b = Vec[Float64].new();
  neg_b.push(-1.0);
  neg_b.push(2.0);
  neg_b.push(3.0);
  if math.optimization.lp_simplex(&c, &a, &neg_b).len() != 0 { return 9; }
  var ragged = Vec[Vec[Float64]].new();
  var rg0 = Vec[Float64].new();
  rg0.push(1.0);
  ragged.push(rg0);
  var rg1 = Vec[Float64].new();
  rg1.push(1.0);
  rg1.push(0.0);
  ragged.push(rg1);
  var rg2 = Vec[Float64].new();
  rg2.push(0.0);
  rg2.push(1.0);
  ragged.push(rg2);
  if math.optimization.lp_simplex(&c, &ragged, &b).len() != 0 { return 10; }

  // 4: unbounded
  var neg_row = Vec[Vec[Float64]].new();
  var nr0 = Vec[Float64].new();
  nr0.push(-1.0);
  neg_row.push(nr0);
  if math.optimization.lp_simplex(&cu, &neg_row, &bb).len() != 0 { return 11; }

  return 0;
}
