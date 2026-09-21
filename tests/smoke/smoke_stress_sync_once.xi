// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_once
use xiom.sync;

fn main() -> Int {
        var o = sync.Once.new();
        var completed = o.is_completed();
        if not completed {
            return 0;
        } else {
            return 1;
        }}
