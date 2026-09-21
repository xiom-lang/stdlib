// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_hash_bool
use xiom.hash;

fn main() -> Int {
    var t1 = hash.hash(true);
    var t2 = hash.hash(true);
    var f1 = hash.hash(false);
    if t1 == t2 && t1 != f1 {
      return 0;
    }
    return 1;
}
