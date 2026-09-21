// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_os_twoframes
use xiom.crypto;
use xiom.io;
use xiom.convert;
// each draw happens inside its own callee frame (single os call per frame)
fn draw() -> Vec[UInt8] {
  return crypto.os_secure_random_bytes(32);
}
fn main() -> Int {
  var a = draw();
  var b = draw();
  var sa = 0;
  var i = 0;
  while i < 32 { sa = sa + (a[i] as Int); i = i + 1; }
  var sb = 0;
  i = 0;
  while i < 32 { sb = sb + (b[i] as Int); i = i + 1; }
  io.println("twoframes sa=" + convert.int_to_string(sa) + " sb=" + convert.int_to_string(sb));
  if sa == sb { io.println("equal!"); return 1; }
  return 0;
}
