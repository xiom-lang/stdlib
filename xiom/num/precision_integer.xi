// XIOM - Num: Precision Integer
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.precision_integer

// Depends on: none

// ============================================================================
// Arbitrary-precision integer operations as thin wrappers over the BigInt
// implementation. NOTE: current implementation lives in num/bigint.xi REAL -
// move the thin wrappers here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn bigint_from_int(v: Int) -> BigInt - construct from a native integer.
// fn bigint_from_str(s: Str) -> Option[BigInt] - parse decimal string; None on invalid input.
// fn bigint_to_str(b: BigInt) -> Str - decimal string representation.
// fn bigint_to_hex(b: BigInt) -> Str - hexadecimal string representation.
// fn bigint_to_bin(b: BigInt) -> Str - binary string representation.
// fn bigint_to_oct(b: BigInt) -> Str - octal string representation.
// fn bigint_add(a: BigInt, b: BigInt) -> BigInt - sum.
// fn bigint_sub(a: BigInt, b: BigInt) -> BigInt - difference.
// fn bigint_mul(a: BigInt, b: BigInt) -> BigInt - product.
// fn bigint_div(a: BigInt, b: BigInt) -> Option[BigInt] - quotient; None when b is zero.
// fn bigint_mod(a: BigInt, b: BigInt) -> Option[BigInt] - remainder; None when b is zero.
// fn bigint_pow(base: BigInt, exp: Int) -> BigInt - base raised to a non-negative integer power.
// fn bigint_neg(a: BigInt) -> BigInt - negation.
// fn bigint_abs(a: BigInt) -> BigInt - absolute value.
// fn bigint_compare(a: BigInt, b: BigInt) -> Int - -1, 0, or 1 ordering a vs b.
// fn bigint_eq(a: BigInt, b: BigInt) -> Bool - whether a equals b.
// fn bigint_lt(a: BigInt, b: BigInt) -> Bool - whether a is less than b.
// fn bigint_gt(a: BigInt, b: BigInt) -> Bool - whether a is greater than b.
// fn bigint_bit_and(a: BigInt, b: BigInt) -> BigInt - bitwise AND.
// fn bigint_bit_or(a: BigInt, b: BigInt) -> BigInt - bitwise OR.
// fn bigint_bit_xor(a: BigInt, b: BigInt) -> BigInt - bitwise XOR.
// fn bigint_shift_left(a: BigInt, n: Int) -> BigInt - left shift by n bits.
// fn bigint_shift_right(a: BigInt, n: Int) -> BigInt - right shift by n bits.
// fn bigint_is_prime(b: BigInt) -> Bool - probabilistic primality test.
// fn bigint_gcd(a: BigInt, b: BigInt) -> BigInt - greatest common divisor.
// fn bigint_lcm(a: BigInt, b: BigInt) -> BigInt - least common multiple.
// fn bigint_mod_inverse(a: BigInt, m: BigInt) -> Option[BigInt] - modular inverse; None when gcd(a, m) != 1.
// fn bigint_mod_pow(base: BigInt, exp: BigInt, m: BigInt) -> BigInt - modular exponentiation.
// fn bigint_factorial(n: Int) -> BigInt - n! as an arbitrary-precision integer.
// fn bigint_binomial(n: Int, k: Int) -> BigInt - binomial coefficient C(n, k) as an arbitrary-precision integer.
