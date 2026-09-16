// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_sample_exponential
use xiom.rand;

fn main() -> Int {
    var val = rand.sample_exponential(1.0);
    if val >= 0.0 {
        return 0;
    } else {
        return 1;
    }
}
