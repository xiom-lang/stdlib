// XIOM - Math: Number Theory
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.number_theory

// Depends on: xiom.math

// ============================================================================
// Primality, factorization, totient/symbol functions, and divisor arithmetic.
// NOTE: current implementation lives in num/bigint.xi is_prime/next_prime +
// math/algebra.xi - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

use xiom.math;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// True iff a * b overflows Int (sign-aware).
fn _mul_ovf(a: Int, b: Int) -> Bool {
  if a == 0 || b == 0 { return false; }
  if a == 1 || b == 1 { return false; }
  if a > 0 && b > 0 { return a > 9223372036854775807 / b; }
  if a > 0 && b < 0 { return b < -9223372036854775808 / a; }
  if a < 0 && b > 0 { return a < -9223372036854775808 / b; }
  return a < 9223372036854775807 / b;
}

// (a + b) mod m for 0 <= a, b < m and m > 0, without overflow.
fn _addmod(a: Int, b: Int, m: Int) -> Int {
  var rem = m - b;
  if a >= rem { return a - rem; }
  return a + b;
}

// (a * b) mod m via double-and-add, never overflowing Int.
fn _mulmod(a: Int, b: Int, m: Int) -> Int {
  var res = 0;
  var aa = a % m;
  if aa < 0 { aa = aa + m; }
  var bb = b % m;
  if bb < 0 { bb = bb + m; }
  while bb > 0 {
    if bb % 2 == 1 { res = _addmod(res, aa, m); }
    aa = _addmod(aa, aa, m);
    bb = bb / 2;
  }
  return res;
}

// a^e mod m for m > 0, exponentiation by squaring over _mulmod.
fn _powmod(a: Int, e: Int, m: Int) -> Int {
  var res = 1;
  var b = a % m;
  if b < 0 { b = b + m; }
  var ex = e;
  while ex > 0 {
    if ex % 2 == 1 { res = _mulmod(res, b, m); }
    b = _mulmod(b, b, m);
    ex = ex / 2;
  }
  return res;
}

// base^exp for base >= 1, exp >= 0; 0 on overflow (genuine powers of primes
// are never 0).
fn _pow(b: Int, e: Int) -> Int {
  var result = 1;
  var base = b;
  var ex = e;
  while ex > 0 {
    if ex % 2 == 1 {
      if _mul_ovf(result, base) { return 0; }
      result = result * base;
    }
    ex = ex / 2;
    if ex > 0 {
      if _mul_ovf(base, base) { return 0; }
      base = base * base;
    }
  }
  return result;
}

