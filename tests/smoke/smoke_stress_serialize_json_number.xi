// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_json_number
use xiom.serialize;

fn main() -> Int {
    var n = serialize.json_number(42.5);

    if n.len() > 0 {
      return 0;
    }
    return 1;}
