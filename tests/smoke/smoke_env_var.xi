// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_env_var
use xiom.env;

fn main() -> Int {
  var v = env.get_var("PATH");
  match v {
    Ok(p) => { if p == "" { return 0; } },
    Err(_) => {},
  };

  return 0;
}
