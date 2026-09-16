// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_atomic_int_swap
use xiom.sync.atomics;

fn main() -> Int {
    var ai = atomics.atomic_int_new(100);
    var old = atomics.atomic_swap(&ai, 200);
    var new_val = atomics.atomic_load(&ai);
    if old == 100 {
        if new_val == 200 {
            return 0;
        } else {
            return 2;
        }
    } else {
        return 1;
    }
}
