// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_encoding_hex_roundtrip
use xiom.encoding;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(0x4au8);
    data.push(0x5fu8);
    data.push(0xc3u8);
    var encoded = encoding.hex_encode(&data);
    match encoding.hex_decode(encoded) {
      Ok(decoded) => {
        if decoded.len() == data.len() {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
