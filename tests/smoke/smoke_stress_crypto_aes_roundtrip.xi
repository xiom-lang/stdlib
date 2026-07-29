module smoke_stress_crypto_aes_roundtrip
  use xiom.crypto;

  fn main() -> Int {
    var key = Vec[UInt8].new();
    var i = 0;
    while i < 16 {
      key.push(42u8);
      i = i + 1;
    }

    var plaintext = Vec[UInt8].new();
    plaintext.push(72u8);
    plaintext.push(101u8);
    plaintext.push(108u8);
    plaintext.push(108u8);
    plaintext.push(111u8);

    var encrypted = crypto.aes_encrypt(&key, &plaintext);

    match encrypted {
      Ok(ciphertext) => {
        var decrypted = crypto.aes_decrypt(&key, &ciphertext);
        match decrypted {
          Ok(recovered) => {
            if recovered.len() == plaintext.len() {
              return 0;
            }
            return 1;
          }
          Err(_) => { return 1; }
        }
      }
      Err(_) => { return 1; }
    }
  }
}
