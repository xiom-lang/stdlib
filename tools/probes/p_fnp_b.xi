// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_fnp_b
use xiom.io;
fn action5(r: Int, v: Int) -> Int { return (r + v) % 5; }
fn apply2(f: fn(Int, Int) -> Int, a: Int, b: Int) -> Int { return f(a, b); }
fn main() -> Int {
  var r = apply2(action5, 3, 4);
  if r != 2 { io.println("apply"); return 1; }
  io.println("user-fn-OK");
  return 0;
}
