// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_hash_deterministic
use xiom.hash;

fn main() -> Int {
    var a = hash.hash(9999);
    var b = hash.hash(9999);
    if a == b {
      return 0;
    }
    return 1;
}
