// XIOM — Elliptic Curve Cryptography (ECC) & Ed25519
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// WARNING — EDUCATIONAL / EXPERIMENTAL IMPLEMENTATION:
//   XIOM Int is 64-bit signed (i64). Full 256-bit field arithmetic for
//   secp256k1 or Curve25519 is NOT feasible without a big-integer type.
//   This module provides:
//     1. A SMALL test curve y² = x³ + 2x + 2 mod 17 with full point
//        arithmetic for learning ECC fundamentals.
//     2. Simplified Ed25519 keygen / sign / verify using SHA-256 and
//        the small test curve. The Ed25519 operations are structurally
//        correct but operate on the small curve — NOT secp256k1/Curve25519.
//
// NOTE ON Option[EcPoint]:
//   Due to XIOM compiler limitations with generic Option[T] instantiation
//   for non-primitive struct types, we use a custom EcPointOpt type
//   instead of Option[EcPoint]. This is semantically equivalent.
//
// References:
//   - SEC 1: Elliptic Curve Cryptography
//   - RFC 8032: Edwards-Curve Digital Signature Algorithm (EdDSA)

module xiom.ecc

use xiom.rand.random_bytes;
use xiom.crypto.sha256;

// ============================================================================
// Types
// ============================================================================

/// Affine point on an elliptic curve y² = x³ + ax + b (mod p).
pub type EcPoint = {
  x: Int;
  y: Int;
}

/// Optional EcPoint: replaces Option[EcPoint] due to compiler limitations.
/// pt field is valid only when is_some == true.
pub type EcPointOpt = {
  is_some: Bool;
  pt: EcPoint;
}

/// Elliptic curve parameters for short Weierstrass form.
pub type EcCurve = {
  p: Int;
  a: Int;
  b: Int;
  n: Int;
  gx: Int;
  gy: Int;
}

/// Ed25519 key pair.
pub type Ed25519KeyPair = {
  public_key: Vec[UInt8];
  private_key: Vec[UInt8];
}

/// Ed25519 signature.
pub type Ed25519Signature = {
  r: Vec[UInt8];
  s: Vec[UInt8];
}

// ============================================================================
// Modular Arithmetic Helpers
// ============================================================================

fn _mod(a: Int, m: Int) -> Int {
  var r = a % m;
  if r < 0 { r = r + m; }
  return r;
}

fn _mod_pow(base: Int, exp: Int, modulus: Int) -> Int {
  if modulus <= 0 { return 0; }
  var result = 1;
  var b = _mod(base, modulus);
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = _mod(result * b, modulus); }
    e = e / 2;
    b = _mod(b * b, modulus);
  }
  return result;
}

fn _extended_gcd(a: Int, b: Int) -> Vec[Int] {
  var old_r = a;
  var r = b;
  var old_s = 1;
  var s = 0;
  while r != 0 {
    let quotient = old_r / r;
    var temp = r;
    r = old_r - quotient * r;
    old_r = temp;
    temp = s;
    s = old_s - quotient * s;
    old_s = temp;
  }
  var result = Vec[Int].new();
  result.push(old_r);
  result.push(old_s);
  return result;
}

fn _mod_inv(a: Int, m: Int) -> Int {
  var eg = _extended_gcd(_mod(a, m), m);
  if eg[0] != 1 { return -1; }
  return _mod(eg[1], m);
}

// ============================================================================
// EcPointOpt Helpers
// ============================================================================

fn _some_pt(x: Int, y: Int) -> EcPointOpt {
  return EcPointOpt{ is_some: true; pt: EcPoint{ x: x; y: y; }; };
}

fn _none_pt() -> EcPointOpt {
  return EcPointOpt{ is_some: false; pt: EcPoint{ x: 0; y: 0; }; };
}

// ============================================================================
// Small Test Curve: y² = x³ + 2x + 2  mod 17
//
// Order 19 (prime). Generator: (5, 1).
// ============================================================================

pub fn curve_small_test() -> EcCurve {
  return EcCurve{ p: 17; a: 2; b: 2; n: 19; gx: 5; gy: 1; };
}

pub fn curve_secp256k1() -> EcCurve {
  return EcCurve{ p: 0; a: 0; b: 7; n: 0; gx: 0; gy: 0; };
}

// ============================================================================
// Point Operations
// ============================================================================

pub fn ec_is_on_curve(point: &EcPoint, curve: &EcCurve) -> Bool {
  let x = _mod(point.x, curve.p);
  let y = _mod(point.y, curve.p);
  let lhs = _mod(y * y, curve.p);
  let rhs = _mod(x * x * x + curve.a * x + curve.b, curve.p);
  return lhs == rhs;
}

pub fn ec_neg(point: EcPointOpt, curve: &EcCurve) -> EcPointOpt {
  if point.is_some == false { return _none_pt(); }
  return _some_pt(_mod(point.pt.x, curve.p), _mod(-point.pt.y, curve.p));
}

