// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_hmac_empty
use xiom.crypto;

fn main() -> Int {
    var key = Vec[UInt8].new();
    var data = Vec[UInt8].new();

    var mac = crypto.hmac_sha256(&key, &data);
    if mac.len() == 32 {
      return 0;
    }
    return 1;
}
