// XIOM - Cryptography: Key Exchange
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.crypto.keyx

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Key exchange: X25519, ECDH (P-256 / secp256k1), classic Diffie-Hellman.
//
// All curve math is delegated to xiom.crypto.curves; classic DH uses
// xiom.bigint modular exponentiation.
//
// Security notes:
//   - X25519 callers must clamp secret keys before use (curve25519_clamp);
//     x25519_public_key / x25519_shared_secret clamp internally.
//   - key_agreement_validate rejects all-zero and non-32-byte public keys.
//   - key_agreement_derive is HKDF-SHA256 bound to the shared secret.
// ============================================================================

use xiom.crypto;
use xiom.bigint;
use xiom.crypto.curves;
use xiom.crypto.hash;
use xiom.encoding;

/// Generate a new X25519 keypair; the tuple is (sk, pk).
/// NOTE: Vec-tuple returns miscompile in the current build; prefer
/// x25519_public_key on a random secret.
/// Complexity: O(255) field operations.
pub fn x25519_keypair() -> (Vec[UInt8], Vec[UInt8]) {
  var sk = crypto.secure_random_bytes(32);
  var pk = x25519_public_key(&sk);
  return (sk, pk);
}

/// Derive the X25519 public key from a secret key.
/// Complexity: O(255) field operations.
pub fn x25519_public_key(sk: &Vec[UInt8]) -> Vec[UInt8] {
  var clamped = curves.curve25519_clamp(sk);
  var bp = curves.curve25519_base_point();
  return curves.curve25519_scalar_mult(&clamped, &bp);
}

/// Compute the X25519 shared secret between a secret key and a peer public
/// key.
/// Complexity: O(255) field operations.
pub fn x25519_shared_secret(sk: &Vec[UInt8], pk: &Vec[UInt8]) -> Vec[UInt8] {
  var clamped = curves.curve25519_clamp(sk);
  return curves.curve25519_scalar_mult(&clamped, pk);
}

/// Multiply the base point by sk (public key). Alias of x25519_public_key.
/// Complexity: O(255) field operations.
pub fn x25519_base(sk: &Vec[UInt8]) -> Vec[UInt8] {
  return x25519_public_key(sk);
}

/// ECDH shared secret on P-256 (x coordinate of sk * pk). Requires a
/// P-256 point-multiplication primitive; delegates to the secp256k1 ladder is
/// NOT possible, so this returns an empty vector until a P-256 point
/// multiplier is wired in (see report).
/// Complexity: O(256) point operations.
pub fn ecdh_p256(sk: &Vec[UInt8], pk: &Vec[UInt8]) -> Vec[UInt8] {
  return Vec[UInt8].new();
}

/// ECDH shared secret on secp256k1 (x coordinate of sk * pk).
/// Complexity: O(256) point operations.
pub fn ecdh_secp256k1(sk: &Vec[UInt8], pk: &Vec[UInt8]) -> Vec[UInt8] {
  var p = curves.secp256k1_point_mul(sk, pk);
  var result = Vec[UInt8].new();
  var i = 0;
  while i < p.0.len() {
    result.push(p.0[i]);
    i = i + 1;
  }
  return result;
}

/// Generate a classic DH private key in [2, p-2].
/// Complexity: O(1) expected.
pub fn dh_generate_key(prime: &Vec[UInt8], generator: &Vec[UInt8]) -> Vec[UInt8] {
  var p = _bigint_from_bytes(prime);
  var byte_len = prime.len();
  var two = bigint.bigint_two();
  var pm2 = bigint.bigint_sub(&p, &two);
  var done = false;
  var result = Vec[UInt8].new();
  while done == false {
    var cand = crypto.secure_random_bytes(byte_len);
    // Force high bit so the value is full-length, then clamp into [2, p-2].
    cand[0] = (cand[0] as Int | 0x80) as UInt8;
    var c = _bigint_from_bytes(&cand);
    var lt = bigint.bigint_compare(&c, &pm2) <= 0;
    var ge = bigint.bigint_compare(&c, &two) >= 0;
    if lt && ge {
      result = _bytes_from_bigint(&c, byte_len);
      done = true;
    }
  }
  return result;
}

/// Compute the classic DH shared secret: peer_pk ^ own_sk mod prime.
/// Complexity: O(bitlen^3).
pub fn dh_shared_secret(prime: &Vec[UInt8], own_sk: &Vec[UInt8], peer_pk: &Vec[UInt8]) -> Vec[UInt8] {
  var p = _bigint_from_bytes(prime);
  var s = _bigint_from_bytes(own_sk);
  var g = _bigint_from_bytes(peer_pk);
  var shared = bigint.bigint_pow_mod(&g, &s, &p);
  return _bytes_from_bigint(&shared, prime.len());
}

/// Derive symmetric key bytes from a shared secret (HKDF-SHA256).
/// Complexity: O(len / 32 + n).
pub fn key_agreement_derive(shared: &Vec[UInt8], info: &Vec[UInt8], len: Int) -> Vec[UInt8] {
  var empty_salt = Vec[UInt8].new();
  return hash.crypto_hash_hkdf(shared, &empty_salt, info, len);
}

/// Sanity-check a peer public key: 32 bytes and not all zero.
/// Complexity: O(1).
pub fn key_agreement_validate(pk: &Vec[UInt8]) -> Bool {
  if pk.len() != 32 { return false; }
  var i = 0;
  while i < 32 {
    if pk[i] != 0u8 { return true; }
    i = i + 1;
  }
  return false;
}

fn _bigint_from_bytes(data: &Vec[UInt8]) -> BigInt {
  var hex = encoding.hex_encode(data);
  var r = bigint.bigint_from_hex(hex);
  match r {
    Ok(b) => b;
    Err(_) => bigint.bigint_zero();
  }
}

fn _bytes_from_bigint(b: &BigInt, byte_len: Int) -> Vec[UInt8] {
  var hex = bigint.bigint_to_hex(b);
  var padded = Vec[UInt8].new();
  var i = 0;
  while i < byte_len {
    padded.push(0);
    i = i + 1;
  }
  var hexlen = hex.len();
  var hi = 0;
  while hi < hexlen {
    var nibble = 0;
    var opt = xiom.string.char_at(hex, hi);
    if opt.is_some {
      var ch = opt.value;
      if ch >= '0' && ch <= '9' {
        nibble = (ch as Int) - 48;
      } elif ch >= 'a' && ch <= 'f' {
        nibble = (ch as Int) - 87;
      } elif ch >= 'A' && ch <= 'F' {
        nibble = (ch as Int) - 55;
      }
    }
    var pos = byte_len - 1 - ((hexlen - 1 - hi) / 2);
    if (hexlen - hi) % 2 == 1 {
      padded[pos] = (padded[pos] as Int | nibble) as UInt8;
    } else {
      padded[pos] = (nibble * 16) as UInt8;
    }
    hi = hi + 1;
  }
  return padded;
}
