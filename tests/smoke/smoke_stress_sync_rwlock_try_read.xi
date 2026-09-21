// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_rwlock_try_read
use xiom.sync;

fn main() -> Int {
    var lock = sync.RwLock.new(77);
    match lock.try_read() {
        Some(g) => {
            var v = g.get();
            g.drop();
            if v == 77 {
                return 0;
            } else {
                return 2;
            }
        },
        None => {
            return 1;
        }
    }
}
