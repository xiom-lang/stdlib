// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_stress_crypto_rsa_keypair
use xiom.crypto;

fn main() -> Int {
    // pure-XIOM RSA supports 16-32 bit keys (documented practical range)
    var kp = crypto.generate_rsa_keypair(24);
    match kp {
      Ok(pair) => {
        if pair.private.len() > 0 {
          if pair.public.len() > 0 {
            return 0;
          }
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
}
