// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_pick
use xiom.rand;

fn main() -> Int {
    var v = Vec[Int].new();
    v.push(10); v.push(20); v.push(30);
    match rand.pick(&v) {
        Some(_) => {
            return 0;
        },
        None => {
            return 1;
        }
    }
}
