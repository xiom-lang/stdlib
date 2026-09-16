// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_identity
use xiom.convert;

fn main() -> Int {
        var val = 42;
        var same = convert.identity(val);
        if same == val {
            return 0;
        } else {
            return 1;
        }}
