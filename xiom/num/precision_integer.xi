// XIOM - Num: Precision Integer
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.num.precision_integer

// Depends on: none

// ============================================================================
// Arbitrary-precision integer operations as thin wrappers over the BigInt
// implementation. The reference implementation lives in num/bigint.xi (module
// xiom.bigint); these thin wrappers present the frozen
// xiom.num.precision_integer API (by-value operands, Option on fallible
// paths). All fallible inputs are validated before dispatch.
// ============================================================================

use xiom.bigint;

/// Constructs a BigInt from a native integer. Complexity: O(1).
pub fn bigint_from_int(v: Int) -> BigInt {
  return xiom.bigint.bigint_from_int(v);
}

/// Parses a decimal string (optional leading '-'/'+'). None on invalid input
/// (empty string or non-digit character). Complexity: O(n^2) accumulation.
pub fn bigint_from_str(s: Str) -> Option[BigInt] {
  var r = xiom.bigint.bigint_from_str(s);
  match r {
    Ok(v) => { return Some(v); }
    Err(_) => { return None; }
  }
}

/// Decimal string representation. Complexity: O(n).
pub fn bigint_to_str(b: BigInt) -> Str {
  return xiom.bigint.bigint_to_str(&b);
}

/// Lowercase hexadecimal string representation ("ff", "-1a"). Complexity: O(n).
pub fn bigint_to_hex(b: BigInt) -> Str {
  return xiom.bigint.bigint_to_hex(&b);
}

/// Binary string representation ("0"/"1" digits). Complexity: O(n).
pub fn bigint_to_bin(b: BigInt) -> Str {
  return xiom.bigint.bigint_to_base(&b, 2);
}

/// Octal string representation. Complexity: O(n).
pub fn bigint_to_oct(b: BigInt) -> Str {
  return xiom.bigint.bigint_to_base(&b, 8);
}

/// Sum a + b. Complexity: O(n).
pub fn bigint_add(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_add(&a, &b);
}

/// Difference a - b. Complexity: O(n).
pub fn bigint_sub(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_sub(&a, &b);
}

/// Product a * b. Complexity: O(n^2) schoolbook, Karatsuba above 36k digits.
pub fn bigint_mul(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_mul(&a, &b);
}

/// Quotient a / b (truncating). None when b is zero.
/// Complexity: O(n^2) Knuth Algorithm D.
pub fn bigint_div(a: BigInt, b: BigInt) -> Option[BigInt] {
  if xiom.bigint.bigint_is_zero(&b) { return None; }
  return Some(xiom.bigint.bigint_div(&a, &b));
}

/// Remainder a mod b (sign of the dividend). None when b is zero.
/// Complexity: O(n^2).
pub fn bigint_mod(a: BigInt, b: BigInt) -> Option[BigInt] {
  if xiom.bigint.bigint_is_zero(&b) { return None; }
  return Some(xiom.bigint.bigint_mod(&a, &b));
}

/// base raised to a non-negative integer power exp (square-and-multiply).
/// exp < 0 returns zero (documented). Complexity: O(log exp) multiplications.
pub fn bigint_pow(base: BigInt, exp: Int) -> BigInt
  requires: exp >= 0
{
  return xiom.bigint.bigint_pow(&base, exp);
}

/// Negation. Complexity: O(n).
pub fn bigint_neg(a: BigInt) -> BigInt {
  return xiom.bigint.bigint_neg(&a);
}

/// Absolute value. Complexity: O(n).
pub fn bigint_abs(a: BigInt) -> BigInt {
  return xiom.bigint.bigint_abs(&a);
}

/// Three-way comparison: -1, 0, or 1 ordering a vs b. Complexity: O(n).
pub fn bigint_compare(a: BigInt, b: BigInt) -> Int {
  return xiom.bigint.bigint_compare(&a, &b);
}

/// Whether a equals b. Complexity: O(n).
pub fn bigint_eq(a: BigInt, b: BigInt) -> Bool {
  return xiom.bigint.bigint_eq(&a, &b);
}

