// p_wave31_shapes.xi -- contract shape validation for wave 31 (math factorial family).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 31 applies to xiom.math.factorial (22 pub fns):
// 1. invalid-input guards: negative n / negative k -> 0 (factorial,
//    double_factorial, subfactorial, multifactorial, binomial, multinomial,
//    falling/rising_factorial, the Stirling/Eulerian/Narayana/Lah DP rows,
//    bell, catalan, motzkin, schroeder, partition_count, derangements);
//    n <= 0 or k <= 0 for the Narayana/Lah families.
// 2. exact zero/one values: factorial(0) == 1, subfactorial(0) == 1,
//    subfactorial(1) == 0, binomial(n,0) == binomial(n,n) == 1,
//    multinomial/empty-ks mirror, Stirling s(n,n) == S(n,n) == 1,
//    eulerian A(n,0) == 1, A(n,n) == 0, Narayana N(n,1) == 1,
//    Lah L(n,n) == 1.
// 3. documented-overflow thresholds: factorial >= 21, double_factorial >= 34,
//    subfactorial >= 21, catalan >= 34 all return 0.
// 4. non-negativity: every numeric family result is >= 0.
// 5. enumeration length shapes: integer_partitions(-1/0/4) -> 0/1/5,
//    bell_triangle(-1/0/3) -> 0/1/4.
// main() drives the real functions with safe inputs; every call evaluates the
// new runtime clauses. Returns 0 when every shape holds.

module p_wave31_shapes

use xiom.math;

