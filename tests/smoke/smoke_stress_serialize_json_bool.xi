// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_json_bool
use xiom.serialize;

fn main() -> Int {
    var t = serialize.json_bool(true);
    var f = serialize.json_bool(false);

    if t.len() > 0 {
      if f.len() > 0 {
        return 0;
      }
    }
    return 1;}
