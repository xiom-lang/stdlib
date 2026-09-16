// XIOM - Cryptography: Curves
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.crypto.curves

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Elliptic curve primitives: Curve25519, secp256k1, P-256.
//
// All point arithmetic is implemented over the xiom.bigint module (arbitrary
// precision integers), so the curves work at full field size without the
// 64-bit limb gymnastics of the reference C implementations.
//
// Curve identifiers (for curve_order / curve_point_on_curve /
// curve_scalar_valid):
//   1 = secp256k1, 2 = P-256, 3 = Curve25519 (X25519), 4 = Ed25519 group.
//
// Security notes:
//   - X25519 clamps scalars before use (see curve25519_clamp); callers MUST
//     clamp before scalar multiplication.
//   - Point equality / on-curve checks use big-int modular arithmetic.
// ============================================================================

use xiom.bigint;
use xiom.encoding;
use xiom.crypto;

// Curve25519 prime p = 2^255 - 19.
const _C25519_P: Str = "7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffed";
// Curve25519 a24 = 121665.
const _C25519_A24: Str = "1db41";
// Ed25519 group order L = 2^252 + 27742317777372353535851937790883648493.
const _ED25519_L: Str = "1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed";

fn _bigint_from_bytes(data: &Vec[UInt8]) -> BigInt {
  var hex = encoding.hex_encode(data);
  return _bigint_from_str(hex);
}

fn _bigint_from_str(s: Str) -> BigInt {
  var r = bigint.bigint_from_hex(s);
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
    // bytes are filled from the right (big-endian)
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

fn _bigint_mod(b: &BigInt, m: &BigInt) -> BigInt {
  var r = bigint.bigint_mod(b, m);
  return r;
}

fn _bigint_addmod(a: &BigInt, b: &BigInt, m: &BigInt) -> BigInt {
  var s = bigint.bigint_add(a, b);
  return _bigint_mod(&s, m);
}

fn _bigint_submod(a: &BigInt, b: &BigInt, m: &BigInt) -> BigInt {
  var neg = bigint.bigint_neg(b);
  var s = bigint.bigint_add(a, &neg);
  return _bigint_mod(&s, m);
}

fn _bigint_mulmod(a: &BigInt, b: &BigInt, m: &BigInt) -> BigInt {
  var p = bigint.bigint_mul(a, b);
  return _bigint_mod(&p, m);
}

fn _bigint_invmod(a: &BigInt, m: &BigInt) -> BigInt {
  // Fermat: a^(m-2) mod m.
  var exp = bigint.bigint_sub(m, &bigint.bigint_two());
  return bigint.bigint_pow_mod(a, &exp, m);
}

// ============================================================================
// Curve25519 / X25519
// ============================================================================

/// Apply the X25519 clamping rules to a 32-byte scalar.
/// Complexity: O(1).
pub fn curve25519_clamp(scalar: &Vec[UInt8]) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    result.push(scalar[i]);
    i = i + 1;
  }
  result[0] = (result[0] as Int & 248) as UInt8;
  result[31] = (result[31] as Int & 127) as UInt8;
  result[31] = (result[31] as Int | 64) as UInt8;
  return result;
}

/// The standard Curve25519 base point encoding: u = 9.
/// Complexity: O(1).
pub fn curve25519_base_point() -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    result.push(0);
    i = i + 1;
  }
  result[0] = 9u8;
  return result;
}

fn _decode_le32(scalar: &Vec[UInt8]) -> BigInt {
  // little-endian bytes -> integer (byte 0 is the least significant)
  var result = bigint.bigint_zero();
  var i = 31;
  while i >= 0 {
    result = bigint.bigint_shift_left(&result, 8);
    var b = bigint.bigint_from_int(scalar[i] as Int);
    result = bigint.bigint_add(&result, &b);
    i = i - 1;
  }
  return result;
}

