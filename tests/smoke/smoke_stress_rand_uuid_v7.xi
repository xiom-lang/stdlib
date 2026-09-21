// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_uuid_v7
use xiom.rand;

fn main() -> Int {
    var id = rand.uuid_v7();
    var len = id.len();
        if len >= 36 {
            return 0;
        } else {
            return 1;
        }
}