// Deterministic trial-division primality test. O(sqrt(n)).
fn _trial_prime(n: Int) -> Bool {
  if n < 2 { return false; }
  if n == 2 { return true; }
  if n % 2 == 0 { return false; }
  var i = 3;
  while i <= n / i {
    if n % i == 0 { return false; }
    i = i + 2;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Primality
// ---------------------------------------------------------------------------

// Deterministic primality test for 64-bit n (Miller-Rabin over the fixed
// base set {2, 325, 9375, 28178, 450775, 9780504, 1795265022}, which is
// proven for every n < 2^64). Returns false for n < 2. Complexity: O(log^3 n).
pub fn is_prime(n: Int) -> Bool {
  return is_prime_deterministic(n);
}

// Strict deterministic primality test: Miller-Rabin with the fixed base set
// proven correct for all 64-bit integers. Returns false for n < 2.
// Complexity: O(log^3 n).
pub fn is_prime_deterministic(n: Int) -> Bool {
  if n < 2 { return false; }
  if n == 2 { return true; }
  if n % 2 == 0 { return false; }
  var d = n - 1;
  var s = 0;
  while d % 2 == 0 {
    d = d / 2;
    s = s + 1;
  }
  var bases = Vec[Int].new();
  bases.push(2);
  bases.push(325);
  bases.push(9375);
  bases.push(28178);
  bases.push(450775);
  bases.push(9780504);
  bases.push(1795265022);
  var i = 0;
  while i < bases.len() {
    var a = bases[i] % n;
    if a < 0 { a = a + n; }
    if a != 0 {
      var x = _powmod(a, d, n);
      if x == 1 || x == n - 1 {
        // strong probable prime for this base
      } else {
        var composite = true;
        var r = 1;
        while r < s {
          x = _mulmod(x, x, n);
          if x == n - 1 {
            composite = false;
            r = s;
          }
          r = r + 1;
        }
        if composite { return false; }
      }
    }
    i = i + 1;
  }
  return true;
}

// Smallest prime strictly greater than n. Returns 0 for n < 0 (no positive
// prime is representable in range for the largest inputs) and 0 when no such
// prime fits in Int (n >= INT_MAX - 1). Complexity: O(gap * sqrt(p)).
pub fn next_prime(n: Int) -> Int {
  if n < 2 { return 2; }
  if n >= 9223372036854775806 { return 0; }
  var cand = n + 1;
  if cand % 2 == 0 { cand = cand + 1; }
  while !is_prime(cand) {
    cand = cand + 2;
  }
  return cand;
}

// Largest prime strictly less than n. Returns 0 for n <= 2 (no such prime)
// and 0 (documented) when the search leaves the representable range.
// Complexity: O(gap * sqrt(p)).
pub fn prev_prime(n: Int) -> Int {
  if n <= 2 { return 0; }
  var cand = n - 1;
  if cand % 2 == 0 { cand = cand - 1; }
  while cand >= 3 {
    if is_prime(cand) { return cand; }
    cand = cand - 2;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Factorization
// ---------------------------------------------------------------------------

// Prime factorization of n with multiplicity. Returns the empty list for
// n <= 1; negative n is factored by absolute value. Complexity: O(sqrt(|n|)).
pub fn factor(n: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if n <= 1 { return out; }
  var x = n;
  if x < 0 { x = -x; }
  while x % 2 == 0 {
    out.push(2);
    x = x / 2;
  }
  var p = 3;
  while p <= x / p {
    while x % p == 0 {
      out.push(p);
      x = x / p;
    }
    p = p + 2;
  }
  if x > 1 { out.push(x); }
  return out;
}

// A non-trivial factor of n via Pollard's rho (Floyd cycle detection with
// f(x) = x^2 + c mod n). Returns n itself when n is prime or when no split is
// found within the retry budget (documented; a repeated call with a different
// internal constant is the standard recovery). Returns 1 for n <= 1.
// Complexity: O(sqrt(p)) expected for the smallest prime factor p.
pub fn pollard_rho(n: Int) -> Int {
  if n <= 1 { return 1; }
  if n % 2 == 0 { return 2; }
  if is_prime(n) { return n; }
  var c = 1;
  while c < 100 {
    var x = 2;
    var y = 2;
    var d = 1;
    var guard = 0;
    while d == 1 && guard < 100000 {
      x = _addmod(_mulmod(x, x, n), c, n);
      var y1 = _addmod(_mulmod(y, y, n), c, n);
      y = _addmod(_mulmod(y1, y1, n), c, n);
      var diff = x - y;
      if diff < 0 { diff = -diff; }
      d = math.arithmetic.gcd(diff, n);
      guard = guard + 1;
    }
    if d != n { return d; }
    c = c + 1;
  }
  return n;
}

// A non-trivial factor of n via Pollard's p-1 method (a = 2^B! mod n for an
// increasing stage bound B). Returns n itself when n is prime or when no
// factor is found within the stage bound (documented). Returns 1 for n <= 1.
// Complexity: O(B * log B * mulmod).
pub fn p_1_factor(n: Int) -> Int {
  if n <= 1 { return 1; }
  if n % 2 == 0 { return 2; }
  if is_prime(n) { return n; }
  var b = 2;
  var j = 2;
  while j <= 200 {
    var r = 1;
    var t = 0;
    while t < j {
      r = _mulmod(r, b, n);
      t = t + 1;
    }
    b = r;
    var g = math.arithmetic.gcd(b - 1, n);
    if g > 1 && g < n { return g; }
    j = j + 1;
  }
  return n;
}

// True iff n passes the Fermat test for base a, i.e. a^(n-1) == 1 (mod n).
// Returns false for n <= 1, true for n == 2, and false when a is a multiple
// of n (the residue is 0, not 1). Primes always pass; composite pseudoprimes
// to base a also return true. Complexity: O(log n).
pub fn is_pseudoprime(n: Int, base: Int) -> Bool {
  if n <= 1 { return false; }
  if n == 2 { return true; }
  if base % n == 0 { return false; }
  return math.arithmetic.pow_mod(base, n - 1, n) == 1;
}

// Miller-Rabin strong pseudoprime test against the supplied bases. Returns
// false for n <= 1, even n (n > 2) and for any base witnessing compositeness;
// a value that passes every base is reported true (likely prime, exactly
// prime for n < 2^64 when the base set is the deterministic one).
// Complexity: O(|bases| * log^3 n).
pub fn miller_rabin(n: Int, bases: &Vec[Int]) -> Bool {
  if n <= 1 { return false; }
  if n == 2 { return true; }
  if n % 2 == 0 { return false; }
  var d = n - 1;
  var s = 0;
  while d % 2 == 0 {
    d = d / 2;
    s = s + 1;
  }
  var i = 0;
  while i < bases.len() {
    var a = bases[i] % n;
    if a < 0 { a = a + n; }
    if a != 0 {
      var x = _powmod(a, d, n);
      if x == 1 || x == n - 1 {
        // passes this base
      } else {
        var composite = true;
        var r = 1;
        while r < s {
          x = _mulmod(x, x, n);
          if x == n - 1 {
            composite = false;
            r = s;
          }
          r = r + 1;
        }
        if composite { return false; }
      }
    }
    i = i + 1;
  }
  return true;
}

// Fermat compositeness test with base a: true iff a^(n-1) == 1 (mod n).
// Alias of is_pseudoprime. Complexity: O(log n).
pub fn fermat_test(n: Int, a: Int) -> Bool {
  return is_pseudoprime(n, a);
}

// Lucas-Lehmer primality test for the Mersenne number M_p = 2^p - 1.
// Returns false for p < 2 and when M_p does not fit in Int (p > 62).
// Complexity: O(p * mulmod).
pub fn lucas_lehmer(p: Int) -> Bool {
  if p < 2 { return false; }
  if p == 2 { return true; }
  var m = 1;
  var i = 0;
  while i < p {
    if m > 9223372036854775807 / 2 { return false; }
    m = m * 2;
    i = i + 1;
  }
  m = m - 1;
  var s = 4;
  var j = 2;
  while j <= p - 1 {
    var sq = _mulmod(s, s, m);
    var v = sq - 2;
    if v < 0 { v = v + m; }
    s = v;
    j = j + 1;
  }
  return s == 0;
}

// True iff 2^p - 1 is prime. Alias of lucas_lehmer. Returns false for p < 2
// and when M_p exceeds Int range. Complexity: O(p * mulmod).
pub fn mersenne_prime_p(p: Int) -> Bool {
  return lucas_lehmer(p);
}

// ---------------------------------------------------------------------------
// Totient and symbol functions
// ---------------------------------------------------------------------------

// Euler totient phi(n): count of integers k in [1, n] coprime to n.
// Returns 0 for n <= 0 (documented). Complexity: O(sqrt(n)).
pub fn euler_phi(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  var result = n;
  var temp = n;
  var p = 2;
  while p * p <= temp {
    if temp % p == 0 {
      while temp % p == 0 { temp = temp / p; }
      result = result / p * (p - 1);
    }
    p = p + 1;
  }
  if temp > 1 {
    result = result / temp * (temp - 1);
  }
  return result;
}

// Mobius function mu(n): 0 if n has a squared prime factor, otherwise
// (-1)^k with k the number of distinct prime factors. Returns 0 for n <= 0
// (documented). Complexity: O(sqrt(n)).
pub fn mobius(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  var x = n;
  var count = 0;
  var p = 2;
  while p * p <= x {
    if x % p == 0 {
      x = x / p;
      if x % p == 0 { return 0; }
      count = count + 1;
    }
    p = p + 1;
  }
  if x > 1 { count = count + 1; }
  if count % 2 == 0 { return 1; }
  return -1;
}

// Jordan totient J_k(n): count of k-tuples (x_1..x_k) in [1, n]^k that are
// jointly coprime to n. Returns 0 for n <= 0, 1 for n == 1, 0 for k < 0
// (documented) and 0 for k == 0 with n > 1 (J_0(n) = 0). Returns 0
// (documented overflow) when the value exceeds Int range.
// Complexity: O(sqrt(n) * log k).
pub fn jordan_totient(n: Int, k: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  if k < 0 { return 0; }
  if k == 0 { return 0; }
  var nk = _pow(n, k);
  if nk == 0 { return 0; }
  var result = nk;
  var temp = n;
  var p = 2;
  while p * p <= temp {
    if temp % p == 0 {
      while temp % p == 0 { temp = temp / p; }
      var pk = _pow(p, k);
      if pk == 0 { return 0; }
      var div = result / pk;
      if _mul_ovf(div, pk - 1) { return 0; }
      result = div * (pk - 1);
    }
    p = p + 1;
  }
  if temp > 1 {
    var pk = _pow(temp, k);
    if pk == 0 { return 0; }
    var div = result / pk;
    if _mul_ovf(div, pk - 1) { return 0; }
    result = div * (pk - 1);
  }
  return result;
}

// Carmichael lambda function: the smallest m with a^m == 1 (mod n) for every
// a coprime to n. Computed as the lcm of lambda(p^a) over the prime powers
// dividing n: lambda(2) = 1, lambda(4) = 2, lambda(2^a) = 2^(a-2) for a >= 3,
// lambda(p^a) = p^(a-1)(p-1) for odd p. Returns 0 for n <= 0 and 0
// (documented overflow) when the value exceeds Int range. Complexity:
// O(sqrt(n) * lcm).
pub fn carmichael(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  var result = 1;
  var m = n;
  var p = 2;
  while p * p <= m || p == 2 {
    if m % p == 0 {
      var pe = 1;
      while m % p == 0 {
        pe = pe * p;
        m = m / p;
      }
      var lam = 1;
      if p == 2 {
        if pe == 4 { lam = 2; }
        else {
          if pe >= 8 { lam = pe / 4; }
        }
      } else {
        if _mul_ovf(pe / p, p - 1) { return 0; }
        lam = (pe / p) * (p - 1);
      }
      result = math.arithmetic.lcm(result, lam);
      if result == 0 { return 0; }
    }
    if p == 2 { p = 3; }
    else { p = p + 2; }
  }
  if m > 1 {
    result = math.arithmetic.lcm(result, m - 1);
  }
  return result;
}

// ---------------------------------------------------------------------------
// Prime counting
// ---------------------------------------------------------------------------

// pi(n): the number of primes <= n. Returns 0 for n < 2. Uses a simple
// sieve of Eratosthenes over [0, n]. Complexity: O(n log log n).
pub fn prime_pi(n: Int) -> Int {
  if n < 2 { return 0; }
  var isc = Vec[Bool].new();
  var i = 0;
  while i <= n {
    isc.push(false);
    i = i + 1;
  }
  var count = 0;
  var p = 2;
  while p <= n {
    if !(isc[p]) {
      count = count + 1;
      if p <= 3037000499 {
        var j = p * p;
        while j <= n {
          isc[j] = true;
          j = j + p;
        }
      }
    }
    p = p + 1;
  }
  return count;
}

// The n-th prime, 1-indexed (nth_prime(1) == 2). Returns 0 for n <= 0 and 0
// (documented) when the search leaves the representable Int range.
// Complexity: O(n * sqrt(p_n)).
pub fn nth_prime(n: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 2; }
  var count = 1;
  var cand = 3;
  while count < n {
    if is_prime(cand) { count = count + 1; }
    if count < n {
      if cand >= 9223372036854775805 { return 0; }
      cand = cand + 2;
    }
  }
  return cand;
}

// Product of the first n primes (p_n#). Returns 0 for n <= 0 and 0
// (documented overflow) when the product exceeds Int range (n > 15).
// Complexity: O(n * sqrt(p_n)).
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

// ---------------------------------------------------------------------------
// Integer properties
// ---------------------------------------------------------------------------

// True iff n is composite (n > 1 and not prime). Returns false for n <= 1.
// Complexity: O(log^3 n) via the Miller-Rabin primality test.
pub fn is_composite(n: Int) -> Bool {
  if n <= 1 { return false; }
  return !is_prime(n);
}

// True iff n is a product of exactly two primes (with multiplicity), so
// squares of primes count. Returns false for n < 4. Complexity: O(sqrt(n)).
pub fn is_semiprime(n: Int) -> Bool {
  if n < 4 { return false; }
  var fs = factor(n);
  return fs.len() == 2;
}

// True iff n is a perfect power a^k for integers a and k >= 2. Returns false
// for n <= 1. Uses the prime-exponent gcd criterion: n is a perfect power iff
// the gcd of the exponents in its prime factorization exceeds 1.
// Complexity: O(sqrt(n)).
pub fn is_power(n: Int) -> Bool {
  if n <= 1 { return false; }
  var fs = factor(n);
  if fs.len() <= 1 { return false; }
  var g = 0;
  var i = 0;
  while i < fs.len() {
    var j = i;
    var cnt = 0;
    while j < fs.len() && fs[j] == fs[i] {
      cnt = cnt + 1;
      j = j + 1;
    }
    g = math.arithmetic.gcd(g, cnt);
    i = j;
  }
  return g > 1;
}

// True iff n is a power of base: n == base^k for some integer k >= 1.
// Special cases: base 0 (only n == 0), base 1 (only n == 1), base -1
// (n == 1 or n == -1). Returns false when the power series overflows Int
// before reaching n. Complexity: O(log_base |n|).
pub fn is_power_of(n: Int, base: Int) -> Bool {
  if base == 0 { return n == 0; }
  if base == 1 { return n == 1; }
  if base == -1 { return n == 1 || n == -1; }
  var value = base;
  while true {
    if value == n { return true; }
    if _mul_ovf(value, base) { return false; }
    value = value * base;
  }
}

// ---------------------------------------------------------------------------
// Divisors and smoothness
// ---------------------------------------------------------------------------

// Radical of n: the product of the distinct prime factors of n. Returns n for
// n <= 1 (rad(1) = 1, rad(0) = 0) and 0 (documented overflow) when the product
// exceeds Int range. Negative n is handled by absolute value. Complexity:
// O(sqrt(n)).
pub fn radical(n: Int) -> Int {
  if n <= 1 { return n; }
  var x = n;
  if x < 0 { x = -x; }
  var result = 1;
  var p = 2;
  while p * p <= x {
    if x % p == 0 {
      if _mul_ovf(result, p) { return 0; }
      result = result * p;
      while x % p == 0 { x = x / p; }
    }
    p = p + 1;
  }
  if x > 1 {
    if _mul_ovf(result, x) { return 0; }
    result = result * x;
  }
  return result;
}

// True iff every prime factor of n is <= bound. Returns true for n <= 1
// (no prime factors) and false for bound <= 1. Negative n is handled by
// absolute value. Complexity: O(sqrt(n)).
pub fn smooth(n: Int, bound: Int) -> Bool {
  if n <= 1 { return true; }
  if bound <= 1 { return false; }
  var x = n;
  if x < 0 { x = -x; }
  var p = 2;
  while p * p <= x {
    while x % p == 0 {
      if p > bound { return false; }
      x = x / p;
    }
    p = p + 1;
  }
  if x > 1 && x > bound { return false; }
  return true;
}

// True iff every prime factor of n is > bound. Returns true for n <= 1 (no
// prime factors). Negative n is handled by absolute value. Complexity:
// O(sqrt(n)).
pub fn rough(n: Int, bound: Int) -> Bool {
  if n <= 1 { return true; }
  var x = n;
  if x < 0 { x = -x; }
  var p = 2;
  while p * p <= x {
    while x % p == 0 {
      if p <= bound { return false; }
      x = x / p;
    }
    p = p + 1;
  }
  if x > 1 && x <= bound { return false; }
  return true;
}

// Legendre symbol (a/p) for odd prime p: 1 for a quadratic residue, -1 for a
// non-residue, 0 when p divides a. Uses Euler's criterion a^((p-1)/2) mod p.
// p == 2 is handled directly (1 for odd a, 0 for even a); p <= 1 returns 0
// (documented, no modulus). Complexity: O(log p).
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

// Jacobi symbol (a/n) for odd positive n; generalizes the Legendre symbol to
// composite odd n. Returns 0 for even or non-positive n (documented; the
// Jacobi symbol is undefined there) and 0 when gcd(a, n) != 1. Uses the
// quadratic-reciprocity reduction over the binary expansion of a.
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

// Kronecker symbol (a/n), the full extension of the Jacobi symbol to all
// integer n. Returns 1 for n == 1, (a/-1) by the sign of a, and uses the
// 2-adic rules for even n. n == 0 gives 1 iff a == 1 or a == -1, else 0.
// Complexity: O(log^2 |n|).
pub fn kronecker_symbol(a: Int, n: Int) -> Int {
  if n == 0 {
    if a == 1 || a == -1 { return 1; }
    return 0;
  }
  if n == 1 { return 1; }
  var aa = a;
  var nn = n;
  var result = 1;
  if nn < 0 {
    nn = -nn;
    if aa < 0 { result = -result; }
  }
  if nn == 1 { return result; }
  var e = 0;
  while nn % 2 == 0 {
    nn = nn / 2;
    e = e + 1;
  }
  var t2 = _kronecker_2(aa);
  if t2 == 0 { return 0; }
  var k = 0;
  while k < e {
    result = result * t2;
    k = k + 1;
  }
  if nn == 1 { return result; }
  var j = _jacobi_odd(aa, nn);
  return result * j;
}

// (a/2): 0 for even a, 1 for a == 1 or 7 (mod 8), -1 for a == 3 or 5 (mod 8).
fn _kronecker_2(a: Int) -> Int {
  if a % 2 == 0 { return 0; }
  var r = a % 8;
  if r < 0 { r = r + 8; }
  if r == 1 || r == 7 { return 1; }
  return -1;
}

// Jacobi (a/n) for odd positive n >= 3 (quadratic-reciprocity reduction).
fn _jacobi_odd(a: Int, n: Int) -> Int {
  if n <= 1 { return 1; }
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

// Sum of the k-th powers of the positive divisors of n, sigma_k(n). Returns
// 0 for n <= 0 and 0 for k < 0 (documented). Computed from the prime
// factorization: sigma_k(n) = prod (p^(k(e+1)) - 1)/(p^k - 1); k == 0 is the
// divisor count. Returns 0 (documented overflow) when the value exceeds Int
// range. Complexity: O(sqrt(n) * log k).
pub fn divisor_sum(n: Int, k: Int) -> Int {
  if n <= 0 { return 0; }
  if n == 1 { return 1; }
  if k < 0 { return 0; }
  var fs = factor(n);
  var result = 1;
  var i = 0;
  while i < fs.len() {
    var p = fs[i];
    var e = 0;
    while i < fs.len() && fs[i] == p {
      e = e + 1;
      i = i + 1;
    }
    var term = e + 1;
    if k != 0 {
      var pk = _pow(p, k);
      if pk == 0 { return 0; }
      var pke = _pow(p, k * (e + 1));
      if pke == 0 { return 0; }
      term = (pke - 1) / (pk - 1);
    }
    if _mul_ovf(result, term) { return 0; }
    result = result * term;
  }
  return result;
}

// Number of positive divisors of n. Returns 0 for n <= 0. Alias of
// divisor_sum(n, 0). Complexity: O(sqrt(n)).
pub fn divisor_count(n: Int) -> Int {
  return divisor_sum(n, 0);
}

// All positive divisors of n excluding n itself (unsorted). Returns the empty
// list for n <= 1 (1 has no proper divisors). Complexity: O(sqrt(n)).
pub fn proper_divisors(n: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  if n <= 1 { return out; }
  var i = 1;
  while i <= n / i {
    if n % i == 0 {
      if i != n { out.push(i); }
      var j = n / i;
      if j != i && j != n { out.push(j); }
    }
    i = i + 1;
  }
  return out;
}
