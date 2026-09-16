// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_env_constants
use xiom.env;

fn main() -> Int {
    if env.OS.len() > 0 && env.ARCH.len() > 0 {
      return 0;
    }
    return 1;
}
