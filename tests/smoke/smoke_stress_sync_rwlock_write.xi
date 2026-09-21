// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_rwlock_write
use xiom.sync;

fn main() -> Int {
        var lock = sync.RwLock.new(10);
        var guard = lock.write();
        var v = guard.get_mut();
        guard.drop();
        if v == 10 {
            return 0;
        } else {
            return 1;
        }}
