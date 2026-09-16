// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_int_to_string_max
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_string(2147483647);
        if result == "2147483647" {
            return 0;
        } else {
            return 1;
        }}
