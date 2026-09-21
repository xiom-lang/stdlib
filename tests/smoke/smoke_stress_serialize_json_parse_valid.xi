// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_json_parse_valid
use xiom.serialize;

fn main() -> Int {
    var parsed = serialize.json_parse("{\"a\": 1, \"b\": \"text\", \"c\": true}");

    if parsed.is_ok() {
      return 0;
    }
    return 1;}
