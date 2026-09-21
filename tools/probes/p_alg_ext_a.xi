// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_alg_ext_a
use xiom.io;
use xiom.math;
fn action5(r: Int, v: Int) -> Int { return (r + v) % 5; }
fn main() -> Int {
  var ring5 = Vec[Int].new();
  var i = 0;
  while i < 5 { ring5.push(i); i = i + 1; }
  var mod5 = Vec[Int].new();
  i = 0;
  while i < 5 { mod5.push(i); i = i + 1; }
  if !math.algebra_extended.module_theory(action5, &ring5, &mod5) { io.println("z5"); return 1; }
  io.println("aggregate-chain-OK");
  return 0;
}
