// XIOM — Cryptography
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto

// === Hashing ===
pub fn sha256(data: &Vec[UInt8]) -> Vec[UInt8];
pub fn sha512(data: &Vec[UInt8]) -> Vec[UInt8];
pub fn sha256_hex(data: &Vec[UInt8]) -> Str;
pub fn md5(data: &Vec[UInt8]) -> Vec[UInt8];
pub fn blake3(data: &Vec[UInt8]) -> Vec[UInt8];
pub fn hmac_sha256(key: &Vec[UInt8], data: &Vec[UInt8]) -> Vec[UInt8];

// === Symmetric Encryption (AES) ===
pub fn aes_encrypt(key: &Vec[UInt8], plaintext: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
pub fn aes_decrypt(key: &Vec[UInt8], ciphertext: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
pub fn aes_encrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], plaintext: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<(Vec[UInt8], Vec[UInt8]), Str>;
pub fn aes_decrypt_gcm(key: &Vec[UInt8], nonce: &Vec[UInt8], ciphertext: &Vec[UInt8], tag: &Vec[UInt8], aad: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;

// === Asymmetric (RSA) ===
pub type KeyPair = { public: Vec[UInt8]; private: Vec[UInt8]; }
pub fn generate_rsa_keypair(bits: Int) -> Result<KeyPair, Str>;
pub fn rsa_encrypt(public_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
pub fn rsa_decrypt(private_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
pub fn rsa_sign(private_key: &Vec[UInt8], data: &Vec[UInt8]) -> Result<Vec[UInt8], Str>;
pub fn rsa_verify(public_key: &Vec[UInt8], data: &Vec[UInt8], signature: &Vec[UInt8]) -> Result<Bool, Str>;

// === Key derivation ===
pub fn pbkdf2(password: &Str, salt: &Vec[UInt8], iterations: Int, key_len: Int) -> Vec[UInt8];
pub fn argon2(password: &Str, salt: &Vec[UInt8], memory: Int, iterations: Int, parallelism: Int) -> Vec[UInt8];

// === Random crypto ===
pub fn secure_random_bytes(count: Int) -> Vec[UInt8];
pub fn constant_time_compare(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool;
