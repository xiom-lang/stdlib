// XIOM Hot Reload Test -- used with xiom_hot_host.exe
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Demonstrates the hot reload cycle: change this file,
// save, and the host will recompile and reload automatically.

pub fn greet() -> Int {
    return 1;  // Change this value and save to see hot reload in action
}

fn main() -> Int {
    // Simulate some work
    var counter: Int = 0;
    while counter < 5 {
        counter = counter + 1;
    }
    // Call greet through hot reload thunk
    let result: Int = greet();
    return result;
}
