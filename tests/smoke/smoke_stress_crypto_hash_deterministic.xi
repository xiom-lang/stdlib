// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_hash_deterministic
use xiom.crypto;

fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(120u8);
    data.push(121u8);
    data.push(122u8);

    var hash1 = crypto.sha256(&data);
    var hash2 = crypto.sha256(&data);

    if crypto.constant_time_compare(&hash1, &hash2) {
      return 0;
    }
    return 1;
}
