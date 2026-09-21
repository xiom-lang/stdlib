// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_condvar_basic
use xiom.sync;

fn main() -> Int {
    var cv = sync.Condvar.new();
    cv.notify_one();
    cv.notify_all();
    return 0;
}
