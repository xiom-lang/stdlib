// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_error_fields
use xiom.serialize.json;

fn main() -> Int {
    var bad_json = "{invalid";

    var result = json.json_parse(bad_json);
    match result {
      Ok(_) => { return 1; }
      Err(msg) => {
        // parse errors surface as a Str message
        if msg.len() > 0 {
          return 0;
        }
        return 2;
      }
    }
}
