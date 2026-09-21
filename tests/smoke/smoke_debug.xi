// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_debug
use xiom.debug;
use xiom.misc;
fn main() -> Int {
  var msg = Vec[UInt8].new();
  msg.push(72); msg.push(105);
  var dump = xiom.debug.hexdump(&msg, 8);
  if dump.len() == 0 { return 1; }
  xiom.debug.assert_debug(true, "ok");
  return 0;
}
