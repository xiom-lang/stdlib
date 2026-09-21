// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_pbkdf2
use xiom.crypto;

fn main() -> Int {
    var salt = Vec[UInt8].new();
    var i = 0;
    while i < 16 {
      salt.push(1u8);
      i = i + 1;
    }

    var derived = crypto.pbkdf2(&"password", &salt, 1000, 32);

    if derived.len() == 32 {
      return 0;
    }
    return 1;
}
