// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_time
use xiom.io;

fn main() -> Int {
  var t = io.time_now();
  if t <= 0 { return 1; }

  return 0;
}
