// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_rand_sample_bernoulli
use xiom.rand;

fn main() -> Int {
    var val = rand.sample_bernoulli(0.5);
    if val == true {
        return 0;
    } else {
        if val == false {
            return 0;
        } else {
            return 1;
        }
    }
}
