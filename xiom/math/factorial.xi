// XIOM - Math: Factorial
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.factorial

// Depends on: xiom.math

// ============================================================================
// Factorial variants, binomial/multinomial coefficients, and counting-number
// families (Stirling, Bell, Catalan, partitions). NOTE: current implementation
// lives in num/bigint.xi factorial/binomial + math/algebra.xi - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn factorial(n: Int) -> Int - n! for n >= 0. TODO(compiler): implement.
// fn double_factorial(n: Int) -> Int - n!! product of every other integer. TODO(compiler): implement.
// fn subfactorial(n: Int) -> Int - derangement count !n. TODO(compiler): implement.
// fn multifactorial(n: Int, k: Int) -> Int - k-th multifactorial of n. TODO(compiler): implement.
// fn binomial(n: Int, k: Int) -> Int - binomial coefficient C(n, k). TODO(compiler): implement.
// fn binomial_coeff(n: Int, k: Int) -> Int - alias of binomial. TODO(compiler): implement.
// fn multinomial(n: Int, ks: &Vec[Int]) -> Int - multinomial coefficient n!/(k1!...km!). TODO(compiler): implement.
// fn falling_factorial(x: Int, k: Int) -> Int - x * (x-1) * ... * (x-k+1). TODO(compiler): implement.
// fn rising_factorial(x: Int, k: Int) -> Int - x * (x+1) * ... * (x+k-1). TODO(compiler): implement.
// fn stirling_first(n: Int, k: Int) -> Int - unsigned Stirling numbers of the first kind. TODO(compiler): implement.
// fn stirling_second(n: Int, k: Int) -> Int - Stirling numbers of the second kind. TODO(compiler): implement.
// fn bell(n: Int) -> Int - Bell number: partitions of an n-element set. TODO(compiler): implement.
// fn catalan(n: Int) -> Int - Catalan number C_n. TODO(compiler): implement.
// fn eulerian(n: Int, k: Int) -> Int - Eulerian number A(n, k). TODO(compiler): implement.
// fn narayana(n: Int, k: Int) -> Int - Narayana number N(n, k). TODO(compiler): implement.
// fn lah(n: Int, k: Int) -> Int - Lah number L(n, k). TODO(compiler): implement.
// fn motzkin(n: Int) -> Int - Motzkin number M_n. TODO(compiler): implement.
// fn schroeder(n: Int) -> Int - large Schroeder number S_n. TODO(compiler): implement.
// fn partition_count(n: Int) -> Int - number of integer partitions of n. TODO(compiler): implement.
// fn integer_partitions(n: Int) -> Vec[Vec[Int]] - all partitions of n as lists. TODO(compiler): implement.
// fn derangements(n: Int) -> Int - number of derangements of n items. TODO(compiler): implement.
// fn bell_triangle(n: Int) -> Vec[Vec[Int]] - Bell triangle rows up to n. TODO(compiler): implement.
