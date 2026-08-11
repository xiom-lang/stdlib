// XIOM - Cryptography: Signatures
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.sign

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Digital signatures: Ed25519, RSA, ECDSA, DSA. NOTE: current implementation
// lives in crypto.xi - move the functions here during the implementation
// phase. TODO(compiler): implement.
// ============================================================================

// fn ed25519_keypair() -> (Vec[UInt8], Vec[UInt8]) - generate a new keypair; tuple is (sk, pk). TODO(compiler): implement.
// fn ed25519_sign(sk, msg) -> Vec[UInt8] - sign a message with a secret key. TODO(compiler): implement.
// fn ed25519_verify(pk, msg, sig) -> Bool - verify an Ed25519 signature. TODO(compiler): implement.
// fn ed25519_public_key(sk) -> Vec[UInt8] - derive the public key from a secret key. TODO(compiler): implement.
// fn ed25519_keypair_from_seed(seed) -> (Vec[UInt8], Vec[UInt8]) - deterministically expand a seed; tuple is (sk, pk). TODO(compiler): implement.
// fn rsa_sign(key, msg, hash: Int) -> Result[Vec[UInt8], Str] - RSASSA-PKCS1-v1_5 sign. TODO(compiler): implement.
// fn rsa_verify(key, msg, sig, hash) -> Bool - verify an RSA signature. TODO(compiler): implement.
// fn ecdsa_sign(curve, sk, msg) -> (Vec[UInt8], Vec[UInt8]) - sign; tuple is (r, s). TODO(compiler): implement.
// fn ecdsa_verify(curve, pk, msg, r, s) -> Bool - verify an ECDSA signature. TODO(compiler): implement.
// fn dsa_sign(p, q, g, x, msg) -> (Vec[UInt8], Vec[UInt8]) - DSA sign; tuple is (r, s). TODO(compiler): implement.
// fn dsa_verify(p, q, g, y, msg, r, s) -> Bool - verify a DSA signature. TODO(compiler): implement.
