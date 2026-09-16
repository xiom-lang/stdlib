// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_args
use xiom.io;

fn main() -> Int {
  var args = io.args();
  if args.len() < 1 { return 1; }

  return 0;
}
