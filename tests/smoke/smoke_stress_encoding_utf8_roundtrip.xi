// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_encoding_utf8_roundtrip
use xiom.encoding;

fn main() -> Int {
    var s = "hello";
    var data = encoding.utf8_encode(s);
    match encoding.utf8_decode(&data) {
      Ok(decoded) => {
        if decoded == s {
          return 0;
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
