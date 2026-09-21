// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_rwlock_try_write
use xiom.sync;

fn main() -> Int {
    var lock = sync.RwLock.new(88);
    match lock.try_write() {
        Some(g) => {
            var v = g.get_mut();
            g.drop();
            if v == 88 {
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
