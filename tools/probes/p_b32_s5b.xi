// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_s5b
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  io.println("A-before"); io.flush_stdout();
  io.println("B-enc=" + base32.base32_encode(&v)); io.flush_stdout();
  return 0;
}
