// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_x5
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var m = xiom.misc.glob.glob_match("*.xi", "main.xi");
  io.println("x5m=" + convert.bool_to_string(m));
  var g = xiom.string.glob.glob_match("*.xi", "main.xi");
  io.println("x5g=" + convert.bool_to_string(g));
  return 0;
}
