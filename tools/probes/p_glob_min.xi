// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_glob_min
use xiom.io;
fn main() -> Int {
  var m1 = xiom.misc.glob.glob_match("*.xi", "a.xi");
  io.println("misc=" + (m1 as Str));
  var g1 = xiom.string.glob.glob_match("*.xi", "a.xi");
  io.println("string=" + (g1 as Str));
  return 0;
}
