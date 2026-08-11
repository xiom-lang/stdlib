// XIOM - Cryptography: AEAD
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.aead

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Authenticated encryption with associated data, algorithm-generic. NOTE:
// current implementation lives in crypto.xi - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn aead_encrypt(alg: Int, key, nonce, data, aad) -> Result[Vec[UInt8], Str] - encrypt and append the tag to the ciphertext. TODO(compiler): implement.
// fn aead_decrypt(alg, key, nonce, data, aad, tag) -> Result[Vec[UInt8], Str] - verify the tag and decrypt. TODO(compiler): implement.
// fn aead_seal(alg, key, data, aad) -> Result[Vec[UInt8], Str] - encrypt with a generated nonce prepended. TODO(compiler): implement.
// fn aead_open(alg, key, sealed, aad) -> Result[Vec[UInt8], Str] - decrypt a sealed message. TODO(compiler): implement.
// fn aead_nonce_size(alg) -> Int - nonce length in bytes for an algorithm. TODO(compiler): implement.
// fn aead_tag_size(alg) -> Int - tag length in bytes for an algorithm. TODO(compiler): implement.
// fn aead_key_size(alg) -> Int - key length in bytes for an algorithm. TODO(compiler): implement.
// fn aead_alg_supported(alg) -> Bool - whether an algorithm identifier is implemented. TODO(compiler): implement.
// fn aead_generate_nonce(alg) -> Vec[UInt8] - generate a random nonce of the right size. TODO(compiler): implement.
// fn aead_encrypt_detached(alg, key, nonce, data, aad) -> Result[(Vec[UInt8], Vec[UInt8]), Str] - return ciphertext and tag separately; tuple is (ciphertext, tag). TODO(compiler): implement.
