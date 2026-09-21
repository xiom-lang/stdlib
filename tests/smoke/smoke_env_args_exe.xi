// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_env_args_exe
use xiom.env;

fn main() -> Int {
  var a = env.args();
  if a.len() < 1 { return 1; }

  match env.current_exe() {
    Ok(e) => { if e == "" { return 2; } },
    Err(_) => {},
  };

  return 0;
}
