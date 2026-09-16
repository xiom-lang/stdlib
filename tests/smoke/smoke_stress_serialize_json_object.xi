// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_json_object
use xiom.serialize;

fn main() -> Int {
    var s = serialize.json_string("hello");

    var obj = serialize.json_string("{ \"key\": " + s + " }");

    if obj.len() > 0 {
      return 0;
    }
    return 1;}
