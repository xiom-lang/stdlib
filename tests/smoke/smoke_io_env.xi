// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_io_env
use xiom.io;

fn main() -> Int {
  var home = io.env_var("PATH");
  match home {
    Some(_) => { return 0; },
    None => { return 0; },
  };

  return 0;
}
