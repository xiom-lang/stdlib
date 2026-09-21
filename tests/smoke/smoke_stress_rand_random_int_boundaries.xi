// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_random_int_boundaries
use xiom.rand;

fn main() -> Int {
        var val = rand.random_int(1, 10);
        if val >= 1 {
            if val <= 10 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }
}
