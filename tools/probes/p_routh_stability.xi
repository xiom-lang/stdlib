// p_routh_stability.xi -- Routh-Hurwitz recurrence regression.
// The old row update used prev1[col] instead of prev1[col+1], so the
// stable polynomial s^2+2s+1 returned false. Expected rc 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_routh_stability

use xiom.math.control_theory;

fn den2(a: Float64, b: Float64, c: Float64) -> Vec[Float64] {
  let d = Vec[Float64].new();
  d.push(a);
  d.push(b);
  d.push(c);
  return d;
}

fn den3(a: Float64, b: Float64, c: Float64, d: Float64) -> Vec[Float64] {
  let v = Vec[Float64].new();
  v.push(a);
  v.push(b);
  v.push(c);
  v.push(d);
  return v;
}

fn main() -> Int {
  let p1 = den2(1.0, 2.0, 1.0);
  if !stability_routh_hurwitz(&p1) { return 1; }
  let p2 = den2(1.0, 3.0, 2.0);
  if !stability_routh_hurwitz(&p2) { return 2; }
  let p3 = den2(1.0, -3.0, 2.0);
  if stability_routh_hurwitz(&p3) { return 3; }
  let p4 = den3(1.0, 6.0, 11.0, 6.0);
  if !stability_routh_hurwitz(&p4) { return 4; }
  let p5 = den3(1.0, 0.0, -1.0, 0.0);
  if stability_routh_hurwitz(&p5) { return 5; }
  let p6 = den2(1.0, 0.0, 1.0);
  if stability_routh_hurwitz(&p6) { return 6; }
  return 0;
}
