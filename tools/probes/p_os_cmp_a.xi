// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_os_cmp_a
use xiom.crypto;
use xiom.io;
use xiom.convert;
fn main() -> Int {
  var a = crypto.os_secure_random_bytes(32);
  var b = crypto.os_secure_random_bytes(32);
  var s = 0;
  var i = 0;
  while i < 32 { s = s + (a[i] as Int); i = i + 1; }
  io.println("cmp-a s=" + convert.int_to_string(s));
  return 0;
}