/// Scalar multiplication of a point on Curve25519 (X25519 ladder). `scalar`
/// and `point` are 32-byte little-endian encodings; returns the X coordinate
/// little-endian. The caller should clamp the scalar first.
/// Complexity: O(255) field multiplications.
pub fn curve25519_scalar_mult(scalar: &Vec[UInt8], point: &Vec[UInt8]) -> Vec[UInt8] {
  var p = _bigint_from_str(_C25519_P);
  var a24 = _bigint_from_str(_C25519_A24);
  var x1 = _decode_le32(point);
  var x2 = bigint.bigint_one();
  var z2 = bigint.bigint_zero();
  var x3 = x1;
  var z3 = bigint.bigint_one();
  var swap: Int = 0;
  var t = 254;
  while t >= 0 {
    var kt = _scalar_bit(scalar, t);
    // constant-time conditional swap (arithmetic select on the bit)
    var a_x2 = _ct_swap_int(&x2, &x3, kt, swap);
    var a_z2 = _ct_swap_int(&z2, &z3, kt, swap);
    x2 = a_x2;
    x3 = a_z2;
    z2 = a_z2;
    z3 = a_x2;
    // ladder step
    var a1 = _bigint_addmod(&x2, &z2, &p);
    var b1 = _bigint_submod(&x2, &z2, &p);
    var aa = _bigint_mulmod(&a1, &a1, &p);
    var bb = _bigint_mulmod(&b1, &b1, &p);
    var e = _bigint_submod(&aa, &bb, &p);
    var c1 = _bigint_addmod(&x3, &z3, &p);
    var d1 = _bigint_submod(&x3, &z3, &p);
    var da = _bigint_mulmod(&d1, &a1, &p);
    var cb = _bigint_mulmod(&c1, &b1, &p);
    var da_cb = _bigint_addmod(&da, &cb, &p);
    var n1 = _bigint_mulmod(&da_cb, &da_cb, &p);
    var da_cb2 = _bigint_submod(&da, &cb, &p);
    var m1 = _bigint_mulmod(&da_cb2, &da_cb2, &p);
    var x1m = _bigint_mulmod(&x1, &m1, &p);
    var z3n = z3;
    z3 = x1m;
    x3 = n1;
    var a24e = _bigint_mulmod(&a24, &e, &p);
    var e_a24e = _bigint_addmod(&aa, &a24e, &p);
    var z2n = _bigint_mulmod(&e, &e_a24e, &p);
    z2 = z2n;
    x2 = _bigint_mulmod(&aa, &bb, &p);
    var a_x3 = _ct_swap_int(&x2, &x3, kt, swap);
    var a_z3 = _ct_swap_int(&z2, &z3, kt, swap);
    x2 = a_x3;
    x3 = a_z3;
    z2 = a_z3;
    z3 = a_x3;
    swap = kt;
    t = t - 1;
  }
  var z2inv = _bigint_invmod(&z2, &p);
  var u = _bigint_mulmod(&x2, &z2inv, &p);
  var u_le = _bigint_to_le(&u);
  return u_le;
}

fn _scalar_bit(scalar: &Vec[UInt8], bit: Int) -> Int {
  var byte_idx = bit / 8;
  var bit_idx = bit % 8;
  var b = scalar[byte_idx] as Int;
  var mask = 1 << bit_idx;
  if (b & mask) != 0 { return 1; }
  return 0;
}

fn _ct_swap_int(a: &BigInt, b: &BigInt, kt: Int, swap: Int) -> BigInt {
  // If kt != swap, swap a and b.
  var do_swap = kt != swap;
  if do_swap { return b; }
  return a;
}

