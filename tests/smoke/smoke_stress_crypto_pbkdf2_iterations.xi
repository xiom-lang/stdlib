module smoke_stress_crypto_pbkdf2_iterations
  use xiom.crypto;

  fn main() -> Int {
    var salt = Vec[UInt8].new();
    salt.push(115u8); salt.push(97u8); salt.push(108u8); salt.push(116u8);
    salt.push(95u8); salt.push(104u8); salt.push(105u8); salt.push(103u8);
    salt.push(104u8); salt.push(95u8); salt.push(105u8); salt.push(116u8);
    salt.push(101u8); salt.push(114u8); salt.push(95u8); salt.push(49u8);

    var derived = crypto.pbkdf2(&"super_secret_password", &salt, 100000, 32);
    if derived.len() == 32 {
      return 0;
    }
    return 1;
  }
