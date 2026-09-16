// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_print
use xiom.io;

fn main() -> Int {
  io.println("smoke print test");

  io.print("inline");

  return 0;
}
