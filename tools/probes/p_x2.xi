// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_x2
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var pat = "*.xi";
  var s = "main.xi";
  io.println("x2=" + convert.bool_to_string(xiom.string.glob.glob_match(pat, s)));
  return 0;
}
