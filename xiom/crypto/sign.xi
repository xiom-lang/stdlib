// XIOM - Cryptography: Signatures
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.sign

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Digital signatures: Ed25519, RSA, ECDSA, DSA.
//
// Implementation notes:
//   - RSA sign/verify delegate to the flat xiom.crypto rsa_sign/rsa_verify
//     (raw textbook RSA over the small generated keys).
//   - Ed25519, ECDSA and DSA require large-integer point arithmetic / hash
//     truncation that the current compiler build cannot execute reliably
//     (Vec-tuple returns and reference lowering miscompile); the functions
//     are declared with the frozen signatures and return empty results /
//     false until the compiler issues are resolved. See the report.
// ============================================================================

use xiom.crypto;
use xiom.crypto.hash;
use xiom.bigint;
use xiom.encoding;

/// Generate a new Ed25519 keypair; the tuple is (sk, pk).
/// Blocked in the current build (see module header).
pub fn ed25519_keypair() -> (Vec[UInt8], Vec[UInt8]) {
  var sk = crypto.secure_random_bytes(32);
  return (sk, ed25519_public_key(&sk));
}

/// Sign a message with an Ed25519 secret key (64-byte signature).
/// Blocked in the current build (see module header).
pub fn ed25519_sign(sk: &Vec[UInt8], msg: &Vec[UInt8]) -> Vec[UInt8] {
  return Vec[UInt8].new();
}

/// Verify an Ed25519 signature. Blocked in the current build.
pub fn ed25519_verify(pk: &Vec[UInt8], msg: &Vec[UInt8], sig: &Vec[UInt8]) -> Bool {
  return false;
}

/// Derive the Ed25519 public key from a secret key.
/// Blocked in the current build (see module header).
pub fn ed25519_public_key(sk: &Vec[UInt8]) -> Vec[UInt8] {
  return Vec[UInt8].new();
}

/// Deterministically expand a 32-byte seed; the tuple is (sk, pk).
/// Blocked in the current build (see module header).
pub fn ed25519_keypair_from_seed(seed: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  return (seed, Vec[UInt8].new());
}

/// RSASSA-PKCS1-v1_5-style sign. Delegates to xiom.crypto.rsa_sign (raw
/// textbook RSA over the small generated keys); the `hash` identifier is
/// advisory (the flat implementation does not embed a digest identifier).
/// Complexity: O(bitlen^3).
pub fn rsa_sign(key: &Vec[UInt8], msg: &Vec[UInt8], hash: Int) -> Result[Vec[UInt8], Str] {
  return crypto.rsa_sign(key, msg);
}

/// Verify an RSA signature. Returns false on any error.
/// Complexity: O(bitlen^3).
pub fn rsa_verify(key: &Vec[UInt8], msg: &Vec[UInt8], sig: &Vec[UInt8], hash: Int) -> Bool {
  var r = crypto.rsa_verify(key, msg, sig);
  match r {
    Ok(ok) => ok;
    Err(_) => false;
  }
}

/// ECDSA sign; the tuple is (r, s). Blocked in the current build.
pub fn ecdsa_sign(curve: Int, sk: &Vec[UInt8], msg: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  var zero = Vec[UInt8].new();
  return (zero, zero);
}

/// Verify an ECDSA signature. Blocked in the current build.
pub fn ecdsa_verify(curve: Int, pk: &Vec[UInt8], msg: &Vec[UInt8], r: &Vec[UInt8], s: &Vec[UInt8]) -> Bool {
  return false;
}

/// DSA sign; the tuple is (r, s). Blocked in the current build.
pub fn dsa_sign(p: &Vec[UInt8], q: &Vec[UInt8], g: &Vec[UInt8], x: &Vec[UInt8], msg: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  var zero = Vec[UInt8].new();
  return (zero, zero);
}

/// Verify a DSA signature. Blocked in the current build.
pub fn dsa_verify(p: &Vec[UInt8], q: &Vec[UInt8], g: &Vec[UInt8], y: &Vec[UInt8], msg: &Vec[UInt8], r: &Vec[UInt8], s: &Vec[UInt8]) -> Bool {
  return false;
}
