// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_s5a
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  io.println("A-before"); io.flush_stdout();
  let e = base32.base32_encode(&v);
  io.println("B-enc=" + e); io.flush_stdout();
  return 0;
}
