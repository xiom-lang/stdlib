module smoke_stress_crypto_secure_random
  use xiom.crypto;

  fn main() -> Int {
    var bytes = crypto.secure_random_bytes(32);

    if bytes.len() == 32 {
      return 0;
    }
    return 1;
  }
}
