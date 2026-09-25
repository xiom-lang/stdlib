// p_wave32_shapes.xi -- contract shape validation for wave 32 (math combinatorics).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 32 applies to xiom.math.combinatorics (28 pub fns):
// 1. invalid-input guards: negative n/k -> 0 (permutations*,
//    combinations*, the DP aliases, sequences), n <= 0 / k <= 0 for
//    Lah/Narayana, k out of range for combinations_enum/subsets_enum.
// 2. exact 0/1/known values on delegation and recurrence families:
//    falling/binomial mirrors, Fibonacci/Lucas/Tribonacci/Tetranacci,
//    compositions, surjections, involutions, signed Stirling sign rule.
// 3. documented-overflow thresholds: derangements >= 21,
//    catalan_numbers >= 34, fibonacci >= 93, lucas >= 91,
//    compositions_all >= 64.
// 4. non-negativity where the family cannot return negative.
// 5. enumeration lengths: derangements_enum (0/1 for n=0/1, >= 1 for
//    n >= 2), permutations_enum (empty -> 1), combinations_enum/subsets_enum
//    (k bounds), powerset_enum (n > 20 -> 0, n = 0 -> 1, 2^n rows).
// main() drives the real functions with safe inputs; every call evaluates the
// new runtime clauses. Returns 0 when every shape holds.

module p_wave32_shapes

use xiom.math;

