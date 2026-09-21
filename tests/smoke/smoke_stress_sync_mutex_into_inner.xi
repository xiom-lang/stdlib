// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_mutex_into_inner
use xiom.sync.mutex;

fn main() -> Int {
    var m = mutex.mutex_new();
    var handle = mutex.mutex_into_inner(&m);
    if handle != 0 {
        return 0;
    }
    return 1;
}
