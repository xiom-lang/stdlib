// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_int_to_char
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_char(65);
        match result {
            Some(c) => {
                if c == 'A' {
                    return 0;
                } else {
                    return 1;
                }
            },
            None => {
                return 1;
            }
        }}
