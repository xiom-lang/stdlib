// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_mutex_new_lock_get
use xiom.sync.mutex;

fn main() -> Int {
    var m = mutex.mutex_new();
    mutex.mutex_lock(&m);
    var held = mutex.mutex_is_locked(&m);
    mutex.mutex_unlock(&m);
    var released = not mutex.mutex_is_locked(&m);
    if held && released {
        return 0;
    }
    return 1;
}
