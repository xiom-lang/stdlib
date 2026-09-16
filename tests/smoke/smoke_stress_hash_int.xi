// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_hash_int
use xiom.hash;

fn main() -> Int {
    var h = hash.hash(42);
    if h > 0 {
      return 0;
    }
    return 1;
}
