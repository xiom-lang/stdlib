// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_charat_probe
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var c1 = "abc".char_at(0);
  io.println("method=" + convert.int_to_string(c1 as Int));
  var f = xiom.string.char_at("abc", 0);
  if f.is_some { io.println("free=some"); } else { io.println("free=none"); }
  return 0;
}
