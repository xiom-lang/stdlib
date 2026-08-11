// XIOM - Math: Number Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.number_theory

// Depends on: xiom.math

// ============================================================================
// Primality, factorization, totient/symbol functions, and divisor arithmetic.
// NOTE: current implementation lives in num/bigint.xi is_prime/next_prime +
// math/algebra.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn is_prime(n: Int) -> Bool - deterministic primality test for 64-bit n. TODO(compiler): implement.
// fn is_prime_deterministic(n: Int) -> Bool - strict deterministic primality test. TODO(compiler): implement.
// fn next_prime(n: Int) -> Int - smallest prime strictly greater than n. TODO(compiler): implement.
// fn prev_prime(n: Int) -> Int - largest prime strictly less than n. TODO(compiler): implement.
// fn factor(n: Int) -> Vec[Int] - prime factorization of n. TODO(compiler): implement.
// fn pollard_rho(n: Int) -> Int - non-trivial factor of n via Pollard's rho. TODO(compiler): implement.
// fn p_1_factor(n: Int) -> Int - non-trivial factor of n via Pollard p-1. TODO(compiler): implement.
// fn is_pseudoprime(n: Int, base: Int) -> Bool - true if n passes a base pseudoprime test. TODO(compiler): implement.
// fn miller_rabin(n: Int, bases: &Vec[Int]) -> Bool - Miller-Rabin strong pseudoprime test. TODO(compiler): implement.
// fn fermat_test(n: Int, a: Int) -> Bool - Fermat compositeness test with base a. TODO(compiler): implement.
// fn lucas_lehmer(p: Int) -> Bool - Lucas-Lehmer test for Mersenne number 2^p - 1. TODO(compiler): implement.
// fn mersenne_prime_p(p: Int) -> Bool - true if 2^p - 1 is prime. TODO(compiler): implement.
// fn euler_phi(n: Int) -> Int - Euler totient: count of integers coprime to n. TODO(compiler): implement.
// fn mobius(n: Int) -> Int - Mobius function: -1, 0, or 1. TODO(compiler): implement.
// fn jordan_totient(n: Int, k: Int) -> Int - Jordan totient function J_k(n). TODO(compiler): implement.
// fn carmichael(n: Int) -> Int - Carmichael lambda function. TODO(compiler): implement.
// fn prime_pi(n: Int) -> Int - count of primes <= n. TODO(compiler): implement.
// fn nth_prime(n: Int) -> Int - the n-th prime. TODO(compiler): implement.
// fn primorial(n: Int) -> Int - product of the first n primes. TODO(compiler): implement.
// fn is_composite(n: Int) -> Bool - true if n is composite. TODO(compiler): implement.
// fn is_semiprime(n: Int) -> Bool - true if n is a product of two primes. TODO(compiler): implement.
// fn is_power(n: Int) -> Bool - true if n is a perfect power a^k, k >= 2. TODO(compiler): implement.
// fn is_power_of(n: Int, base: Int) -> Bool - true if n is a power of base. TODO(compiler): implement.
// fn radical(n: Int) -> Int - product of the distinct prime factors of n. TODO(compiler): implement.
// fn smooth(n: Int, bound: Int) -> Bool - true if all prime factors of n are <= bound. TODO(compiler): implement.
// fn rough(n: Int, bound: Int) -> Bool - true if all prime factors of n are > bound. TODO(compiler): implement.
// fn legendre_symbol(a: Int, p: Int) -> Int - Legendre symbol (a/p) for odd prime p. TODO(compiler): implement.
// fn jacobi_symbol(a: Int, n: Int) -> Int - Jacobi symbol (a/n) for odd n. TODO(compiler): implement.
// fn kronecker_symbol(a: Int, n: Int) -> Int - Kronecker symbol (a/n). TODO(compiler): implement.
// fn divisor_sum(n: Int, k: Int) -> Int - sum of the k-th powers of divisors of n. TODO(compiler): implement.
// fn divisor_count(n: Int) -> Int - number of positive divisors of n. TODO(compiler): implement.
// fn proper_divisors(n: Int) -> Vec[Int] - divisors of n excluding n itself. TODO(compiler): implement.
