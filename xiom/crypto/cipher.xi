// XIOM - Cryptography: Cipher
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.cipher

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Symmetric ciphers: AES modes, ChaCha20, 3DES, DES. NOTE: current
// implementation lives in crypto.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn aes_encrypt_ecb(key: &Vec[UInt8], data: &Vec[UInt8]) -> Result[Vec[UInt8], Str] - AES-ECB encrypt with PKCS#7 padding. TODO(compiler): implement.
// fn aes_decrypt_ecb(key, data) -> Result[Vec[UInt8], Str] - AES-ECB decrypt with padding removal. TODO(compiler): implement.
// fn aes_encrypt_cbc(key, iv, data) -> Result[Vec[UInt8], Str] - AES-CBC encrypt. TODO(compiler): implement.
// fn aes_decrypt_cbc(key, iv, data) -> Result[Vec[UInt8], Str] - AES-CBC decrypt. TODO(compiler): implement.
// fn aes_encrypt_ctr(key, iv, data) -> Vec[UInt8] - AES-CTR encrypt (stream, no padding). TODO(compiler): implement.
// fn aes_decrypt_ctr(key, iv, data) -> Vec[UInt8] - AES-CTR decrypt (same as encrypt). TODO(compiler): implement.
// fn aes_encrypt_gcm(key, iv, data, aad) -> Vec[UInt8] - AES-GCM encrypt with an authentication tag. TODO(compiler): implement.
// fn aes_decrypt_gcm(key, iv, data, aad, tag) -> Result[Vec[UInt8], Str] - AES-GCM decrypt and verify the tag. TODO(compiler): implement.
// fn aes_encrypt_cfb(key, iv, data) -> Vec[UInt8] - AES-CFB128 encrypt. TODO(compiler): implement.
// fn aes_encrypt_ofb(key, iv, data) -> Vec[UInt8] - AES-OFB encrypt. TODO(compiler): implement.
// fn aes_generate_key() -> Vec[UInt8] - generate a random 256-bit AES key. TODO(compiler): implement.
// fn aes_key_from_passphrase(passphrase, salt, iterations) -> Vec[UInt8] - derive an AES key from a passphrase. TODO(compiler): implement.
// fn chacha20_encrypt(key, nonce, counter, data) -> Vec[UInt8] - ChaCha20 stream encrypt. TODO(compiler): implement.
// fn chacha20_decrypt(key, nonce, counter, data) -> Vec[UInt8] - ChaCha20 stream decrypt. TODO(compiler): implement.
// fn chacha20poly1305_encrypt(key, nonce, data, aad) -> Vec[UInt8] - ChaCha20-Poly1305 AEAD encrypt. TODO(compiler): implement.
// fn chacha20poly1305_decrypt(key, nonce, data, aad, tag) -> Result[Vec[UInt8], Str] - ChaCha20-Poly1305 decrypt and verify. TODO(compiler): implement.
// fn des_encrypt(key, data) -> Result[Vec[UInt8], Str] - legacy single DES encrypt. TODO(compiler): implement.
// fn des_decrypt(key, data) -> Result[Vec[UInt8], Str] - legacy single DES decrypt. TODO(compiler): implement.
// fn triple_des_encrypt(key, data) -> Result[Vec[UInt8], Str] - 3DES encrypt. TODO(compiler): implement.
// fn triple_des_decrypt(key, data) -> Result[Vec[UInt8], Str] - 3DES decrypt. TODO(compiler): implement.
