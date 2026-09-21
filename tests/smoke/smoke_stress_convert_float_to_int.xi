// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_float_to_int
use xiom.convert;

fn main() -> Int {
        var result = convert.float_to_int(3.14);
        if result == 3 {
            return 0;
        } else {
            return 1;
        }}
