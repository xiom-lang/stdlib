// XIOM - Cryptography: AEAD
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.crypto.aead

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Authenticated encryption with associated data, algorithm-generic.
//
// Algorithm identifiers (documented here; the constants are stable API):
//   1 = AES-128-GCM (16-byte key, 12-byte nonce, 16-byte tag)
//   2 = AES-256-GCM (32-byte key, 12-byte nonce, 16-byte tag)
//   3 = ChaCha20-Poly1305 (32-byte key, 12-byte nonce, 16-byte tag)
//
// Layouts:
//   - aead_encrypt / aead_decrypt use a separate nonce and return/accept the
//     ciphertext with the tag appended (ct || tag).
//   - aead_seal / aead_open prepend/consume a freshly generated nonce
//     (nonce || ct || tag).
//   - aead_encrypt_detached returns (ciphertext, tag) separately.
//
// Security notes:
//   - A nonce MUST NOT be reused under the same key.
//   - aead_open / aead_decrypt verify the authentication tag (constant time)
//     before releasing plaintext.
// ============================================================================

use xiom.crypto;
use xiom.crypto.cipher;

const _ALG_AES128_GCM: Int = 1;
const _ALG_AES256_GCM: Int = 2;
const _ALG_CHACHA20_POLY1305: Int = 3;
const _NONCE_SIZE: Int = 12;
const _TAG_SIZE: Int = 16;

/// Whether an algorithm identifier is implemented.
/// Complexity: O(1).
pub fn aead_alg_supported(alg: Int) -> Bool {
  return alg == _ALG_AES128_GCM || alg == _ALG_AES256_GCM || alg == _ALG_CHACHA20_POLY1305;
}

/// Nonce length in bytes for an algorithm (12 for all supported algorithms).
/// Returns 0 for unknown algorithms.
/// Complexity: O(1).
pub fn aead_nonce_size(alg: Int) -> Int {
  if aead_alg_supported(alg) { return _NONCE_SIZE; }
  return 0;
}

/// Tag length in bytes for an algorithm (16 for all supported algorithms).
/// Returns 0 for unknown algorithms.
/// Complexity: O(1).
pub fn aead_tag_size(alg: Int) -> Int {
  if aead_alg_supported(alg) { return _TAG_SIZE; }
  return 0;
}

/// Key length in bytes for an algorithm: 16 (AES-128-GCM), 32 otherwise.
/// Returns 0 for unknown algorithms.
/// Complexity: O(1).
pub fn aead_key_size(alg: Int) -> Int {
  if alg == _ALG_AES128_GCM { return 16; }
  if aead_alg_supported(alg) { return 32; }
  return 0;
}

/// Generate a random nonce of the right size for an algorithm.
/// Complexity: O(1).
pub fn aead_generate_nonce(alg: Int) -> Vec[UInt8] {
  var size = aead_nonce_size(alg);
  if size <= 0 { return Vec[UInt8].new(); }
  return crypto.secure_random_bytes(size);
}

fn _aead_seal_alg(alg: Int, key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if alg == _ALG_CHACHA20_POLY1305 {
    return Ok(cipher.chacha20poly1305_encrypt(key, nonce, data, aad));
  }
  return Ok(cipher.aes_encrypt_gcm(key, nonce, data, aad));
}

/// Encrypt `data` with associated data `aad` under `key`/`nonce`; returns the
/// ciphertext with the 16-byte authentication tag appended.
/// Complexity: O(n), n = data length.
pub fn aead_encrypt(alg: Int, key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(aead_alg_supported(alg)) {
    return Err("aead_encrypt: unsupported algorithm");
  }
  if key.len() != aead_key_size(alg) {
    return Err("aead_encrypt: invalid key length");
  }
  if nonce.len() != aead_nonce_size(alg) {
    return Err("aead_encrypt: invalid nonce length");
  }
  return _aead_seal_alg(alg, key, nonce, data, aad);
}

