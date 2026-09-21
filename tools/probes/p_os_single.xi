// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_os_single
use xiom.crypto;
use xiom.io;
fn main() -> Int {
  var a = crypto.os_secure_random_bytes(32);
  if a.len() != 32 { io.println("len"); return 1; }
  io.println("single-OK");
  return 0;
}
