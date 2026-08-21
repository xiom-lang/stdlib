module smoke_stress_crypto_aes_gcm
use xiom.crypto;

fn main() -> Int {
    var key = Vec[UInt8].new();
    key.push(0u8); key.push(1u8); key.push(2u8); key.push(3u8);
    key.push(4u8); key.push(5u8); key.push(6u8); key.push(7u8);
    key.push(8u8); key.push(9u8); key.push(10u8); key.push(11u8);
    key.push(12u8); key.push(13u8); key.push(14u8); key.push(15u8);

    var nonce = Vec[UInt8].new();
    nonce.push(0u8); nonce.push(1u8); nonce.push(2u8); nonce.push(3u8);
    nonce.push(4u8); nonce.push(5u8); nonce.push(6u8); nonce.push(7u8);
    nonce.push(8u8); nonce.push(9u8); nonce.push(10u8); nonce.push(11u8);

    var plaintext = Vec[UInt8].new();
    plaintext.push(72u8); plaintext.push(101u8); plaintext.push(108u8);
    plaintext.push(108u8); plaintext.push(111u8);

    var aad = Vec[UInt8].new();

    var enc = crypto.aes_encrypt_gcm(&key, &nonce, &plaintext, &aad);
    match enc {
      Ok(pair) => {
        // tuple payload via .0/.1 field access (tuple PATTERNS bind Int --
        // documented checker simplification; field access is the supported form)
        var dec = crypto.aes_decrypt_gcm(&key, &nonce, &pair.0, &pair.1, &aad);
        match dec {
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
