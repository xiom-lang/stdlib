// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_serialize_detect_format_json
use xiom.serialize;

fn main() -> Int {
    var json_data = Vec[UInt8].new();
    json_data.push(123u8); json_data.push(34u8); json_data.push(110u8);
    json_data.push(97u8); json_data.push(109u8); json_data.push(101u8);
    json_data.push(34u8); json_data.push(58u8); json_data.push(34u8);
    json_data.push(88u8); json_data.push(34u8); json_data.push(125u8);

    var fmt = serialize.detect_format(&json_data);
    if fmt.len() > 0 {
      return 0;
    }
    return 1;
}
