// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_sha256_basic
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(104u8);
    data.push(101u8);
    data.push(108u8);
    data.push(108u8);
    data.push(111u8);

    var hash = crypto.sha256(&data);
    var hex = crypto.sha256_hex(&data);

    if hash.len() == 32 {
      return 0;
    }
    return 1;
}
