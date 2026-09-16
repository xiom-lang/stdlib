// q1_io_only.xi -- import ONLY xiom.io to surface io.xi catalog warnings.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module q1_io_only
use xiom.io;

fn main() -> Int {
  io.println("q1-io");
  return 0;
}
