// p_b32_alias.xi -- same-leaf shim binding characterization (base32).
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Both the leaf import and an explicit alias must reach the shim's
// base32_encode and return the RFC 4648 value for "foo".
module p_b32_alias
use xiom.convert.base32;
use xiom.convert.base32 as cvt;
use xiom.io;

fn main() -> Int {
  var v = Vec[UInt8].new();
  v.push(102); v.push(111); v.push(111);
  let a = base32.base32_encode(&v);
  let b = cvt.base32_encode(&v);
  io.println("leaf=" + a);
  io.println("alias=" + b);
  if a != "MZXW6===" { return 1; };
  if b != "MZXW6===" { return 2; };
  0
}
