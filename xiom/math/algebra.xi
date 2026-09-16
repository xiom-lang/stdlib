// XIOM - Math: Algebra
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.algebra

// Depends on: none

// ============================================================================
// Number-theoretic and combinatorial integer algebra.
//
// Integer building blocks (gcd/lcm/egcd/mod_inverse/pow_mod, power-of-two
// tests, integer sqrt) are real in xiom.math.arithmetic / xiom.math.roots;
// those functions are reused by qualified delegation (DRY). Symbol functions
// (Legendre/Jacobi), CRT, primorial, nth-prime and the combinatorial helpers
// are implemented here directly. Native Int division truncates toward zero
// and `%` follows the dividend sign; all overflow-prone paths are guarded and
// return a documented 0 sentinel. NOTE: requires/ensures clauses are
// runtime-enforced in this compiler and crash on violation, so all domain and
// overflow handling lives in the function bodies.
// ============================================================================

use xiom.math;

// ============================================================================
// Divisibility
// ============================================================================

// Greatest common divisor of a and b; always non-negative (gcd(0, 0) == 0).
// Delegates to xiom.math.arithmetic.gcd, which saturates the one
// unrepresentable case gcd(INT_MIN, k) = 2^63 to INT_MAX (documented).
// Complexity: O(log min(|a|, |b|)).
pub fn gcd(a: Int, b: Int) -> Int {
  return math.arithmetic.gcd(a, b);
}

// Least common multiple of |a| and |b|; always non-negative. 0 when either
// input is 0 and 0 (documented overflow) when the true lcm exceeds Int
// range. Delegates to xiom.math.arithmetic.lcm. Complexity: O(gcd).
pub fn lcm(a: Int, b: Int) -> Int {
  return math.arithmetic.lcm(a, b);
}

// Extended Euclid: (g, x, y) with a*x + b*y == g == gcd(a, b), g >= 0.
// For a == b == 0 returns (0, 1, 0). Delegates to
// xiom.math.arithmetic.gcd_extended. Complexity: O(log min(|a|, |b|)).
pub fn egcd(a: Int, b: Int) -> (Int, Int, Int) {
  return math.arithmetic.gcd_extended(a, b);
}

// Multiplicative inverse of a modulo m: x with (a * x) % m == 1. Returns
// None when gcd(a, m) != 1 (no inverse), when m == 0 (no modulus), and
// Some(0) for m == 1 (everything is 0 mod 1). Delegates to
// xiom.math.arithmetic.mod_inverse. Complexity: O(log min(|a|, |m|)).
pub fn mod_inverse(a: Int, m: Int) -> Option[Int] {
  return math.arithmetic.mod_inverse(a, m);
}

// ============================================================================
// Modular arithmetic
// ============================================================================

// Chinese remainder theorem solution x with x % m_i == r_i for every i.
// Returns None when the moduli are not pairwise coprime, when the two slices
// differ in length, or when any slice is empty. The combination
// x = sum(r_i * M_i * inv(M_i mod m_i, m_i)) is built over M = prod(m_i);
// intermediate products can overflow Int for large moduli (documented; for
// pairwise-coprime small moduli the result is exact and in [0, M)).
// Complexity: O(n^2 * log max(m_i)) for the coprimality check plus O(n log)
// for the inverses.
pub fn crt(remainders: &Vec[Int], moduli: &Vec[Int]) -> Option[Int] {
  var n = moduli.len();
  if remainders.len() != n { return None; }
  if n == 0 { return None; }
  var i = 0;
  while i < n {
    var j = i + 1;
    while j < n {
      if math.arithmetic.gcd(moduli[i], moduli[j]) != 1 { return None; }
      j = j + 1;
    }
    i = i + 1;
  }
  var M = 1;
  var k = 0;
  while k < n {
    M = M * moduli[k];
    k = k + 1;
  }
  var x = 0;
  var t = 0;
  while t < n {
    var Mi = M / moduli[t];
    var inv = math.arithmetic.mod_inverse(Mi % moduli[t], moduli[t]);
    if !inv.is_some() { return None; }
    x = x + remainders[t] * Mi * inv.unwrap();
    t = t + 1;
  }
  if x < 0 { x = x + M; }
  return Some(x % M);
}

// ============================================================================
// Symbol functions
// ============================================================================

// Legendre symbol (a/p) for odd prime p: 1 when a is a quadratic residue
// modulo p, -1 when it is a non-residue, 0 when p divides a. Uses Euler's
// criterion a^((p-1)/2) mod p via modular exponentiation. p == 2 is handled
// directly (1 for odd a, 0 for even a); p <= 1 returns 0 (documented, no
// modulus). Complexity: O(log p).
pub fn legendre_symbol(a: Int, p: Int) -> Int {
  if p <= 1 { return 0; }
  if p == 2 {
    if a % 2 == 0 { return 0; }
    return 1;
  }
  if a % p == 0 { return 0; }
  var r = math.arithmetic.pow_mod(a, (p - 1) / 2, p);
  if r == 1 { return 1; }
  if r == p - 1 { return -1; }
  return 0;
}