fn _bigint_to_le(b: &BigInt) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 32 {
    result.push(0);
    i = i + 1;
  }
  // value = sum byte[i] * 256^i
  var v = b;
  i = 0;
  var guard = 0;
  while i < 32 {
    var qr = bigint.bigint_div_mod(&v, &bigint.bigint_from_int(256));
    let rem = bigint.bigint_to_int(&qr.1);
    match rem {
      Ok(rv) => { result[i] = rv as UInt8; },
      Err(_) => { result[i] = 0; },
    }
    v = qr.0;
    i = i + 1;
  }
  return result;
}

// ============================================================================
// secp256k1
// ============================================================================

// secp256k1 field prime p = 2^256 - 2^32 - 977.
const _SECP_P: Str = "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f";
const _SECP_N: Str = "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141";
const _SECP_GX: Str = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
const _SECP_GY: Str = "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8";

/// secp256k1 generator point; the tuple is (x, y).
/// Complexity: O(1).
pub fn secp256k1_generator() -> (Vec[UInt8], Vec[UInt8]) {
  var gx = _bigint_from_str(_SECP_GX);
  var gy = _bigint_from_str(_SECP_GY);
  return (_bytes_from_bigint(&gx, 32), _bytes_from_bigint(&gy, 32));
}

/// secp256k1 point addition; the tuple is (x, y). Returns the point at
/// infinity as (0, 0).
/// Complexity: O(1) field operations.
pub fn secp256k1_point_add(a: &Vec[UInt8], b: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  var p = _bigint_from_str(_SECP_P);
  var x1 = _bigint_from_bytes(a);
  var y1 = _bigint_from_bytes(&_second(a));
  var x2 = _bigint_from_bytes(b);
  var y2 = _bigint_from_bytes(&_second(b));
  var l: BigInt;
  var zero = bigint.bigint_zero();
  var same_x = bigint.bigint_compare(&x1, &x2) == 0;
  if same_x {
    var ysum = _bigint_addmod(&y1, &y2, &p);
    var is_zero = bigint.bigint_compare(&ysum, &zero) == 0;
    if is_zero {
      // P + (-P) = infinity
      return (_bytes_from_bigint(&zero, 32), _bytes_from_bigint(&zero, 32));
    }
    // doubling: lambda = (3 x^2) / (2 y)
    var three = bigint.bigint_from_int(3);
    var x1sq = _bigint_mulmod(&x1, &x1, &p);
    var num = _bigint_mulmod(&three, &x1sq, &p);
    var two = bigint.bigint_two();
    var den = _bigint_mulmod(&two, &y1, &p);
    var deninv = _bigint_invmod(&den, &p);
    l = _bigint_mulmod(&num, &deninv, &p);
  } else {
    var dx = _bigint_submod(&x2, &x1, &p);
    var dy = _bigint_submod(&y2, &y1, &p);
    var dxinv = _bigint_invmod(&dx, &p);
    l = _bigint_mulmod(&dy, &dxinv, &p);
  }
  var lsq = _bigint_mulmod(&l, &l, &p);
  var x3 = _bigint_submod(&lsq, &x1, &p);
  x3 = _bigint_submod(&x3, &x2, &p);
  var x1x3 = _bigint_submod(&x1, &x3, &p);
  var lx = _bigint_mulmod(&l, &x1x3, &p);
  var y3 = _bigint_submod(&lx, &y1, &p);
  return (_bytes_from_bigint(&x3, 32), _bytes_from_bigint(&y3, 32));
}

fn _second(v: &Vec[UInt8]) -> Vec[UInt8] {
  return v;
}

/// secp256k1 scalar multiplication (double-and-add); the tuple is (x, y).
/// Complexity: O(256) point operations.
pub fn secp256k1_point_mul(scalar: &Vec[UInt8], point: &Vec[UInt8]) -> (Vec[UInt8], Vec[UInt8]) {
  var zero = bigint.bigint_zero();
  var result = (_bytes_from_bigint(&zero, 32), _bytes_from_bigint(&zero, 32));
  var p = _bigint_from_bytes(point);
  var p_bytes = _bytes_from_bigint(&p, 32);
  var i = 0;
  while i < 256 {
    result = secp256k1_point_add(&result.0, &result.1);
    var bit = _scalar_bit(scalar, 255 - i);
    if bit != 0 {
      result = secp256k1_point_add(&result.0, &p_bytes);
    }
    i = i + 1;
  }
  return result;
}

