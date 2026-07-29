module smoke_stress_crypto_argon2_basic
  use xiom.crypto;

  fn main() -> Int {
    var salt = Vec[UInt8].new();
    salt.push(115u8); salt.push(111u8); salt.push(109u8); salt.push(101u8);
    salt.push(115u8); salt.push(97u8); salt.push(108u8); salt.push(116u8);
    salt.push(49u8); salt.push(50u8); salt.push(51u8); salt.push(52u8);
    salt.push(53u8); salt.push(54u8); salt.push(55u8); salt.push(56u8);

    var hash = crypto.argon2(&"password123", &salt, 3, 65536, 1, 32);
    if hash.len() == 32 {
      return 0;
    }
    return 1;
  }
