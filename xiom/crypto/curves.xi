// XIOM - Cryptography: Curves
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.crypto.curves

// Depends on: xiom.crypto, xiom.string

// ============================================================================
// Elliptic curve primitives: Curve25519, secp256k1, P-256. NOTE: current
// implementation lives in crypto.xi - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn curve25519_scalar_mult(scalar, point) -> Vec[UInt8] - scalar multiplication of a point on Curve25519. TODO(compiler): implement.
// fn curve25519_base_point() -> Vec[UInt8] - the standard base point encoding. TODO(compiler): implement.
// fn curve25519_clamp(scalar: &Vec[UInt8]) -> Vec[UInt8] - apply the X25519 clamping rules to a scalar. TODO(compiler): implement.
// fn secp256k1_generator() -> (Vec[UInt8], Vec[UInt8]) - generator point coordinates; tuple is (x, y). TODO(compiler): implement.
// fn secp256k1_point_add(a, b) -> (Vec[UInt8], Vec[UInt8]) - add two points; tuple is (x, y). TODO(compiler): implement.
// fn secp256k1_point_mul(scalar, point) -> (Vec[UInt8], Vec[UInt8]) - multiply a point by a scalar; tuple is (x, y). TODO(compiler): implement.
// fn p256_curve_order() -> Vec[UInt8] - the P-256 group order n. TODO(compiler): implement.
// fn curve_order(curve: Int) -> Vec[UInt8] - group order for a named curve. TODO(compiler): implement.
// fn curve_point_on_curve(curve, x, y) -> Bool - test whether (x, y) satisfies the curve equation. TODO(compiler): implement.
// fn curve_scalar_valid(curve, scalar) -> Bool - test whether a scalar is a valid private key. TODO(compiler): implement.
