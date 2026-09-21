// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_os_cmp_b
use xiom.crypto;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var a = crypto.os_secure_random_bytes(32);
  var b = crypto.os_secure_random_bytes(32);
  var s = 0;
  var i = 0;
  while i < 32 { s = s + (b[i] as Int); i = i + 1; }
  io.println("cmp-b s=" + convert.int_to_string(s));
  return 0;
}
