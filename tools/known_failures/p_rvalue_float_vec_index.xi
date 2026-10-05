// p_rvalue_float_vec_index.xi -- known failure: inline (rvalue) indexing of
// a returned Vec[Float64] reads garbage
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// On v0.64.0 (and the v0.61.3-v0.63.1 family), indexing the rvalue of a
// Vec[Float64]-returning call (`mk_f()[0]`) reads the raw bits instead of
// the stored element, while binding the same call to a `var`/`let` local
// first reads correctly, and the identical shape on Vec[Int] is correct.
// This broke xiom.stats.moments.quantile's q == 0.0 / q == 1.0 branches
// (return _sorted(data)[0]), found by tools/probes/p_wave77_shapes.xi and
// worked around by binding the sorted copy first.
//
// Expected when fixed: rc 0. On the pin: rc 1 (the Float64 rvalue read).

module p_rvalue_float_vec_index

fn mk_f() -> Vec[Float64] {
  var v = Vec[Float64].new();
  v.push(1.0);
  return v;
}

fn mk_i() -> Vec[Int] {
  var v = Vec[Int].new();
  v.push(5);
  return v;
}

fn main() -> Int {
  // Int control: the same rvalue read is correct.
  if mk_i()[0] != 5 { return 2; }
  // Bound Float64 locals are correct (the wave-77 workaround).
  var vf = mk_f();
  if vf[0] != 1.0 { return 3; }
  let lf = mk_f();
  if lf[0] != 1.0 { return 4; }
  // Bug: inline indexing of the returned Vec[Float64] rvalue misreads.
  if mk_f()[0] != 1.0 { return 1; }
  return 0;
}
