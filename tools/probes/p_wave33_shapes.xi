// p_wave33_shapes.xi -- contract shape validation for wave 33 (math number theory).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 33 applies to xiom.math.number_theory (21 safe pub
// fns; the p*p-wrap and deferred families stay clause-free):
// 1. primality guards: is_prime/is_prime_deterministic false for n < 2,
//    true for 2, false for even n > 2.
// 2. enumeration guards: factor(<=1) empty, factor(>1) non-empty,
//    prev_prime(<=2) == 0, prev_prime(nonzero) < n, nth_prime(1) == 2,
//    primorial(1) == 2 and the n >= 16 overflow threshold.
// 3. pseudoprime/strong-test guards incl. the empty-base miller_rabin
//    mirror and the base-multiple false case.
// 4. Lucas-Lehmer: p < 2 / p > 62 false, p == 2 / p == 5 true.
// 5. integer-property guards: is_composite(<=1 or 2) false,
//    is_semiprime(< 4) false, is_power(<= 1) false, is_power_of special
//    bases 0/1/-1.
// 6. symbol ranges: legendre/jacobi/kronecker in [-1, 1] with the p <= 1
//    and even-n zero guards, kronecker n == 0/1 mirrors.
// 7. divisor guards: divisor_sum(n <= 0 / n == 1 / n > 1 && k < 0),
//    non-negativity, divisor_count mirrors, proper_divisors lengths.
// main() drives the real functions with safe inputs; every call evaluates the
// new runtime clauses. Returns 0 when every shape holds.

module p_wave33_shapes

use xiom.math;