fn main() -> Int {
  // 1+2+3: factorial family
  if math.factorial.factorial(-2) != 0 { return 1; }
  if math.factorial.factorial(0) != 1 { return 2; }
  if math.factorial.factorial(1) != 1 { return 3; }
  if math.factorial.factorial(5) != 120 { return 4; }
  if math.factorial.factorial(21) != 0 { return 5; }
  if math.factorial.double_factorial(-1) != 0 { return 6; }
  if math.factorial.double_factorial(5) != 15 { return 7; }
  if math.factorial.double_factorial(34) != 0 { return 8; }
  if math.factorial.subfactorial(-1) != 0 { return 9; }
  if math.factorial.subfactorial(0) != 1 { return 10; }
  if math.factorial.subfactorial(1) != 0 { return 11; }
  if math.factorial.subfactorial(4) != 9 { return 12; }
  if math.factorial.subfactorial(21) != 0 { return 13; }
  if math.factorial.multifactorial(-1, 2) != 0 { return 14; }
  if math.factorial.multifactorial(5, 0) != 0 { return 15; }
  if math.factorial.multifactorial(0, 5) != 1 { return 16; }
  if math.factorial.multifactorial(5, 2) != 15 { return 17; }

  // binomial / multinomial
  if math.factorial.binomial(-1, 0) != 0 { return 18; }
  if math.factorial.binomial(7, -1) != 0 { return 19; }
  if math.factorial.binomial(3, 4) != 0 { return 20; }
  if math.factorial.binomial(7, 0) != 1 { return 21; }
  if math.factorial.binomial(7, 7) != 1 { return 22; }
  if math.factorial.binomial(2, 1) != 2 { return 23; }
  if math.factorial.binomial(5, 2) != 10 { return 24; }
  var of = math.factorial.binomial(4294967294, 2);
  if of < 0 { return 25; }
  if math.factorial.binomial_coeff(5, 2) != 10 { return 26; }
  var emptyk = Vec[Int].new();
  if math.factorial.multinomial(-1, &emptyk) != 0 { return 27; }
  if math.factorial.multinomial(2, &emptyk) != 0 { return 28; }
  if math.factorial.multinomial(0, &emptyk) != 1 { return 29; }
  var ks = Vec[Int].new();
  ks.push(2);
  ks.push(2);
  if math.factorial.multinomial(4, &ks) != 6 { return 30; }

  // falling / rising
  if math.factorial.falling_factorial(5, -1) != 0 { return 31; }
  if math.factorial.falling_factorial(5, 0) != 1 { return 32; }
  if math.factorial.falling_factorial(0, 3) != 0 { return 33; }
  if math.factorial.falling_factorial(5, 2) != 20 { return 34; }
  if math.factorial.rising_factorial(5, -1) != 0 { return 35; }
  if math.factorial.rising_factorial(5, 0) != 1 { return 36; }
  if math.factorial.rising_factorial(0, 3) != 0 { return 37; }
  if math.factorial.rising_factorial(5, 2) != 30 { return 38; }

  // Stirling / Bell / Catalan / Eulerian / Narayana / Lah
  if math.factorial.stirling_first(-1, 0) != 0 { return 39; }
  if math.factorial.stirling_first(0, 0) != 1 { return 40; }
  if math.factorial.stirling_first(3, 3) != 1 { return 41; }
  if math.factorial.stirling_first(3, 0) != 0 { return 42; }
  if math.factorial.stirling_second(-1, 0) != 0 { return 43; }
  if math.factorial.stirling_second(0, 0) != 1 { return 44; }
  if math.factorial.stirling_second(3, 3) != 1 { return 45; }
  if math.factorial.stirling_second(3, 0) != 0 { return 46; }
  if math.factorial.bell(-1) != 0 { return 47; }
  if math.factorial.bell(0) != 1 { return 48; }
  if math.factorial.bell(1) != 1 { return 49; }
  if math.factorial.bell(5) != 52 { return 50; }
  if math.factorial.catalan(-1) != 0 { return 51; }
  if math.factorial.catalan(0) != 1 { return 52; }
  if math.factorial.catalan(5) != 42 { return 53; }
  if math.factorial.catalan(34) != 0 { return 54; }
  if math.factorial.eulerian(-1, 0) != 0 { return 55; }
  if math.factorial.eulerian(0, 0) != 1 { return 56; }
  if math.factorial.eulerian(3, 0) != 1 { return 57; }
  if math.factorial.eulerian(3, 3) != 0 { return 58; }
  if math.factorial.narayana(0, 0) != 0 { return 59; }
  if math.factorial.narayana(3, 1) != 1 { return 60; }
  if math.factorial.lah(0, 0) != 0 { return 61; }
  if math.factorial.lah(3, 3) != 1 { return 62; }
  if math.factorial.lah(3, 1) != 6 { return 63; }

  // Motzkin / Schroeder / partition_count
  if math.factorial.motzkin(-1) != 0 { return 64; }
  if math.factorial.motzkin(0) != 1 { return 65; }
  if math.factorial.motzkin(1) != 1 { return 66; }
  if math.factorial.motzkin(6) != 51 { return 67; }
  if math.factorial.schroeder(-1) != 0 { return 68; }
  if math.factorial.schroeder(0) != 1 { return 69; }
  if math.factorial.schroeder(4) != 90 { return 70; }
  if math.factorial.partition_count(-1) != 0 { return 71; }
  if math.factorial.partition_count(0) != 1 { return 72; }
  if math.factorial.partition_count(10) != 42 { return 73; }

  // 5: enumerations
  var ip0 = math.factorial.integer_partitions(-1);
  if ip0.len() != 0 { return 74; }
  var ip1 = math.factorial.integer_partitions(0);
  if ip1.len() != 1 { return 75; }
  var ip2 = math.factorial.integer_partitions(4);
  if ip2.len() != 5 { return 76; }
  var bt0 = math.factorial.bell_triangle(-1);
  if bt0.len() != 0 { return 77; }
  var bt1 = math.factorial.bell_triangle(0);
  if bt1.len() != 1 { return 78; }
  var bt2 = math.factorial.bell_triangle(3);
  if bt2.len() != 4 { return 79; }

  // derangements alias
  if math.factorial.derangements(-1) != 0 { return 80; }
  if math.factorial.derangements(0) != 1 { return 81; }
  if math.factorial.derangements(4) != 9 { return 82; }
  if math.factorial.derangements(21) != 0 { return 83; }
  // invalid-input regression: the zero-row identity needs k == 0
  if math.factorial.stirling_first(0, 1) != 0 { return 84; }
  if math.factorial.stirling_first(0, -1) != 0 { return 85; }
  if math.factorial.stirling_second(0, 1) != 0 { return 86; }
  if math.factorial.eulerian(0, 1) != 0 { return 87; }
  if math.factorial.eulerian(0, -1) != 0 { return 88; }
  return 0;
}
