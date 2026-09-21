// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_fnp_a
use xiom.io;
use xiom.math.algebra_extended;
fn action5(r: Int, v: Int) -> Int { return (r + v) % 5; }
fn apply2(f: fn(Int, Int) -> Int, a: Int, b: Int) -> Int { return f(a, b); }
fn main() -> Int {
  var ring5 = Vec[Int].new();
  var i = 0;
  while i < 5 { ring5.push(i); i = i + 1; }
  if !algebra_extended.group_theory(action5, &ring5, 0) { io.println("group"); return 1; }
  io.println("group-OK");
  return 0;
}
