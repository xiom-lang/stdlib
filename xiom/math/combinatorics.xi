// XIOM - Math: Combinatorics
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.combinatorics

// Depends on: xiom.math

// ============================================================================
// Counting functions and enumeration of permutations, combinations, partitions,
// and number-theoretic sequences. NOTE: current implementation lives in
// math/algebra.xi + num/bigint.xi + math/series.xi - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn permutations(n: Int, k: Int) -> Int - falling factorial n!/(n-k)!.
// fn combinations(n: Int, k: Int) -> Int - binomial coefficient C(n, k).
// fn permutations_with_repetition(n: Int, k: Int) -> Int - n^k ordered selections with replacement.
// fn combinations_with_repetition(n: Int, k: Int) -> Int - C(n+k-1, k) unordered selections with replacement.
// fn derangements(n: Int) -> Int - number of fixed-point-free permutations of n items.
// fn bell_numbers(n: Int) -> Int - Bell number B(n): partitions of an n-set.
// fn catalan_numbers(n: Int) -> Int - Catalan number C_n.
// fn eulerian_numbers(n: Int, k: Int) -> Int - permutations of n with exactly k ascents.
// fn stirling_numbers_1(n: Int, k: Int) -> Int - signed Stirling numbers of the first kind.
// fn stirling_numbers_2(n: Int, k: Int) -> Int - Stirling numbers of the second kind: partitions into k blocks.
// fn lah_numbers(n: Int, k: Int) -> Int - Lah numbers L(n, k).
// fn narayana_numbers(n: Int, k: Int) -> Int - Narayana numbers N(n, k).
// fn fibonacci(n: Int) -> Int - F(n), 0-indexed: F(0)=0, F(1)=1.
// fn fibonacci_start(a: Int, b: Int, n: Int) -> Int - Fibonacci-like sequence beginning with a and b.
// fn lucas(n: Int) -> Int - Lucas number L(n).
// fn tribonacci(n: Int) -> Int - third-order sequence T(n) = T(n-1)+T(n-2)+T(n-3).
// fn tetranacci(n: Int) -> Int - fourth-order sequence with the first four terms summed.
// fn partitions(n: Int) -> Int - number of integer partitions p(n).
// fn integer_partitions(n: Int) -> Vec[Vec[Int]] - enumerate all integer partitions of n.
// fn compositions(n: Int, k: Int) -> Int - number of compositions of n into exactly k parts.
// fn compositions_all(n: Int) -> Int - total number of compositions of n.
// fn surjections(n: Int, k: Int) -> Int - number of onto functions from an n-set to a k-set.
// fn involutions(n: Int) -> Int - number of self-inverse permutations on n elements.
// fn derangements_enum(n: Int) -> Vec[Vec[Int]] - enumerate all fixed-point-free permutations of n.
// fn permutations_enum(elems: &Vec[Int]) -> Vec[Vec[Int]] - enumerate all permutations of elems.
// fn combinations_enum(elems: &Vec[Int], k: Int) -> Vec[Vec[Int]] - enumerate all k-combinations of elems.
// fn subsets_enum(elems: &Vec[Int], k: Int) -> Vec[Vec[Int]] - enumerate all k-element subsets of elems.
// fn powerset_enum(elems: &Vec[Int]) -> Vec[Vec[Int]] - enumerate all subsets of elems.
