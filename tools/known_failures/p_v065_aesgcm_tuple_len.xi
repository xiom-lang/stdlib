// p_v065_aesgcm_tuple_len.xi -- v0.64.5 candidate regression
// (REL-20261014-2123-stdlib): aes_encrypt_gcm returns Ok but the tuple
// Vec lengths read 0xFFFFFFFF (4294967295) instead of 5 and 16, and the
// decrypt call AVs. Expected rc 0; observed rc 3 on the v0.64.5 dry-run
// archive 5/5 (the length guard masks the downstream decrypt AV -- the
// source smoke tests/smoke/smoke_stress_crypto_aes_gcm.xi hits the
// 0xC0000005 directly), and rc 0 5/5 on the v0.64.4 release archive.

module p_v065_aesgcm_tuple_len

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

  let enc = crypto.aes_encrypt_gcm(&key, &nonce, &plaintext, &aad);
  match enc {
    Ok(pair) => {
      if pair.0.len() != 5 { return 3; }
      if pair.1.len() != 16 { return 4; }
      let dec = crypto.aes_decrypt_gcm(&key, &nonce, &pair.0, &pair.1, &aad);
      match dec {
        Ok(recovered) => {
          if recovered.len() == plaintext.len() { return 0; }
          return 5;
        },
        Err(_) => { return 6; },
      }
    },
    Err(_) => { return 7; },
  }
}
