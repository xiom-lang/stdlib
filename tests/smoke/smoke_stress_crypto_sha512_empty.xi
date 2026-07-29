module smoke_stress_crypto_sha512_empty
  use xiom.crypto;

  fn main() -> Int {
    var data = Vec[UInt8].new();

    var hash = crypto.sha512(&data);

    if hash.len() == 64 {
      return 0;
    }
    return 1;
  }
}
