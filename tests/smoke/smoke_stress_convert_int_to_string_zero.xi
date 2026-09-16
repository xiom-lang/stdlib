// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_convert_int_to_string_zero
use xiom.convert;

fn main() -> Int {
        var result = convert.int_to_string(0);
        if result == "0" {
            return 0;
        } else {
            return 1;
        }}
