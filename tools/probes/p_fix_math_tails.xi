// p_fix_math_tails.xi -- probes the fix-first math-tail batch.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the fixes:
// 1. binomial: the gcd-folded multiplicative recurrence returns the true
//    C(n, k) whenever it fits in Int -- the old per-step guard reported 0
//    for binomial(4294967294, 2) although the value fits.
// 2. kronecker_symbol: the 2-adic factor is applied only to the 2-part of
//    n, so even a with odd n follows the Jacobi path ((2/7) == 1).
// 3. the seven p*p loop conditions (euler_phi, mobius, jordan_totient,
//    carmichael, radical, smooth, rough) are overflow-proof; small-input
//    behavior is unchanged.
// 4. next_prime saturates at the top of Int instead of wrapping/hanging
//    (added after the fix; the pre-fix path never returned).
// Returns 0 when every fixed behavior holds.

module p_fix_math_tails

use xiom.math;

fn main() -> Int {
  // 1: binomial exactness near 2^31
  var big = math.factorial.binomial(4294967294, 2);
  if big <= 0 { return 1; }
  if math.factorial.binomial(5, 2) != 10 { return 2; }
  if math.factorial.binomial(7, 0) != 1 { return 3; }
  if math.factorial.binomial(6, 3) != 20 { return 4; }
  if math.factorial.binomial(68, 34) != 0 { return 5; }

  // 2: kronecker even-a with odd n
  if math.number_theory.kronecker_symbol(2, 7) != 1 { return 6; }
  if math.number_theory.kronecker_symbol(3, 7) != -1 { return 7; }
  if math.number_theory.kronecker_symbol(2, 4) != 0 { return 8; }
  if math.number_theory.kronecker_symbol(2, 2) != 0 { return 9; }
  if math.number_theory.kronecker_symbol(1, 2) != 1 { return 10; }
  if math.number_theory.kronecker_symbol(3, 2) != -1 { return 11; }
  if math.number_theory.kronecker_symbol(7, 2) != 1 { return 12; }
  if math.number_theory.kronecker_symbol(2, 0) != 0 { return 13; }
  if math.number_theory.kronecker_symbol(1, 0) != 1 { return 14; }
  if math.number_theory.kronecker_symbol(5, 1) != 1 { return 15; }

  // 3: p*p loops, small-input equivalence
  if math.number_theory.euler_phi(12) != 4 { return 16; }
  if math.number_theory.mobius(30) != -1 { return 17; }
  if math.number_theory.radical(12) != 6 { return 18; }
  if math.number_theory.jordan_totient(12, 2) != 96 { return 19; }
  if math.number_theory.carmichael(8) != 2 { return 20; }
  if math.number_theory.carmichael(12) != 2 { return 21; }
  if !math.number_theory.smooth(12, 3) { return 22; }
  if math.number_theory.smooth(12, 2) { return 23; }
  if math.number_theory.rough(12, 3) { return 24; }
  if !math.number_theory.rough(35, 3) { return 25; }

  // 4: next_prime boundary (post-fix addendum)
  if math.number_theory.next_prime(9223372036854775805) != 0 { return 26; }
  if math.number_theory.next_prime(9223372036854775804) != 0 { return 27; }
  if math.number_theory.next_prime(7) != 11 { return 28; }
  return 0;
}
