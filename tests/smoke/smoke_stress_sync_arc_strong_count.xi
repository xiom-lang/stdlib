// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_arc_strong_count
use xiom.sync;

fn main() -> Int {
        var a = sync.Arc.new(200);
        var count = a.strong_count();
        a.drop();
        if count == 1 {
            return 0;
        } else {
            return 1;
        }}