/// Verify the tag and decrypt. `data` is the ciphertext with the 16-byte tag
/// appended; `tag` is the expected tag (the trailing bytes of `data`).
/// Complexity: O(n), n = data length.
pub fn aead_decrypt(alg: Int, key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8], tag: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(aead_alg_supported(alg)) {
    return Err("aead_decrypt: unsupported algorithm");
  }
  if key.len() != aead_key_size(alg) {
    return Err("aead_decrypt: invalid key length");
  }
  if nonce.len() != aead_nonce_size(alg) {
    return Err("aead_decrypt: invalid nonce length");
  }
  if alg == _ALG_CHACHA20_POLY1305 {
    return cipher.chacha20poly1305_decrypt(key, nonce, data, aad, tag);
  }
  return cipher.aes_decrypt_gcm(key, nonce, data, aad, tag);
}

/// Encrypt with a freshly generated nonce prepended:
/// nonce || ciphertext || tag.
/// Complexity: O(n), n = data length.
pub fn aead_seal(alg: Int, key: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(aead_alg_supported(alg)) {
    return Err("aead_seal: unsupported algorithm");
  }
  if key.len() != aead_key_size(alg) {
    return Err("aead_seal: invalid key length");
  }
  var nonce = aead_generate_nonce(alg);
  let body = _aead_seal_alg(alg, key, &nonce, data, aad);
  match body {
    Ok(b) => {
      var result = Vec[UInt8].new();
      var i = 0;
      while i < nonce.len() {
        result.push(nonce[i]);
        i = i + 1;
      }
      i = 0;
      while i < b.len() {
        result.push(b[i]);
        i = i + 1;
      }
      return Ok(result);
    }
    Err(e) => { return Err(e); }
  }
}

/// Decrypt a sealed message (nonce || ciphertext || tag).
/// Complexity: O(n), n = data length.
pub fn aead_open(alg: Int, key: &Vec[UInt8], sealed: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str> {
  if !(aead_alg_supported(alg)) {
    return Err("aead_open: unsupported algorithm");
  }
  if key.len() != aead_key_size(alg) {
    return Err("aead_open: invalid key length");
  }
  var nonce_size = aead_nonce_size(alg);
  var tag_size = aead_tag_size(alg);
  if sealed.len() < nonce_size + tag_size {
    return Err("aead_open: sealed message too short");
  }
  var nonce = Vec[UInt8].new();
  var i = 0;
  while i < nonce_size {
    nonce.push(sealed[i]);
    i = i + 1;
  }
  var body = Vec[UInt8].new();
  while i < sealed.len() - tag_size {
    body.push(sealed[i]);
    i = i + 1;
  }
  var tag = Vec[UInt8].new();
  while i < sealed.len() {
    tag.push(sealed[i]);
    i = i + 1;
  }
  if alg == _ALG_CHACHA20_POLY1305 {
    return cipher.chacha20poly1305_decrypt(key, &nonce, &body, aad, &tag);
  }
  return cipher.aes_decrypt_gcm(key, &nonce, &body, aad, &tag);
}

/// Encrypt and return the ciphertext and tag separately; the tuple is
/// (ciphertext, tag).
/// Complexity: O(n), n = data length.
pub fn aead_encrypt_detached(alg: Int, key: &Vec[UInt8], nonce: &Vec[UInt8], data: &Vec[UInt8], aad: &Vec[UInt8]) -> Result[(Vec[UInt8], Vec[UInt8]), Str] {
  if !(aead_alg_supported(alg)) {
    return Err("aead_encrypt_detached: unsupported algorithm");
  }
  if key.len() != aead_key_size(alg) {
    return Err("aead_encrypt_detached: invalid key length");
  }
  if nonce.len() != aead_nonce_size(alg) {
    return Err("aead_encrypt_detached: invalid nonce length");
  }
  let body = _aead_seal_alg(alg, key, nonce, data, aad);
  match body {
    Ok(b) => {
      var tag_size = aead_tag_size(alg);
      var ct = Vec[UInt8].new();
      var i = 0;
      while i < b.len() - tag_size {
        ct.push(b[i]);
        i = i + 1;
      }
      var tag = Vec[UInt8].new();
      while i < b.len() {
        tag.push(b[i]);
        i = i + 1;
      }
      return Ok((ct, tag));
    }
    Err(e) => { return Err(e); }
  }
}
