// XIOM - Cryptography: Hash
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.hash

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Cryptographic hash functions and HMAC/PBKDF2/HKDF helpers. NOTE: current
// implementation lives in crypto.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn crypto_hash_sha256(data: &Vec[UInt8]) -> Vec[UInt8] - SHA-256 digest (32 bytes). TODO(compiler): implement.
// fn crypto_hash_sha512(data) -> Vec[UInt8] - SHA-512 digest (64 bytes). TODO(compiler): implement.
// fn crypto_hash_sha1(data) -> Vec[UInt8] - SHA-1 digest (20 bytes). TODO(compiler): implement.
// fn crypto_hash_md5(data) -> Vec[UInt8] - MD5 digest (16 bytes). TODO(compiler): implement.
// fn crypto_hash_blake2b(data) -> Vec[UInt8] - BLAKE2b digest (64 bytes). TODO(compiler): implement.
// fn crypto_hash_sha256_hex(data) -> Str - SHA-256 digest as lowercase hex. TODO(compiler): implement.
// fn crypto_hash_sha512_hex(data) -> Str - SHA-512 digest as lowercase hex. TODO(compiler): implement.
// fn crypto_hash_hmac_sha256(key: &Vec[UInt8], data) -> Vec[UInt8] - keyed SHA-256 MAC. TODO(compiler): implement.
// fn crypto_hash_hmac_sha512(key, data) -> Vec[UInt8] - keyed SHA-512 MAC. TODO(compiler): implement.
// fn crypto_hash_hmac_md5(key, data) -> Vec[UInt8] - keyed MD5 MAC. TODO(compiler): implement.
// fn crypto_hash_pbkdf2_sha256(password, salt, iterations, len) -> Vec[UInt8] - derive key bytes from a password. TODO(compiler): implement.
// fn crypto_hash_hkdf(ikm, salt, info, len) -> Vec[UInt8] - HKDF key derivation from input key material. TODO(compiler): implement.
