// p_wave70_shapes.xi -- wave 70 shape validation: crypto (mac/kdf/keyx/sign/rng)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-70 clause guards on xiom.crypto.mac (12),
// xiom.crypto.kdf (9), xiom.crypto.keyx (9, incl. X25519/secp256k1 ECDH on
// this pin), xiom.crypto.rng_crypto (5), xiom.crypto.sign (5) and
// xiom.poly1305 (1); returns 0 when every case holds. No network I/O;
// random values are probed with bands only.

module p_wave70_shapes

use xiom.crypto.mac;
use xiom.crypto.kdf;
use xiom.crypto.rng_crypto;
use xiom.crypto.keyx;
use xiom.crypto.sign;
use xiom.poly1305;

fn _zeros(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(0u8);
    i = i + 1;
  }
  return v;
}

fn _seq(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  var key = _seq(32);
  var key16 = _seq(16);
  var iv16 = _seq(16);
  var data = Vec[UInt8].new();
  data.push(72u8);
  data.push(105u8);
  data.push(32u8);
  data.push(84u8);
  data.push(104u8);
  data.push(101u8);
  data.push(114u8);
  data.push(101u8);

  // ---- mac: HMAC one-shot and incremental
  let h256 = mac.hmac_sha256(&key, &data);
  if h256.len() != 32 { return 1; }
  let h512 = mac.hmac_sha512(&key, &data);
  if h512.len() != 64 { return 2; }
  let c1 = mac.hmac_new(&key, 1);
  if c1.block != 64 { return 3; }
  if c1.key.len() != 64 { return 4; }
  if c1.data.len() != 0 { return 5; }
  if c1.hash != 1 { return 6; }
  let c2 = mac.hmac_new(&key, 2);
  if c2.block != 128 { return 7; }
  if c2.key.len() != 128 { return 8; }
  var inc = mac.hmac_new(&key, 1);
  mac.hmac_update(&mut inc, &data);
  if inc.data.len() != data.len() { return 9; }
  let fin = mac.hmac_final(inc);
  if fin.len() != 32 { return 10; }
  var inc2 = mac.hmac_new(&key, 2);
  mac.hmac_update(&mut inc2, &data);
  if mac.hmac_final(inc2).len() != 64 { return 11; }
  var inc3 = mac.hmac_new(&key, 3);
  mac.hmac_update(&mut inc3, &data);
  if mac.hmac_final(inc3).len() != 16 { return 12; }
  if !mac.hmac_verify(&key, &data, &h256) { return 13; }
  var zero32 = _zeros(32);
  if mac.hmac_verify(&key, &data, &zero32) { return 14; }
  var short_tag = _zeros(16);
  if mac.hmac_verify(&key, &data, &short_tag) { return 15; }

  // ---- mac: CBC-MAC / CMAC / constant-time
  var data17 = _seq(17);
  if mac.cbc_mac(&key16, &iv16, &data17).len() != 16 { return 16; }
  var empty = Vec[UInt8].new();
  if mac.cbc_mac(&key16, &iv16, &empty).len() != 16 { return 17; }
  if mac.cmac_aes128(&key16, &data17).len() != 16 { return 18; }
  if mac.cmac_aes128(&key16, &empty).len() != 16 { return 19; }
  var a3 = _seq(3);
  var a3b = _seq(3);
  var a3c = Vec[UInt8].new();
  a3c.push(1u8);
  a3c.push(2u8);
  a3c.push(4u8);
  if !mac.constant_time_eq(&a3, &a3b) { return 20; }
  if mac.constant_time_eq(&a3, &a3c) { return 21; }
  if mac.constant_time_eq(&a3, &empty) { return 22; }
  if mac.constant_time_select(7, 9, true) != 7 { return 23; }
  if mac.constant_time_select(7, 9, false) != 9 { return 24; }

  // ---- mac: Poly1305 (wrapper + canonical)
  let pm = mac.poly1305_mac(&key, &data);
  if pm.len() != 16 { return 25; }
  if !mac.poly1305_verify(&key, &data, &pm) { return 26; }
  if mac.poly1305_verify(&key, &data, &short_tag) { return 27; }
  if poly1305.poly1305_mac(&key, &data).len() != 16 { return 28; }

  // ---- kdf: PBKDF2 / HKDF
  var pass = Vec[UInt8].new();
  pass.push(112u8);
  pass.push(97u8);
  pass.push(115u8);
  pass.push(115u8);
  var salt = Vec[UInt8].new();
  salt.push(115u8);
  salt.push(97u8);
  salt.push(108u8);
  salt.push(116u8);
  if kdf.pbkdf2(&pass, &salt, 1, 64).len() != 64 { return 29; }
  if kdf.pbkdf2(&pass, &salt, 0, 64).len() != 0 { return 30; }
  if kdf.pbkdf2(&pass, &salt, 1, 0).len() != 0 { return 31; }
  if kdf.pbkdf2_hmac_sha256(&pass, &salt, 2, 32).len() != 32 { return 32; }
  if kdf.pbkdf2_hmac_sha256(&pass, &salt, 1, 0).len() != 0 { return 33; }
  var ikm = _seq(22);
  var salt2 = _seq(13);
  var info = Vec[UInt8].new();
  info.push(240u8);
  info.push(241u8);
  let prk = kdf.hkdf_extract(1, &ikm, &salt2);
  if prk.len() != 32 { return 34; }
  if kdf.hkdf_extract(2, &ikm, &salt2).len() != 64 { return 35; }
  if kdf.hkdf_expand(1, &prk, &info, 42).len() != 42 { return 36; }
  if kdf.hkdf_expand(1, &prk, &info, 0).len() != 0 { return 37; }
  if kdf.hkdf_expand(1, &prk, &info, 8161).len() != 0 { return 38; }
  if kdf.hkdf_expand(2, &prk, &info, 64).len() != 64 { return 39; }
  if kdf.hkdf_expand(2, &prk, &info, 16321).len() != 0 { return 40; }
  if kdf.hkdf_sha256(&ikm, &salt2, &info, 42).len() != 42 { return 41; }
  if kdf.hkdf_sha256(&ikm, &salt2, &info, 0).len() != 0 { return 42; }
  if kdf.kdf_derive_master(&ikm, &salt2, &info, 32).len() != 32 { return 43; }
  if kdf.kdf_derive_master(&ikm, &salt2, &info, 0).len() != 0 { return 44; }
  if kdf.kdf_check_interval(0) != 1 { return 45; }
  if kdf.kdf_check_interval(1000001) != 1000000 { return 46; }
  if kdf.kdf_check_interval(7) != 7 { return 47; }
  if kdf.argon2id(&pass, &salt, 1024, 2, 1, 32).len() != 32 { return 48; }
  if kdf.argon2id(&pass, &salt, 0, 0, 0, 0).len() != 0 { return 49; }
  if kdf.bcrypt(&pass, &salt, 4).len() != 24 { return 50; }

  // ---- rng_crypto
  if rng_crypto.crypto_random_bytes(32).len() != 32 { return 51; }
  if rng_crypto.crypto_random_bytes(-1).len() != 0 { return 52; }
  let un = rng_crypto.crypto_random_uniform(7);
  if un < 0 || un >= 7 { return 53; }
  if rng_crypto.crypto_random_uniform(0) != 0 { return 54; }
  if rng_crypto.crypto_random_uniform(-3) != 0 { return 55; }
  let rf = rng_crypto.crypto_random_float();
  if rf < 0.0 || rf >= 1.0 { return 56; }
  if rng_crypto.crypto_random_prime(16).len() != 2 { return 57; }
  if rng_crypto.crypto_random_prime(8).len() != 0 { return 58; }
  if rng_crypto.crypto_random_prime(4096).len() != 0 { return 59; }
  if rng_crypto.crypto_random_string(8, "abc").len() != 8 { return 60; }
  if rng_crypto.crypto_random_string(-1, "abc").len() != 0 { return 61; }
  if rng_crypto.crypto_random_string(8, "").len() != 0 { return 62; }

  // ---- keyx: classic DH + agreement helpers + X25519/secp256k1
  var p2 = Vec[UInt8].new();
  p2.push(255u8);
  p2.push(255u8);
  var g2 = Vec[UInt8].new();
  g2.push(2u8);
  let dhk = keyx.dh_generate_key(&p2, &g2);
  if dhk.len() != 2 { return 63; }
  if keyx.dh_shared_secret(&p2, &dhk, &dhk).len() != 2 { return 64; }
  var pk32 = _seq(32);
  if !keyx.key_agreement_validate(&pk32) { return 65; }
  var z32 = _zeros(32);
  if keyx.key_agreement_validate(&z32) { return 66; }
  var short31 = _seq(31);
  if keyx.key_agreement_validate(&short31) { return 67; }
  if keyx.key_agreement_derive(&pk32, &info, 16).len() != 16 { return 68; }
  if keyx.key_agreement_derive(&pk32, &info, 0).len() != 0 { return 69; }
  if keyx.ecdh_p256(&pk32, &pk32).len() != 0 { return 70; }
  let xpk = keyx.x25519_public_key(&pk32);
  if xpk.len() != 32 { return 76; }
  if keyx.x25519_shared_secret(&pk32, &xpk).len() != 32 { return 77; }
  if keyx.x25519_base(&pk32).len() != 32 { return 78; }
  if keyx.ecdh_secp256k1(&pk32, &pk32).len() != 32 { return 79; }

  // ---- sign: documented stubs return empty / false
  if sign.ed25519_sign(&key, &data).len() != 0 { return 71; }
  if sign.ed25519_public_key(&key).len() != 0 { return 72; }
  if sign.ed25519_verify(&key, &data, &short_tag) { return 73; }
  if sign.ecdsa_verify(1, &key, &data, &key, &key) { return 74; }
  if sign.dsa_verify(&key, &key, &key, &key, &data, &key, &key) { return 75; }

  return 0;
}
