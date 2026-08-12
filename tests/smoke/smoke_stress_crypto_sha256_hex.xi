module smoke_stress_crypto_sha256_hex
  use xiom.crypto;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(97u8);
    data.push(98u8);
    data.push(99u8);

    var hex = crypto.sha256_hex(&data);

    if hex.len() == 64 {
      return 0;
    }
    return 1;
  }