// Jacobi symbol (a/n) for odd positive n; generalizes the Legendre symbol
// to composite odd n. Returns 0 for even or non-positive n (documented; the
// Jacobi symbol is undefined there) and 0 when gcd(a, n) != 1. Uses the
// standard quadratic-reciprocity reduction over the binary expansion.
// Complexity: O(log^2 n) worst case.
pub fn jacobi_symbol(a: Int, n: Int) -> Int {
  if n <= 0 { return 0; }
  if n % 2 == 0 { return 0; }
  var aa = a % n;
  if aa < 0 { aa = aa + n; }
  var result = 1;
  var m = n;
  while aa != 0 {
    while aa % 2 == 0 {
      aa = aa / 2;
      var r = m % 8;
      if r == 3 || r == 5 { result = -result; }
    }
    var t = aa;
    aa = m;
    m = t;
    if aa % 4 == 3 && m % 4 == 3 { result = -result; }
    aa = aa % m;
  }
  if m == 1 { return result; }
  return 0;
}

// ============================================================================
// Combinatorics
// ============================================================================

// Binomial coefficient C(n, k). Returns 0 for invalid input (k < 0, k > n,
// n < 0) and 0 on overflow. Computed by the multiplicative form with an
// overflow guard on every step (result * (n - i + 1) / i stays in range).
// Complexity: O(min(k, n - k)).
pub fn binomial(n: Int, k: Int) -> Int {
  if n < 0 { return 0; }
  if k < 0 || k > n { return 0; }
  if k == 0 || k == n { return 1; }
  var kk = k;
  if kk > n - kk { kk = n - kk; }
  var result = 1;
  var i = 1;
  while i <= kk {
    var num = n - i + 1;
    if result > 9223372036854775807 / num { return 0; }
    result = result * num;
    result = result / i;
    i = i + 1;
  }
  return result;
}

// Factorial of n (n!). Returns 0 for n < 0 and 0 on overflow (n >= 21
// exceeds Int range). Complexity: O(n).
pub fn factorial(n: Int) -> Int {
  if n < 0 { return 0; }
  if n <= 1 { return 1; }
  var result = 1;
  var i = 2;
  while i <= n {
    if result > 9223372036854775807 / i { return 0; }
    result = result * i;
    i = i + 1;
  }
  return result;
}

// ============================================================================
// Primes
// ============================================================================

// Product of the first n primes (p_n#). Returns 0 for n <= 0 and 0
// (documented overflow) when the product exceeds Int range (n > 15).
// Complexity: O(n * sqrt(p_n)) trial division.
pub fn primorial(n: Int) -> Int {
  if n <= 0 { return 0; }
  var result = 1;
  var count = 0;
  var cand = 2;
  while count < n {
    if is_prime(cand) {
      if result > 9223372036854775807 / cand { return 0; }
      result = result * cand;
      count = count + 1;
    }
    cand = cand + 1;
  }
  return result;
}

// The n-th prime, 1-indexed (nth_prime(1) == 2). Returns 0 for n <= 0.
// Trial-division sieve walking odd candidates. Complexity: O(n * sqrt(p_n)).
pub fn nth_prime(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 2; }
  var count = 1;
  var cand = 3;
  while count < n {
    if is_prime(cand) { count = count + 1; }
    if count < n { cand = cand + 2; }
  }
  return cand;
}

// ============================================================================
// Integer roots and powers of two
// ============================================================================

// floor(sqrt(n)) for n >= 0 via integer Newton iteration (no float, no
// overflow). Returns -1 for n < 0 (documented). Delegates to
// xiom.math.roots.integer_sqrt. Complexity: O(log n) iterations.
pub fn integer_sqrt(n: Int) -> Int {
  return math.roots.integer_sqrt(n);
}

// Smallest power of two >= n. Returns 1 for n <= 0 and 0 (documented
// overflow) when the next power of two exceeds Int range (n > 2^62).
// Delegates to xiom.math.arithmetic.next_power_of_two. Complexity: O(log n).
pub fn next_power_of_two(n: Int) -> Int {
  return math.arithmetic.next_power_of_two(n);
}

// True iff n is a positive power of two (is_power_of_two(0) == false,
// is_power_of_two(1) == true). Delegates to
// xiom.math.arithmetic.is_power_of_two. Complexity: O(log n).
pub fn is_power_of_two(n: Int) -> Bool {
  return math.arithmetic.is_power_of_two(n);
}

// True iff n is a perfect square (0 and 1 are squares). Returns false for
// n < 0. Uses the exact integer floor-sqrt check. Complexity: O(log n).
pub fn is_perfect_square(n: Int) -> Bool {
  if n < 0 { return false; }
  var r = math.roots.integer_sqrt(n);
  return r * r == n;
}

// ============================================================================
// Internal helpers
// ============================================================================

// Deterministic trial-division primality test for 64-bit n. O(sqrt(n)).
fn is_prime(n: Int) -> Bool {
  if n < 2 { return false; }
  if n == 2 { return true; }
  if n % 2 == 0 { return false; }
  var i = 3;
  while i * i <= n {
    if n % i == 0 { return false; }
    i = i + 2;
  }
  return true;
}
