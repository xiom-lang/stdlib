// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_os_double
use xiom.crypto;
use xiom.io;
fn main() -> Int {
  var a = crypto.os_secure_random_bytes(32);
  var b = crypto.os_secure_random_bytes(32);
  if a.len() != 32 || b.len() != 32 { io.println("len"); return 1; }
  var same = true;
  var i = 0;
  while i < 32 { if a[i] != b[i] { same = false; }; i = i + 1; }
  if same { io.println("equal"); return 2; }
  io.println("double-OK");
  return 0;
}
