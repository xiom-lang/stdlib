// p_linear_programming.xi -- verification for optimization.linear_programming
// (queue B part 2b: per-variable bound modes on top of lp_simplex).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Cases (base LP: min -3x -2y s.t. x+y <= 4, x <= 2, y <= 3):
// 1. empty bounds delegates to lp_simplex -> (2, 2), identical to the
//    direct lp_simplex call.
// 2. bound modes: x in [0,1] (both-bounded, adds z <= 1), y in [0,+inf)
//    (lower-only) -> (1, 3).
// 3. upper-only: min -x s.t. x <= 3, x in (-inf,2] -> 2.
// 4. free: min x s.t. x >= -1 (-x <= 1), x in (-inf,+inf) -> -1
//    (z+ - z- split; a 0 default would give 0).
// 5. both-bounded single variable: min -x s.t. x <= 10, x in [0,2] -> 2.
// 6. fixed variable: min x s.t. x <= 5, x in [2,2] -> 2.
// 7. guards -> empty: bounds length mismatch, lo > hi, more than two
//    bounds entries, and the documented limitation that a shifted
//    b2 with a negative entry (x >= 1 with x <= 0) returns empty.
// Every call evaluates the clause result.len() == 0 || result.len() == c.len().
// Returns 0 when every case holds.

module p_linear_programming

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

  // 1: empty bounds -> direct delegation identity.
  var no_bounds = Vec[Vec[Float64]].new();
  var x1 = math.optimization.linear_programming(&c, &a, &b, &no_bounds);
  if x1.len() != 2 { return 1; }
  if !near(x1[0], 2.0) { return 2; }
  if !near(x1[1], 2.0) { return 3; }
  var x1d = math.optimization.lp_simplex(&c, &a, &b);
  if x1d.len() != 2 { return 4; }
  if !near(x1[0], x1d[0]) { return 5; }
  if !near(x1[1], x1d[1]) { return 6; }

  // 2: both-bounded x, lower-only y.
  var bnd = Vec[Vec[Float64]].new();
  var e0 = Vec[Float64].new();
  e0.push(0.0);
  e0.push(1.0);
  bnd.push(e0);
  var e1 = Vec[Float64].new();
  e1.push(0.0);
  e1.push(1.0 / 0.0);
  bnd.push(e1);
  var x2 = math.optimization.linear_programming(&c, &a, &b, &bnd);
  if x2.len() != 2 { return 7; }
  if !near(x2[0], 1.0) { return 8; }
  if !near(x2[1], 3.0) { return 9; }

  // 3: upper-only.
  var ch = Vec[Float64].new();
  ch.push(-1.0);
  var ah = Vec[Vec[Float64]].new();
  var hr = Vec[Float64].new();
  hr.push(1.0);
  ah.push(hr);
  var bh = Vec[Float64].new();
  bh.push(3.0);
  var bndh = Vec[Vec[Float64]].new();
  var eh = Vec[Float64].new();
  eh.push(-1.0 / 0.0);
  eh.push(2.0);
  bndh.push(eh);
  var x3 = math.optimization.linear_programming(&ch, &ah, &bh, &bndh);
  if x3.len() != 1 { return 10; }
  if !near(x3[0], 2.0) { return 11; }

  // 4: free variable (z+ - z- split).
  var cf = Vec[Float64].new();
  cf.push(1.0);
  var af = Vec[Vec[Float64]].new();
  var fr = Vec[Float64].new();
  fr.push(-1.0);
  af.push(fr);
  var bf = Vec[Float64].new();
  bf.push(1.0);
  var bndf = Vec[Vec[Float64]].new();
  var ef = Vec[Float64].new();
  ef.push(-1.0 / 0.0);
  ef.push(1.0 / 0.0);
  bndf.push(ef);
  var x4 = math.optimization.linear_programming(&cf, &af, &bf, &bndf);
  if x4.len() != 1 { return 12; }
  if !near(x4[0], -1.0) { return 13; }

  // 5: both-bounded single variable.
  var cb = Vec[Float64].new();
  cb.push(-1.0);
  var ab = Vec[Vec[Float64]].new();
  var br = Vec[Float64].new();
  br.push(1.0);
  ab.push(br);
  var bb = Vec[Float64].new();
  bb.push(10.0);
  var bndb = Vec[Vec[Float64]].new();
  var eb = Vec[Float64].new();
  eb.push(0.0);
  eb.push(2.0);
  bndb.push(eb);
  var x5 = math.optimization.linear_programming(&cb, &ab, &bb, &bndb);
  if x5.len() != 1 { return 14; }
  if !near(x5[0], 2.0) { return 15; }

  // 6: fixed variable (hi == lo).
  var cx = Vec[Float64].new();
  cx.push(1.0);
  var ax = Vec[Vec[Float64]].new();
  var xr = Vec[Float64].new();
  xr.push(1.0);
  ax.push(xr);
  var bx = Vec[Float64].new();
  bx.push(5.0);
  var bndx = Vec[Vec[Float64]].new();
  var ex = Vec[Float64].new();
  ex.push(2.0);
  ex.push(2.0);
  bndx.push(ex);
  var x6 = math.optimization.linear_programming(&cx, &ax, &bx, &bndx);
  if x6.len() != 1 { return 16; }
  if !near(x6[0], 2.0) { return 17; }

  // 7: guards.
  var short = Vec[Vec[Float64]].new();
  short.push(e0);
  if math.optimization.linear_programming(&c, &a, &b, &short).len() != 0 { return 18; }
  var bad = Vec[Vec[Float64]].new();
  var br0 = Vec[Float64].new();
  br0.push(3.0);
  br0.push(1.0);
  bad.push(br0);
  bad.push(e1);
  if math.optimization.linear_programming(&c, &a, &b, &bad).len() != 0 { return 19; }
  var wide = Vec[Vec[Float64]].new();
  var wr = Vec[Float64].new();
  wr.push(0.0);
  wr.push(1.0);
  wr.push(2.0);
  wide.push(wr);
  wide.push(e1);
  if math.optimization.linear_programming(&c, &a, &b, &wide).len() != 0 { return 20; }
  var cl = Vec[Float64].new();
  cl.push(1.0);
  var al = Vec[Vec[Float64]].new();
  var lr = Vec[Float64].new();
  lr.push(1.0);
  al.push(lr);
  var bl = Vec[Float64].new();
  bl.push(0.0);
  var bndl = Vec[Vec[Float64]].new();
  var el = Vec[Float64].new();
  el.push(1.0);
  el.push(1.0 / 0.0);
  bndl.push(el);
  if math.optimization.linear_programming(&cl, &al, &bl, &bndl).len() != 0 { return 21; }

  return 0;
}
