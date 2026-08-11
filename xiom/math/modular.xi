// XIOM - Math: Modular
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.modular

// Depends on: xiom.math

// ============================================================================
// Modular arithmetic, CRT, and root extraction modulo a prime. NOTE: current
// implementation lives in num/bigint.xi pow_mod/mod_inverse + math/algebra.xi
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn mod_add(a: Int, b: Int, m: Int) -> Int - (a + b) mod m. TODO(compiler): implement.
// fn mod_sub(a: Int, b: Int, m: Int) -> Int - (a - b) mod m. TODO(compiler): implement.
// fn mod_mul(a: Int, b: Int, m: Int) -> Int - (a * b) mod m. TODO(compiler): implement.
// fn mod_pow(base: Int, exp: Int, m: Int) -> Int - base^exp mod m. TODO(compiler): implement.
// fn mod_inverse(a: Int, m: Int) -> Int - multiplicative inverse of a mod m. TODO(compiler): implement.
// fn mod_sqrt(a: Int, p: Int) -> Int - square root of a mod prime p. TODO(compiler): implement.
// fn mod_cbrt(a: Int, m: Int) -> Int - cube root of a mod m. TODO(compiler): implement.
// fn mod_div(a: Int, b: Int, m: Int) -> Int - (a / b) mod m. TODO(compiler): implement.
// fn mod_lcm(a: Int, b: Int, m: Int) -> Int - least common multiple mod m. TODO(compiler): implement.
// fn crt(remainders: &Vec[Int], moduli: &Vec[Int]) -> Int - Chinese remainder theorem solution. TODO(compiler): implement.
// fn crt_solve(congruences: &Vec[(Int, Int)]) -> Int - solve a system of congruences. TODO(compiler): implement.
// fn linear_congruence(a: Int, b: Int, m: Int) -> Int - solve a*x = b (mod m). TODO(compiler): implement.
// fn quadratic_residue(a: Int, p: Int) -> Bool - true if a is a quadratic residue mod p. TODO(compiler): implement.
// fn tonelli_shanks(n: Int, p: Int) -> Int - square root of n mod p (odd prime). TODO(compiler): implement.
// fn cipolla(n: Int, p: Int) -> Int - square root of n mod p via Cipolla. TODO(compiler): implement.
// fn cornacchia(a: Int, b: Int, m: Int) -> (Int, Int) - Cornacchia's algorithm for x^2 + d*y^2 = m. TODO(compiler): implement.
// fn hilbert_symbol(a: Int, b: Int, p: Int) -> Int - local Hilbert symbol (a, b)_p. TODO(compiler): implement.
// fn pow_mod_fast(base: Int, exp: Int, m: Int) -> Int - fast modular exponentiation. TODO(compiler): implement.
