// p_regress_iter_collect.xi -- promoted regression lock (was a known failure)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locked by the v0.62.4 pin. Before it, calling the parent-module
// `iter.range(1, 3).collect()` failed clang with
// "instruction forward referenced with type 'ptr'". On official v0.62.4
// the call compiles and runs rc 0. The CLAUSE side of the same family is
// still open (adding even `ensures: result >= 0` to Range.count makes
// smoke_iter fail with an undefined __closure_N); that part stays in
// tools/known_failures/p_iter_range_collect_forwardref.xi. Expected: rc 0.
module p_regress_iter_collect

use xiom.iter;

fn main() -> Int {
  let r = iter.range(1, 3);
  let c = r.collect();
  if c.len() != 2 {
    return 2;
  }
  if c[0] != 1 || c[1] != 2 {
    return 3;
  }
  return 0;
}
