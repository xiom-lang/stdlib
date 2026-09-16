// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_env_home_dir
use xiom.env;

fn main() -> Int {
    var home = env.home_dir();
    match home {
      Some(_) => { return 0; }
      None => { return 1; }
    }
}
