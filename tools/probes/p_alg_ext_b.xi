// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_alg_ext_b
use xiom.math.algebra_extended;
fn action5(r: Int, v: Int) -> Int { return (r + v) % 5; }
fn main() -> Int {
  var ring5 = Vec[Int].new();
  var i = 0;
  while i < 5 { ring5.push(i); i = i + 1; }
  var mod5 = Vec[Int].new();
  i = 0;
  while i < 5 { mod5.push(i); i = i + 1; }
  if !algebra_extended.module_theory(action5, &ring5, &mod5) { io.println("z5"); return 1; }
  io.println("direct-import-OK");
  return 0;
}
