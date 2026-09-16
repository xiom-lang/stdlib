// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_once_completed
use xiom.sync;

fn main() -> Int {
    var o = sync.Once.new();
    var completed_before = o.is_completed();
    if completed_before { return 1; }
    o.call_once(fn() {
        return;
    });
    var completed_after = o.is_completed();
    if completed_after {
        return 0;
    } else {
        return 2;
    }
}