fn main() -> Int {
  // permutations / combinations mirrors
  if math.combinatorics.permutations(5, -1) != 0 { return 1; }
  if math.combinatorics.permutations(5, 0) != 1 { return 2; }
  if math.combinatorics.permutations(5, 2) != 20 { return 3; }
  if math.combinatorics.permutations(0, 3) != 0 { return 4; }
  if math.combinatorics.combinations(-1, 0) != 0 { return 5; }
  if math.combinatorics.combinations(5, 5) != 1 { return 6; }
  if math.combinatorics.combinations(5, 0) != 1 { return 7; }
  if math.combinatorics.combinations(2, 1) != 2 { return 8; }
  if math.combinatorics.combinations(5, 2) != 10 { return 9; }
  if math.combinatorics.permutations_with_repetition(-1, 0) != 0 { return 10; }
  if math.combinatorics.permutations_with_repetition(5, 0) != 1 { return 11; }
  if math.combinatorics.permutations_with_repetition(0, 3) != 0 { return 12; }
  if math.combinatorics.permutations_with_repetition(2, 3) != 8 { return 13; }
  if math.combinatorics.combinations_with_repetition(-1, 0) != 0 { return 14; }
  if math.combinatorics.combinations_with_repetition(0, 0) != 1 { return 15; }
  if math.combinatorics.combinations_with_repetition(0, 2) != 0 { return 16; }
  if math.combinatorics.combinations_with_repetition(5, 0) != 1 { return 17; }
  if math.combinatorics.combinations_with_repetition(3, 2) != 6 { return 18; }

  // delegating aliases
  if math.combinatorics.derangements(-1) != 0 { return 19; }
  if math.combinatorics.derangements(0) != 1 { return 20; }
  if math.combinatorics.derangements(4) != 9 { return 21; }
  if math.combinatorics.derangements(21) != 0 { return 22; }
  if math.combinatorics.bell_numbers(-1) != 0 { return 23; }
  if math.combinatorics.bell_numbers(0) != 1 { return 24; }
  if math.combinatorics.bell_numbers(5) != 52 { return 25; }
  if math.combinatorics.catalan_numbers(-1) != 0 { return 26; }
  if math.combinatorics.catalan_numbers(0) != 1 { return 27; }
  if math.combinatorics.catalan_numbers(5) != 42 { return 28; }
  if math.combinatorics.catalan_numbers(34) != 0 { return 29; }
  if math.combinatorics.eulerian_numbers(-1, 0) != 0 { return 30; }
  if math.combinatorics.eulerian_numbers(0, 0) != 1 { return 31; }
  if math.combinatorics.eulerian_numbers(0, 1) != 0 { return 32; }
  if math.combinatorics.eulerian_numbers(3, 0) != 1 { return 33; }
  if math.combinatorics.eulerian_numbers(3, 3) != 0 { return 34; }
  if math.combinatorics.stirling_numbers_1(-1, 0) != 0 { return 35; }
  if math.combinatorics.stirling_numbers_1(0, 0) != 1 { return 36; }
  if math.combinatorics.stirling_numbers_1(0, 1) != 0 { return 37; }
  if math.combinatorics.stirling_numbers_1(3, 1) != 2 { return 38; }
  if math.combinatorics.stirling_numbers_1(3, 2) != -3 { return 39; }
  if math.combinatorics.stirling_numbers_2(-1, 0) != 0 { return 40; }
  if math.combinatorics.stirling_numbers_2(0, 0) != 1 { return 41; }
  if math.combinatorics.stirling_numbers_2(0, 1) != 0 { return 42; }
  if math.combinatorics.stirling_numbers_2(3, 1) != 1 { return 43; }
  if math.combinatorics.stirling_numbers_2(3, 3) != 1 { return 44; }
  if math.combinatorics.lah_numbers(0, 0) != 0 { return 45; }
  if math.combinatorics.lah_numbers(3, 1) != 6 { return 46; }
  if math.combinatorics.lah_numbers(3, 3) != 1 { return 47; }
  if math.combinatorics.narayana_numbers(0, 0) != 0 { return 48; }
  if math.combinatorics.narayana_numbers(3, 1) != 1 { return 49; }
  if math.combinatorics.narayana_numbers(3, 2) != 3 { return 50; }

  // sequences
  if math.combinatorics.fibonacci(-1) != 0 { return 51; }
  if math.combinatorics.fibonacci(0) != 0 { return 52; }
  if math.combinatorics.fibonacci(1) != 1 { return 53; }
  if math.combinatorics.fibonacci(10) != 55 { return 54; }
  if math.combinatorics.fibonacci(93) != 0 { return 55; }
  if math.combinatorics.fibonacci_start(3, 4, -1) != 0 { return 56; }
  if math.combinatorics.fibonacci_start(3, 4, 0) != 3 { return 57; }
  if math.combinatorics.fibonacci_start(3, 4, 1) != 4 { return 58; }
  if math.combinatorics.fibonacci_start(3, 4, 2) != 7 { return 59; }
  if math.combinatorics.lucas(-1) != 0 { return 60; }
  if math.combinatorics.lucas(0) != 2 { return 61; }
  if math.combinatorics.lucas(1) != 1 { return 62; }
  if math.combinatorics.lucas(10) != 123 { return 63; }
  if math.combinatorics.lucas(91) != 0 { return 64; }
  if math.combinatorics.tribonacci(-1) != 0 { return 65; }
  if math.combinatorics.tribonacci(1) != 0 { return 66; }
  if math.combinatorics.tribonacci(2) != 1 { return 67; }
  if math.combinatorics.tribonacci(7) != 13 { return 68; }
  if math.combinatorics.tetranacci(-1) != 0 { return 69; }
  if math.combinatorics.tetranacci(2) != 0 { return 70; }
  if math.combinatorics.tetranacci(3) != 1 { return 71; }
  if math.combinatorics.tetranacci(7) != 8 { return 72; }
  if math.combinatorics.partitions(-1) != 0 { return 73; }
  if math.combinatorics.partitions(0) != 1 { return 74; }
  if math.combinatorics.partitions(10) != 42 { return 75; }
  var ip0 = math.combinatorics.integer_partitions(-1);
  if ip0.len() != 0 { return 76; }
  var ip1 = math.combinatorics.integer_partitions(0);
  if ip1.len() != 1 { return 77; }
  var ip2 = math.combinatorics.integer_partitions(4);
  if ip2.len() != 5 { return 78; }
  if math.combinatorics.compositions(-1, 0) != 0 { return 79; }
  if math.combinatorics.compositions(0, 0) != 1 { return 80; }
  if math.combinatorics.compositions(0, 2) != 0 { return 81; }
  if math.combinatorics.compositions(4, 5) != 0 { return 82; }
  if math.combinatorics.compositions(4, 2) != 3 { return 83; }
  if math.combinatorics.compositions(4, 4) != 1 { return 84; }
  if math.combinatorics.compositions_all(-1) != 0 { return 85; }
  if math.combinatorics.compositions_all(0) != 1 { return 86; }
  if math.combinatorics.compositions_all(3) != 4 { return 87; }
  if math.combinatorics.compositions_all(64) != 0 { return 88; }
  if math.combinatorics.surjections(-1, 0) != 0 { return 89; }
  if math.combinatorics.surjections(2, 3) != 0 { return 90; }
  if math.combinatorics.surjections(3, 1) != 1 { return 91; }
  if math.combinatorics.surjections(3, 2) != 6 { return 92; }
  if math.combinatorics.involutions(-1) != 0 { return 93; }
  if math.combinatorics.involutions(0) != 1 { return 94; }
  if math.combinatorics.involutions(5) != 26 { return 95; }

  // enumerations
  var de0 = math.combinatorics.derangements_enum(-1);
  if de0.len() != 0 { return 96; }
  var de1 = math.combinatorics.derangements_enum(0);
  if de1.len() != 1 { return 97; }
  var de2 = math.combinatorics.derangements_enum(1);
  if de2.len() != 0 { return 98; }
  var de3 = math.combinatorics.derangements_enum(3);
  if de3.len() != 2 { return 99; }
  var e0 = Vec[Int].new();
  var pe0 = math.combinatorics.permutations_enum(&e0);
  if pe0.len() != 1 { return 100; }
  var e3 = Vec[Int].new();
  e3.push(1);
  e3.push(2);
  e3.push(3);
  var pe3 = math.combinatorics.permutations_enum(&e3);
  if pe3.len() != 6 { return 101; }
  var ce3 = math.combinatorics.combinations_enum(&e3, 2);
  if ce3.len() != 3 { return 102; }
  var ce0 = math.combinatorics.combinations_enum(&e3, 0);
  if ce0.len() != 1 { return 103; }
  var ce5 = math.combinatorics.combinations_enum(&e3, 5);
  if ce5.len() != 0 { return 104; }
  var ceN = math.combinatorics.combinations_enum(&e3, -1);
  if ceN.len() != 0 { return 105; }
  var se2 = math.combinatorics.subsets_enum(&e3, 2);
  if se2.len() != 3 { return 106; }
  var ps0 = math.combinatorics.powerset_enum(&e0);
  if ps0.len() != 1 { return 107; }
  var ps3 = math.combinatorics.powerset_enum(&e3);
  if ps3.len() != 8 { return 108; }
  var big = Vec[Int].new();
  var bi = 0;
  while bi < 21 {
    big.push(bi);
    bi = bi + 1;
  }
  var psb = math.combinatorics.powerset_enum(&big);
  if psb.len() != 0 { return 109; }
  return 0;
}
