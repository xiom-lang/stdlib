// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_rwlock_read
use xiom.sync;

fn main() -> Int {
        var lock = sync.RwLock.new(55);
        var guard = lock.read();
        var v = guard.get();
        guard.drop();
        if v == 55 {
            return 0;
        } else {
            return 1;
        }}
