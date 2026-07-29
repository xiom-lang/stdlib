module smoke_stress_crypto_blake3_basic
  use xiom.crypto;

  fn main() -> Int {
    var data = Vec[UInt8].new();
    data.push(120u8);
    data.push(105u8);
    data.push(111u8);
    data.push(109u8);

    var hash = crypto.blake3(&data);

    if hash.len() == 32 {
      return 0;
    }
    return 1;
  }
}