/// Whether a is strictly less than b. Complexity: O(n).
pub fn bigint_lt(a: BigInt, b: BigInt) -> Bool {
  return xiom.bigint.bigint_lt(&a, &b);
}

/// Whether a is strictly greater than b. Complexity: O(n).
pub fn bigint_gt(a: BigInt, b: BigInt) -> Bool {
  return xiom.bigint.bigint_gt(&a, &b);
}

/// Bitwise AND (two's-complement semantics). Complexity: O(n).
pub fn bigint_bit_and(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_bit_and(&a, &b);
}

/// Bitwise OR (two's-complement semantics). Complexity: O(n).
pub fn bigint_bit_or(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_bit_or(&a, &b);
}

/// Bitwise XOR (two's-complement semantics). Complexity: O(n).
pub fn bigint_bit_xor(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_bit_xor(&a, &b);
}

/// Left shift by n bits (multiply by 2^n; n < 0 treated as 0). This is a true
/// BIT shift (distinct from xiom.bigint's decimal shift_left). Complexity:
/// O(n^2) via the multiplications.
pub fn bigint_shift_left(a: BigInt, n: Int) -> BigInt
  requires: n >= 0
{
  if n <= 0 { return a; }
  var two = xiom.bigint.bigint_from_int(2);
  var factor = xiom.bigint.bigint_pow(&two, n);
  return xiom.bigint.bigint_mul(&a, &factor);
}

/// Arithmetic (floor) right shift by n bits: b >> n rounds toward -inf for
/// negative b. n < 0 treated as 0. Complexity: O(n^2) via the divisions.
pub fn bigint_shift_right(a: BigInt, n: Int) -> BigInt
  requires: n >= 0
{
  if n <= 0 { return a; }
  return xiom.bigint.bigint_shift_right(&a, n);
}

/// Probabilistic primality test (Miller-Rabin, deterministic for n < 3.3e24).
/// Complexity: O(k log^3 n) bigint operations.
pub fn bigint_is_prime(b: BigInt) -> Bool {
  return xiom.bigint.bigint_is_prime(&b);
}

/// Greatest common divisor (non-negative). Complexity: O(log n) divisions.
pub fn bigint_gcd(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_gcd(&a, &b);
}

/// Least common multiple; lcm(0, x) == 0. Complexity: O(gcd + mul).
pub fn bigint_lcm(a: BigInt, b: BigInt) -> BigInt {
  return xiom.bigint.bigint_lcm(&a, &b);
}

/// Modular inverse of a mod m via extended Euclid. None when gcd(a, m) != 1
/// or when m is zero. The result lies in [0, |m|). Complexity: O(log m)
/// divisions.
pub fn bigint_mod_inverse(a: BigInt, m: BigInt) -> Option[BigInt] {
  if xiom.bigint.bigint_is_zero(&m) { return None; }
  var eg = xiom.bigint.bigint_ext_gcd(&a, &m);
  if !xiom.bigint.bigint_is_one(&eg.0) { return None; }
  return Some(xiom.bigint.bigint_mod(&eg.1, &m));
}

/// (base^exp) mod m via square-and-multiply. Requires m != 0 and exp >= 0;
/// a zero modulus returns zero (documented). Complexity: O(log exp) muls.
pub fn bigint_mod_pow(base: BigInt, exp: BigInt, m: BigInt) -> BigInt
  requires: !xiom.bigint.bigint_is_zero(&m)
  requires: !xiom.bigint.bigint_is_negative(&exp)
{
  return xiom.bigint.bigint_pow_mod(&base, &exp, &m);
}

/// n! as an arbitrary-precision integer. n < 0 returns zero (documented).
/// Complexity: O(n) bigint multiplications.
pub fn bigint_factorial(n: Int) -> BigInt
  requires: n >= 0
{
  return xiom.bigint.bigint_factorial(n);
}

/// Binomial coefficient C(n, k). Invalid k (outside [0, n]) returns zero.
/// Complexity: O(k) bigint multiplications/divisions.
pub fn bigint_binomial(n: Int, k: Int) -> BigInt
  requires: n >= 0
  requires: k >= 0
  requires: k <= n
{
  return xiom.bigint.bigint_binomial(n, k);
}
