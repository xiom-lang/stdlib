// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_json_string
use xiom.serialize;

fn main() -> Int {
    var s = serialize.json_string("hello world");

    if s.len() > 0 {
      return 0;
    }
    return 1;}
