// p_b32_alias2: explicit alias only, convert.base32 (shim).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_alias2
use xiom.convert.base32 as cvt;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  let b = cvt.base32_encode(&v);
  io.println("alias=" + b);
  if b != "MZXW6===" { return 2; };
  0
}
