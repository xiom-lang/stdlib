// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_sha256_large
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    var i = 0;
    while i < 10000 {
      data.push(65u8);
      i = i + 1;
    }

    var hash = crypto.sha256(&data);

    if hash.len() == 32 {
      return 0;
    }
    return 1;
}
