module smoke_stress_crypto_aes_bad_key
use xiom.crypto;

fn main() -> Int {
    var bad_key = Vec[UInt8].new();
    bad_key.push(1u8); bad_key.push(2u8); bad_key.push(3u8);

    var plaintext = Vec[UInt8].new();
    plaintext.push(72u8); plaintext.push(101u8); plaintext.push(108u8);
    plaintext.push(108u8); plaintext.push(111u8);

    var enc = crypto.aes_encrypt(&bad_key, &plaintext);
    match enc {
      Ok(_) => { return 1; }
      Err(_) => { return 0; }
    }
}
