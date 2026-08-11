// XIOM - Math: Algebra
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.algebra

// Depends on: none

// ============================================================================
// Number-theoretic and combinatorial integer algebra. TODO(compiler): implement.
// ============================================================================

// fn gcd(a: Int, b: Int) -> Int - greatest common divisor of a and b.
// fn lcm(a: Int, b: Int) -> Int - least common multiple of a and b.
// fn egcd(a: Int, b: Int) -> (Int, Int, Int) - extended Euclid; tuple is (g, x, y) with a*x + b*y = g = gcd(a, b).
// fn mod_inverse(a: Int, m: Int) -> Option[Int] - multiplicative inverse of a mod m; None when gcd(a, m) != 1.
// fn crt(remainders: &Vec[Int], moduli: &Vec[Int]) -> Option[Int] - Chinese remainder theorem solution; None when moduli are not pairwise coprime.
// fn legendre_symbol(a: Int, p: Int) -> Int - Legendre symbol (a/p): 1 if a is a quadratic residue, -1 otherwise, 0 if divisible.
// fn jacobi_symbol(a: Int, n: Int) -> Int - Jacobi symbol (a/n) for odd positive n; generalizes the Legendre symbol.
// fn binomial(n: Int, k: Int) -> Int - binomial coefficient C(n, k); 0 for invalid input or overflow.
// fn factorial(n: Int) -> Int - n! for n >= 0; 0 on overflow or negative input.
// fn primorial(n: Int) -> Int - product of the first n primes.
// fn nth_prime(n: Int) -> Int - the n-th prime, 1-indexed (nth_prime(1) == 2).
// fn integer_sqrt(n: Int) -> Int - floor(sqrt(n)) for n >= 0.
// fn next_power_of_two(n: Int) -> Int - smallest power of two greater than or equal to n.
// fn is_power_of_two(n: Int) -> Bool - true iff n is a positive power of two.
// fn is_perfect_square(n: Int) -> Bool - true iff n is a perfect square.
