// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_atomic_bool
use xiom.sync;

fn main() -> Int {
        var ab = sync.AtomicBool.new(false);
        var val1 = ab.load();
        ab.store(true);
        var val2 = ab.load();
        if not val1 {
            if val2 {
                return 0;
            } else {
                return 2;
            }
        } else {
            return 1;
        }}
