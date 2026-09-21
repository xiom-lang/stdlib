// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_atomic_int_new_load
use xiom.sync;

fn main() -> Int {
        var ai = sync.AtomicInt.new(0);
        var val = ai.load();
        if val == 0 {
            return 0;
        } else {
            return 1;
        }}
