// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_ct_tower2
use xiom.convert.into;
use xiom.io;

fn main() -> Int {
  var ifl = into.into_float(7);
  if ifl != 7.0 { io.println("into_float"); return 2; }
  io.println("INTO_FLOAT OK");
  return 0;
}
