// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_sync_barrier
use xiom.sync;

fn main() -> Int {
        var b = sync.Barrier.new(1);
        b.wait();
        return 0;}
