// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_fullpath_import
use xiom.serialize.endian;
use xiom.io;

fn main() -> Int {
  var out = Vec[UInt8].new();
  xiom.serialize.endian.write_u32_le(&mut out, 0x12345678 as UInt32);
  io.println("fp len=" + out.len() + " b0=" + (out[0] as Int));
  return 0;
}