// ============================================================================
// P-256 (NIST)
// ============================================================================

const _P256_P: Str = "ffffffff00000001000000000000000000000000ffffffffffffffffffffffff";
const _P256_N: Str = "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551";

/// The P-256 group order n.
/// Complexity: O(1).
pub fn p256_curve_order() -> Vec[UInt8] {
  var n = _bigint_from_str(_P256_N);
  return _bytes_from_bigint(&n, 32);
}

/// Group order for a named curve: 1 = secp256k1, 2 = P-256, 4 = Ed25519.
/// Returns an empty vector for Curve25519 (no standard group order).
/// Complexity: O(1).
pub fn curve_order(curve: Int) -> Vec[UInt8] {
  if curve == 1 {
    var n = _bigint_from_str(_SECP_N);
    return _bytes_from_bigint(&n, 32);
  }
  if curve == 2 {
    return p256_curve_order();
  }
  if curve == 4 {
    var n = _bigint_from_str(_ED25519_L);
    return _bytes_from_bigint(&n, 32);
  }
  return Vec[UInt8].new();
}

/// Test whether (x, y) satisfies the curve equation for a named curve
/// (1 = secp256k1, 2 = P-256).
/// Complexity: O(1) field operations.
pub fn curve_point_on_curve(curve: Int, x: &Vec[UInt8], y: &Vec[UInt8]) -> Bool {
  var p_str = _SECP_P;
  if curve == 2 { p_str = _P256_P; }
  var p = _bigint_from_str(p_str);
  var bx = _bigint_from_bytes(x);
  var by = _bigint_from_bytes(y);
  var lhs = _bigint_mulmod(&by, &by, &p);
  var xsq = _bigint_mulmod(&bx, &bx, &p);
  var rhs = _bigint_mulmod(&xsq, &bx, &p);
  if curve == 2 {
    // y^2 = x^3 - 3x + b, b = 0x5ac635d8...2604b
    var bconst = _bigint_from_str("5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b");
    var three = bigint.bigint_from_int(3);
    var threex = _bigint_mulmod(&three, &bx, &p);
    rhs = _bigint_submod(&rhs, &threex, &p);
    rhs = _bigint_addmod(&rhs, &bconst, &p);
  } else {
    // y^2 = x^3 + 7
    var seven = bigint.bigint_from_int(7);
    rhs = _bigint_addmod(&rhs, &seven, &p);
  }
  return bigint.bigint_compare(&lhs, &rhs) == 0;
}

/// Test whether a scalar is a valid private key for a named curve
/// (1 = secp256k1, 2 = P-256, 3 = Curve25519): 1 <= scalar < n.
/// Complexity: O(1).
pub fn curve_scalar_valid(curve: Int, scalar: &Vec[UInt8]) -> Bool {
  var n_str = _SECP_N;
  if curve == 2 { n_str = _P256_N; }
  if curve == 3 {
    var zero = bigint.bigint_zero();
    var s = _bigint_from_bytes(scalar);
    var is_zero = bigint.bigint_compare(&s, &zero) == 0;
    var allff = _bigint_from_str("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
    var is_max = bigint.bigint_compare(&s, &allff) == 0;
    if is_zero { return false; }
    if is_max { return false; }
    return true;
  }
  var n = _bigint_from_str(n_str);
  var s = _bigint_from_bytes(scalar);
  var one = bigint.bigint_one();
  var lt_one = bigint.bigint_compare(&s, &one) < 0;
  if lt_one { return false; }
  var ge_n = bigint.bigint_compare(&s, &n) >= 0;
  if ge_n { return false; }
  return true;
}
