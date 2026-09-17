// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_sdx_shim_first
use xiom.io;
fn main() -> Int {
  var s = xiom.string.soundex.soundex("Robert");
  io.println("sdx=[" + s + "]");
  return 0;
}
