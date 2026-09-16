// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_b32_import_only
use xiom.convert.base32;
use xiom.io;

fn main() -> Int {
  io.println("IMPORT-ONLY OK");
  io.flush_stdout();
  return 0;
}