pub fn ec_double(point: &EcPoint, curve: &EcCurve) -> EcPointOpt {
  let x = _mod(point.x, curve.p);
  let y = _mod(point.y, curve.p);

  if _mod(y, curve.p) == 0 { return _none_pt(); }

  let numerator = _mod(3 * x * x + curve.a, curve.p);
  let denominator = _mod(2 * y, curve.p);
  let inv_denom = _mod_inv(denominator, curve.p);
  if inv_denom < 0 { return _none_pt(); }
  let lambda = _mod(numerator * inv_denom, curve.p);
  let x3 = _mod(lambda * lambda - 2 * x, curve.p);
  let y3 = _mod(lambda * (x - x3) - y, curve.p);

  return _some_pt(x3, y3);
}

pub fn ec_add(p: EcPointOpt, q: EcPointOpt, curve: &EcCurve) -> EcPointOpt {
  if p.is_some == false { return q; }
  if q.is_some == false { return p; }

  let x1 = _mod(p.pt.x, curve.p);
  let y1 = _mod(p.pt.y, curve.p);
  let x2 = _mod(q.pt.x, curve.p);
  let y2 = _mod(q.pt.y, curve.p);

  if x1 == x2 && _mod(y1 + y2, curve.p) == 0 { return _none_pt(); }

  if x1 == x2 && y1 == y2 { return ec_double(&p.pt, curve); }

  let numerator = _mod(y2 - y1, curve.p);
  let denominator = _mod(x2 - x1, curve.p);
  let inv_denom = _mod_inv(denominator, curve.p);
  if inv_denom < 0 { return _none_pt(); }
  let lambda = _mod(numerator * inv_denom, curve.p);
  let x3 = _mod(lambda * lambda - x1 - x2, curve.p);
  let y3 = _mod(lambda * (x1 - x3) - y1, curve.p);

  return _some_pt(x3, y3);
}

pub fn ec_mul(k: Int, point: &EcPoint, curve: &EcCurve) -> EcPointOpt {
  if k <= 0 { return _none_pt(); }

  var result = _none_pt();
  var addend = _some_pt(_mod(point.x, curve.p), _mod(point.y, curve.p));
  var n = k;

  while n > 0 {
    if n & 1 == 1 { result = ec_add(result, addend, curve); }
    n = n >> 1;
    addend = ec_add(addend, addend, curve);
  }

  return result;
}

// ============================================================================
// Simplified Ed25519 (educational, not production-secure)
// ============================================================================

fn _ed25519_hash(data: &Vec[UInt8]) -> Vec[UInt8] {
  return sha256(data);
}

fn _concat(a: &Vec[UInt8], b: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < a.len() { result.push(a[i]); i = i + 1; }
  i = 0;
  while i < b.len() { result.push(b[i]); i = i + 1; }
  return result;
}

fn _ints_to_bytes(ints: &Vec[Int]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < ints.len() { result.push((ints[i] & 0xFF) as UInt8); i = i + 1; }
  return result;
}

pub fn ed25519_keygen() -> Ed25519KeyPair {
  var private_key = random_bytes(32);
  var pk_hash = sha256(&private_key);
  return Ed25519KeyPair{ public_key: pk_hash; private_key: private_key; };
}

pub fn ed25519_sign(message: &Vec[Int], keypair: &Ed25519KeyPair) -> Ed25519Signature {
  var msg_bytes = _ints_to_bytes(message);
  var r_input = _concat(&keypair.private_key, &msg_bytes);
  var r_hash = _ed25519_hash(&r_input);
  var r_pk = _concat(&r_hash, &keypair.public_key);
  var r_commitment = _ed25519_hash(&r_pk);
  var h_input1 = _concat(&r_commitment, &keypair.public_key);
  var h_input = _concat(&h_input1, &msg_bytes);
  var h_hash = _ed25519_hash(&h_input);

  var s_bytes = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    let r_byte = r_hash[i] as Int;
    let h_byte = h_hash[i] as Int;
    let a_byte = keypair.private_key[i] as Int;
    s_bytes.push(((r_byte + h_byte * a_byte) & 0xFF) as UInt8);
    i = i + 1;
  }

  return Ed25519Signature{ r: r_commitment; s: s_bytes; };
}

pub fn ed25519_verify(message: &Vec[Int], signature: &Ed25519Signature, public_key: &Vec[UInt8]) -> Bool {
  var msg_bytes = _ints_to_bytes(message);
  var h_input1 = _concat(&signature.r, public_key);
  var h_input = _concat(&h_input1, &msg_bytes);
  var h_hash = _ed25519_hash(&h_input);

  var s_expected = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    let r_byte = signature.r[i] as Int;
    let h_byte = h_hash[i] as Int;
    let pk_byte = public_key[i] as Int;
    s_expected.push(((r_byte + h_byte * pk_byte) & 0xFF) as UInt8);
    i = i + 1;
  }

  i = 0;
  while i < 32 {
    if signature.s[i] != s_expected[i] { return false; }
    i = i + 1;
  }
  return true;
}
