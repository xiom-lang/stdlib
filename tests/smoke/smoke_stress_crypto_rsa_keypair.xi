module smoke_stress_crypto_rsa_keypair
  use xiom.crypto;

  fn main() -> Int {
    var kp = crypto.generate_rsa_keypair(2048);
    match kp {
      Ok(pair) => {
        if pair.private_key.len() > 0 {
          if pair.public_key.len() > 0 {
            return 0;
          }
        }
        return 1;
      }
      Err(_) => { return 1; }
    }
  }