fn main() -> Int {
  // primality
  if math.number_theory.is_prime(1) { return 1; }
  if !math.number_theory.is_prime(2) { return 2; }
  if math.number_theory.is_prime(9) { return 3; }
  if !math.number_theory.is_prime(97) { return 4; }
  if math.number_theory.is_prime_deterministic(1) { return 5; }
  if !math.number_theory.is_prime_deterministic(2) { return 6; }
  if math.number_theory.is_prime_deterministic(100) { return 7; }
  if !math.number_theory.is_prime_deterministic(97) { return 8; }

  // prev_prime / factor
  if math.number_theory.prev_prime(1) != 0 { return 9; }
  if math.number_theory.prev_prime(2) != 0 { return 10; }
  if math.number_theory.prev_prime(3) != 2 { return 11; }
  if math.number_theory.prev_prime(10) != 7 { return 12; }
  var f0 = math.number_theory.factor(0);
  if f0.len() != 0 { return 13; }
  var f1 = math.number_theory.factor(12);
  if f1.len() != 3 { return 14; }
  var f2 = math.number_theory.factor(97);
  if f2.len() != 1 { return 15; }

  // pseudoprimes / strong test
  if math.number_theory.is_pseudoprime(1, 5) { return 16; }
  if !math.number_theory.is_pseudoprime(2, 3) { return 17; }
  if !math.number_theory.is_pseudoprime(7, 3) { return 18; }
  if math.number_theory.is_pseudoprime(7, 7) { return 19; }
  if math.number_theory.fermat_test(1, 5) { return 20; }
  if !math.number_theory.fermat_test(7, 3) { return 21; }
  if math.number_theory.fermat_test(7, 7) { return 22; }
  var mb = Vec[Int].new();
  mb.push(2);
  if math.number_theory.miller_rabin(1, &mb) { return 23; }
  if !math.number_theory.miller_rabin(2, &mb) { return 24; }
  if math.number_theory.miller_rabin(9, &mb) { return 25; }
  if !math.number_theory.miller_rabin(97, &mb) { return 26; }
  var mbe = Vec[Int].new();
  if !math.number_theory.miller_rabin(9, &mbe) { return 27; }

  // Lucas-Lehmer
  if math.number_theory.lucas_lehmer(1) { return 28; }
  if !math.number_theory.lucas_lehmer(2) { return 29; }
  if !math.number_theory.lucas_lehmer(5) { return 30; }
  if math.number_theory.lucas_lehmer(63) { return 31; }
  if !math.number_theory.mersenne_prime_p(5) { return 32; }
  if math.number_theory.mersenne_prime_p(63) { return 33; }

  // nth_prime / primorial
  if math.number_theory.nth_prime(0) != 0 { return 34; }
  if math.number_theory.nth_prime(1) != 2 { return 35; }
  if math.number_theory.nth_prime(5) != 11 { return 36; }
  if math.number_theory.nth_prime(10) != 29 { return 37; }
  if math.number_theory.primorial(0) != 0 { return 38; }
  if math.number_theory.primorial(1) != 2 { return 39; }
  if math.number_theory.primorial(3) != 30 { return 40; }
  if math.number_theory.primorial(5) != 2310 { return 41; }
  if math.number_theory.primorial(16) != 0 { return 42; }

  // integer properties
  if math.number_theory.is_composite(1) { return 43; }
  if math.number_theory.is_composite(2) { return 44; }
  if !math.number_theory.is_composite(4) { return 45; }
  if math.number_theory.is_composite(97) { return 46; }
  if math.number_theory.is_semiprime(1) { return 47; }
  if math.number_theory.is_semiprime(3) { return 48; }
  if !math.number_theory.is_semiprime(4) { return 49; }
  if !math.number_theory.is_semiprime(6) { return 50; }
  if math.number_theory.is_semiprime(12) { return 51; }
  if math.number_theory.is_power(0) { return 52; }
  if math.number_theory.is_power(1) { return 53; }
  if !math.number_theory.is_power(8) { return 54; }
  if !math.number_theory.is_power(9) { return 55; }
  if math.number_theory.is_power(12) { return 56; }
  if !math.number_theory.is_power_of(0, 0) { return 57; }
  if math.number_theory.is_power_of(5, 0) { return 58; }
  if !math.number_theory.is_power_of(1, 1) { return 59; }
  if math.number_theory.is_power_of(5, 1) { return 60; }
  if !math.number_theory.is_power_of(8, 2) { return 61; }
  if !math.number_theory.is_power_of(9, 3) { return 62; }
  if math.number_theory.is_power_of(10, 2) { return 63; }
  if !math.number_theory.is_power_of(-1, -1) { return 64; }
  if math.number_theory.is_power_of(2, -1) { return 65; }

  // symbols
  if math.number_theory.legendre_symbol(2, 1) != 0 { return 66; }
  if math.number_theory.legendre_symbol(2, 7) != 1 { return 67; }
  if math.number_theory.legendre_symbol(3, 7) != -1 { return 68; }
  if math.number_theory.legendre_symbol(7, 7) != 0 { return 69; }
  if math.number_theory.jacobi_symbol(1, -3) != 0 { return 70; }
  if math.number_theory.jacobi_symbol(2, 4) != 0 { return 71; }
  if math.number_theory.jacobi_symbol(2, 7) != 1 { return 72; }
  if math.number_theory.jacobi_symbol(3, 7) != -1 { return 73; }
  if math.number_theory.kronecker_symbol(2, 0) != 0 { return 74; }
  if math.number_theory.kronecker_symbol(1, 0) != 1 { return 75; }
  if math.number_theory.kronecker_symbol(5, 1) != 1 { return 76; }
  if math.number_theory.kronecker_symbol(1, 7) != 1 { return 77; }

  // divisors
  if math.number_theory.divisor_sum(0, 2) != 0 { return 78; }
  if math.number_theory.divisor_sum(1, 5) != 1 { return 79; }
  if math.number_theory.divisor_sum(6, -1) != 0 { return 80; }
  if math.number_theory.divisor_sum(6, 0) != 4 { return 81; }
  if math.number_theory.divisor_sum(6, 1) != 12 { return 82; }
  if math.number_theory.divisor_sum(6, 2) != 50 { return 83; }
  if math.number_theory.divisor_count(0) != 0 { return 84; }
  if math.number_theory.divisor_count(1) != 1 { return 85; }
  if math.number_theory.divisor_count(6) != 4 { return 86; }
  var pd0 = math.number_theory.proper_divisors(0);
  if pd0.len() != 0 { return 87; }
  var pd1 = math.number_theory.proper_divisors(1);
  if pd1.len() != 0 { return 88; }
  var pd6 = math.number_theory.proper_divisors(6);
  if pd6.len() != 3 { return 89; }
  return 0;
}
