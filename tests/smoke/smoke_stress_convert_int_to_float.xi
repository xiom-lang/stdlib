// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_int_to_float
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_float(42);
        if result == 42.0 {
            return 0;
        } else {
            return 1;
        }}
