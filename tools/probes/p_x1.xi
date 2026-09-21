// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_x1
use xiom.io;
use xiom.convert;
fn main() -> Int {
  io.println("x1=" + convert.bool_to_string(xiom.string.glob.glob_match("*.xi", "main.xi")));
  return 0;
}
