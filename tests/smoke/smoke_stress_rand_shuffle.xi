// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_shuffle
use xiom.rand;

fn main() -> Int {
    var v = Vec[Int].new();
    v.push(1); v.push(2); v.push(3); v.push(4); v.push(5);
    rand.shuffle(&mut v);
    var count = v.len();
    if count == 5 {
        return 0;
    } else {
        return 1;
    }
}
