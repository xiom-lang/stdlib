// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_crossrun
use xiom.crypto;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var d = crypto.secure_random_bytes(16);
  var s = 0;
  var i = 0;
  while i < 16 { s = s * 31 + (d[i] as Int); i = i + 1; }
  io.println("hash=" + convert.int_to_string(s));
  return 0;
}
