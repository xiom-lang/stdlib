// p_tuple_elem_vec_read.xi -- inline Vec element read in a tuple literal
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Expected: rc 0 (`build` copies the Float64 scores 0.1/0.9 and the Int
// labels 0/1 into the (Float64, Int) pairs; both score reads land in the
// expected bands).
// Observed on compiler v0.64.2: the Float64 components pushed via the
// INLINE element reads `v.push((pred[i], lab[i]))` are corrupted (both
// band checks fail; the labels stay correct), so the program exits rc 1.
// Binding the element first (`var x = pred[i]; var y = lab[i];
// v.push((x, y))`) produces the correct values on the same pin -- that is
// the workaround applied to `machine_learning.metric_auc` (wave 101).
// The corruption needs the element read to be syntactically inside the
// tuple literal; literal pushes, variable pushes, and reads from a
// literal-built tuple vector are all correct.

module p_tuple_elem_vec_read

fn build(pred: &Vec[Float64], lab: &Vec[Int]) -> Vec[(Float64, Int)] {
  var v = Vec[(Float64, Int)].new();
  var i = 0;
  while i < pred.len() {
    v.push((pred[i], lab[i]));
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  var pv = Vec[Float64].new();
  pv.push(0.1);
  pv.push(0.9);
  var lv = Vec[Int].new();
  lv.push(0);
  lv.push(1);
  let r = build(&pv, &lv);
  let e0 = r[0];
  let e1 = r[1];
  let f0ok = e0.0 > 0.05 && e0.0 < 0.15;
  if !f0ok { return 1; }
  let f1ok = e1.0 > 0.85 && e1.0 < 0.95;
  if !f1ok { return 2; }
  if e0.1 != 0 { return 3; }
  if e1.1 != 1 { return 4; }
  return 0;
}
