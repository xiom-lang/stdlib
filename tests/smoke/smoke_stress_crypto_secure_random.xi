// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_secure_random
use xiom.crypto;

fn main() -> Int {
    var bytes = crypto.secure_random_bytes(32);

    if bytes.len() == 32 {
      return 0;
    }
    return 1;
}
