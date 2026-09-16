// XIOM - Math: Modular
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.modular

// Depends on: xiom.math

// ============================================================================
// Modular arithmetic, CRT, and root extraction modulo a prime. NOTE: current
// implementation lives in num/bigint.xi pow_mod/mod_inverse + math/algebra.xi
// - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

use xiom.math;

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

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

// base^exp for base >= 1, exp >= 0; 0 on overflow.
fn _pow(b: Int, e: Int) -> Int {
  var result = 1;
  var base = b;
  var ex = e;
  while ex > 0 {
    if ex % 2 == 1 {
      if result > 9223372036854775807 / base { return 0; }
      result = result * base;
    }
    ex = ex / 2;
    if ex > 0 {
      if base > 3037000499 { return 0; }
      base = base * base;
    }
  }
  return result;
}

// True iff a * b overflows Int (sign-aware).
fn _mul_ovf(a: Int, b: Int) -> Bool {
  if a == 0 || b == 0 { return false; }
  if a == 1 || b == 1 { return false; }
  if a > 0 && b > 0 { return a > 9223372036854775807 / b; }
  if a > 0 && b < 0 { return b < -9223372036854775808 / a; }
  if a < 0 && b > 0 { return a < -9223372036854775808 / b; }
  return a < 9223372036854775807 / b;
}

// ---------------------------------------------------------------------------
// Basic modular arithmetic
// ---------------------------------------------------------------------------

// (a + b) mod m with the result in [0, m). Returns 0 for m <= 0 (no modulus,
// documented) and 0 for m == 1 (everything is 0 mod 1). Complexity: O(1).
pub fn mod_add(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var x = a % m;
  if x < 0 { x = x + m; }
  var y = b % m;
  if y < 0 { y = y + m; }
  return _addmod(x, y, m);
}

// (a - b) mod m with the result in [0, m). Returns 0 for m <= 0 (no modulus,
// documented) and 0 for m == 1. Complexity: O(1).
pub fn mod_sub(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var x = a % m;
  if x < 0 { x = x + m; }
  var y = b % m;
  if y < 0 { y = y + m; }
  var r = x - y;
  if r < 0 { r = r + m; }
  return r;
}

// (a * b) mod m with the result in [0, m). Uses overflow-free double-and-add.
// Returns 0 for m <= 0 (no modulus, documented) and 0 for m == 1.
// Complexity: O(log min(a, b)).
pub fn mod_mul(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  return _mulmod(a, b, m);
}

// base^exp mod m with the result in [0, m). Delegates to
// xiom.math.arithmetic.pow_mod. Returns 0 for m <= 0, m == 1, and exp < 0
// (documented; only non-negative exponents are supported). Complexity:
// O(log exp).
pub fn mod_pow(base: Int, exp: Int, m: Int) -> Int {
  return math.arithmetic.pow_mod(base, exp, m);
}

// Multiplicative inverse of a mod m: x with (a*x) % m == 1. Returns 0 when no
// inverse exists (gcd(a, m) != 1), when m == 0 (no modulus) and for m == 1
// (documented). Delegates to xiom.math.arithmetic.mod_inverse. Complexity:
// O(log min(|a|, |m|)).
pub fn mod_inverse(a: Int, m: Int) -> Int {
  var inv = math.arithmetic.mod_inverse(a, m);
  if !(inv.is_some()) { return 0; }
  return inv.unwrap();
}

// A square root of a mod prime p (x with x^2 == a mod p), choosing the root in
// [0, (p-1)/2]. Returns 0 when no root exists, when p <= 1 (no modulus) and
// when p is composite (documented: p must be prime). Delegates to
// tonelli_shanks. Complexity: O(log^3 p).
pub fn mod_sqrt(a: Int, p: Int) -> Int {
  return tonelli_shanks(a, p);
}

// A cube root of a mod m: x with x^3 == a mod m. For prime m with gcd(3,
// m-1) == 1 the root is a^((2m-1)/3) mod m; for m == 1 (mod 3) a small scan is
// used. Returns 0 when no root exists, for m <= 0 (no modulus) and when m == 1.
// Complexity: O(log m) for the closed form, O(m) scan otherwise.
pub fn mod_cbrt(a: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var am = a % m;
  if am < 0 { am = am + m; }
  var g = math.arithmetic.gcd(3, m - 1);
  if g == 1 {
    var exp = (2 * m - 1) / 3;
    return math.arithmetic.pow_mod(am, exp, m);
  }
  var x = 0;
  while x < m {
    var c = _mulmod(_mulmod(x, x, m), x, m);
    if c == am { return x; }
    x = x + 1;
  }
  return 0;
}

// (a / b) mod m: a * b^(-1) mod m. Returns 0 when b has no inverse mod m
// (gcd(b, m) != 1), when m <= 0 (no modulus) and for m == 1 (documented).
// Complexity: O(log min(|b|, |m|)).
pub fn mod_div(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var inv = math.arithmetic.mod_inverse(b, m);
  if !(inv.is_some()) { return 0; }
  return _mulmod(a, inv.unwrap(), m);
}

// Least common multiple of a and b reduced mod m. Returns 0 when m <= 0 (no
// modulus), for m == 1 and when either input is 0. Uses the overflow-free
// modular multiply so the true lcm may exceed Int range. Complexity: O(log).
pub fn mod_lcm(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var g = math.arithmetic.gcd(a, b);
  if g == 0 { return 0; }
  var aq = a / g;
  return _mulmod(aq, b, m);
}

// ---------------------------------------------------------------------------
// Congruences
// ---------------------------------------------------------------------------

// Chinese remainder theorem solution x with x % m_i == r_i for every pair.
// Returns 0 when the slices differ in length, when either slice is empty, when
// any modulus is non-positive, when the moduli are not pairwise coprime, and
// when the product of the moduli overflows Int (documented). The result lies
// in [0, M) with M = prod(m_i). Complexity: O(n^2 * log max(m_i)).
pub fn crt(remainders: &Vec[Int], moduli: &Vec[Int]) -> Int {
  var n = moduli.len();
  if remainders.len() != n { return 0; }
  if n == 0 { return 0; }
  var i = 0;
  while i < n {
    if moduli[i] <= 0 { return 0; }
    var j = i + 1;
    while j < n {
      if math.arithmetic.gcd(moduli[i], moduli[j]) != 1 { return 0; }
      j = j + 1;
    }
    i = i + 1;
  }
  var M = 1;
  var k = 0;
  while k < n {
    if M > 9223372036854775807 / moduli[k] { return 0; }
    M = M * moduli[k];
    k = k + 1;
  }
  var x = 0;
  var t = 0;
  while t < n {
    var Mi = M / moduli[t];
    var inv = math.arithmetic.mod_inverse(Mi % moduli[t], moduli[t]);
    if !(inv.is_some()) { return 0; }
    var term = remainders[t] % moduli[t];
    if term < 0 { term = term + moduli[t]; }
    var prod = _mulmod(term, Mi, M);
    prod = _mulmod(prod, inv.unwrap(), M);
    x = _addmod(x, prod, M);
    t = t + 1;
  }
  return x;
}

// Solve a system of congruences given as (remainder, modulus) pairs using the
// iterative merging method. Returns 0 when the list is empty, when any
// modulus is non-positive, when the system is inconsistent, and on overflow
// (documented). Complexity: O(n * log max(m_i)).
pub fn crt_solve(congruences: &Vec[(Int, Int)]) -> Int {
  var n = congruences.len();
  if n == 0 { return 0; }
  var x = congruences[0].0;
  var m = congruences[0].1;
  if m <= 0 { return 0; }
  x = x % m;
  if x < 0 { x = x + m; }
  var i = 1;
  while i < n {
    var r2 = congruences[i].0;
    var m2 = congruences[i].1;
    if m2 <= 0 { return 0; }
    r2 = r2 % m2;
    if r2 < 0 { r2 = r2 + m2; }
    var g = math.arithmetic.gcd(m, m2);
    var diff = r2 - x;
    var dg = diff % g;
    if dg < 0 { dg = dg + g; }
    if dg != 0 { return 0; }
    var m1 = m / g;
    var m2r = m2 / g;
    var inv = math.arithmetic.mod_inverse(m1 % m2r, m2r);
    if !(inv.is_some()) { return 0; }
    var t0 = (diff / g) % m2r;
    if t0 < 0 { t0 = t0 + m2r; }
    var t = _mulmod(t0, inv.unwrap(), m2r);
    if _mul_ovf(m1, m2r) { return 0; }
    var nm = m1 * m2r;
    var step = _mulmod(m % nm, t, nm);
    x = (x + step) % nm;
    if x < 0 { x = x + nm; }
    m = nm;
    i = i + 1;
  }
  return x;
}

// Solve a*x == b (mod m): returns the least non-negative solution. Returns 0
// when m <= 0 (no modulus), when m == 1, when gcd(a, m) does not divide b (no
// solution) and on overflow (documented). Complexity: O(log min(|a|, |m|)).
pub fn linear_congruence(a: Int, b: Int, m: Int) -> Int {
  if m <= 0 { return 0; }
  if m == 1 { return 0; }
  var g = math.arithmetic.gcd(a, m);
  var bm = b % m;
  if bm < 0 { bm = bm + m; }
  if bm % g != 0 { return 0; }
  var a1 = a / g;
  var m1 = m / g;
  var b1 = bm / g;
  var inv = math.arithmetic.mod_inverse(a1 % m1, m1);
  if !(inv.is_some()) { return 0; }
  return _mulmod(b1 % m1, inv.unwrap(), m1);
}

// ---------------------------------------------------------------------------
// Quadratic residuosity and roots
// ---------------------------------------------------------------------------

// True iff a is a quadratic residue mod prime p, i.e. x^2 == a (mod p) has a
// solution. a == 0 (mod p) counts as a residue (x = 0). Returns false for
// p <= 1 (no modulus). Uses Euler's criterion. Complexity: O(log p).
pub fn quadratic_residue(a: Int, p: Int) -> Bool {
  if p <= 1 { return false; }
  var aa = a % p;
  if aa < 0 { aa = aa + p; }
  if aa == 0 { return true; }
  if p == 2 { return true; }
  var r = math.arithmetic.pow_mod(aa, (p - 1) / 2, p);
  return r == 1;
}

// Square root of n mod odd prime p via the Tonelli-Shanks algorithm, choosing
// the root in [0, (p-1)/2]. Returns 0 when n is a non-residue mod p, for
// p <= 2 (p == 2 is handled directly) and when p is composite (documented: p
// must be prime). Complexity: O(log^3 p).
pub fn tonelli_shanks(n: Int, p: Int) -> Int {
  if p <= 1 { return 0; }
  if p == 2 { return n % 2; }
  var nn = n % p;
  if nn < 0 { nn = nn + p; }
  if nn == 0 { return 0; }
  if !quadratic_residue(nn, p) { return 0; }
  var q = p - 1;
  var s = 0;
  while q % 2 == 0 {
    q = q / 2;
    s = s + 1;
  }
  var z = 2;
  while _powmod(z, (p - 1) / 2, p) != p - 1 {
    z = z + 1;
  }
  var m = s;
  var c = _powmod(z, q, p);
  var t = _powmod(nn, q, p);
  var r = _powmod(nn, (q + 1) / 2, p);
  while t != 1 {
    var i = 1;
    var tt = _mulmod(t, t, p);
    while tt != 1 && i < m {
      tt = _mulmod(tt, tt, p);
      i = i + 1;
    }
    if i >= m { return 0; }
    var e = _pow(2, m - i - 1);
    var b = _powmod(c, e, p);
    r = _mulmod(r, b, p);
    c = _mulmod(b, b, p);
    t = _mulmod(t, c, p);
    m = i;
  }
  if r > p - r { return p - r; }
  return r;
}

// Square root of n mod odd prime p via Cipolla's algorithm, choosing the root
// in [0, (p-1)/2]. Returns 0 when n is a non-residue mod p, for p <= 2 (p == 2
// is handled directly) and when p is composite (documented: p must be prime).
// Complexity: O(log^2 p).
pub fn cipolla(n: Int, p: Int) -> Int {
  if p <= 1 { return 0; }
  if p == 2 { return n % 2; }
  var nn = n % p;
  if nn < 0 { nn = nn + p; }
  if nn == 0 { return 0; }
  if !quadratic_residue(nn, p) { return 0; }
  var a = 0;
  var found = false;
  var w2 = 0;
  while a < p && !found {
    var sq = _mulmod(a, a, p);
    var cand = sq - nn;
    if cand < 0 { cand = cand + p; }
    if _powmod(cand, (p - 1) / 2, p) == p - 1 {
      found = true;
      w2 = cand;
    } else {
      a = a + 1;
    }
  }
  if !found { return 0; }
  var exp = (p + 1) / 2;
  var x1 = a;
  var y1 = 1;
  var xr = 1;
  var yr = 0;
  while exp > 0 {
    if exp % 2 == 1 {
      var nx = _addmod(_mulmod(xr, x1, p), _mulmod(_mulmod(yr, y1, p), w2, p), p);
      var ny = _addmod(_mulmod(xr, y1, p), _mulmod(yr, x1, p), p);
      xr = nx;
      yr = ny;
    }
    var n1 = _addmod(_mulmod(x1, x1, p), _mulmod(_mulmod(y1, y1, p), w2, p), p);
    var n2 = _mulmod(_addmod(x1, x1, p), y1, p);
    x1 = n1;
    y1 = n2;
    exp = exp / 2;
  }
  if xr > p - xr { return p - xr; }
  return xr;
}

// ---------------------------------------------------------------------------
// Diophantine and symbols
// ---------------------------------------------------------------------------

// Cornacchia's algorithm: find integers x, y >= 0 with x^2 + d*y^2 = m. The
// parameter b is a square root of -d modulo m (the caller must supply one; for
// prime m this is sqrt(-d) mod m, e.g. via tonelli_shanks). Returns (0, 0)
// when d <= 0, when no representation exists, and on overflow (documented).
// Complexity: O(log^2 m).
pub fn cornacchia(d: Int, b: Int, m: Int) -> (Int, Int) {
  if d <= 0 { return (0, 0); }
  if m <= 1 { return (0, 0); }
  var a0 = m;
  var b0 = b % m;
  if b0 < 0 { b0 = b0 + m; }
  while b0 > m / b0 {
    var q = a0 / b0;
    var r1 = a0 - q * b0;
    a0 = b0;
    b0 = r1;
  }
  var x = b0;
  var rem = m - x * x;
  if rem % d != 0 { return (0, 0); }
  var y2 = rem / d;
  var y = math.roots.integer_sqrt(y2);
  if y * y != y2 { return (0, 0); }
  return (x, y);
}

// Local Hilbert symbol (a, b)_p over Q_p, returning 1 or -1. Uses the
// standard factorization: for odd p, (a,b)_p = (-1)^(alpha*beta) *
// (u/p)^beta * (v/p)^alpha with a = p^alpha * u, b = p^beta * v; for p == 2
// the explicit epsilon/omega formula is used. Returns 0 when a or b is 0 (the
// symbol is degenerate there, documented). Complexity: O(log_p |a| + log_p
// |b| + log p).
pub fn hilbert_symbol(a: Int, b: Int, p: Int) -> Int {
  if p <= 1 { return 1; }
  if a == 0 || b == 0 { return 0; }
  var aa = a;
  var bb = b;
  var alpha = 0;
  while aa % p == 0 {
    alpha = alpha + 1;
    aa = aa / p;
  }
  var beta = 0;
  while bb % p == 0 {
    beta = beta + 1;
    bb = bb / p;
  }
  var sign = 1;
  if p == 2 {
    var eu = _epsilon2(aa);
    var ev = _epsilon2(bb);
    var wu = _omega2(aa);
    var wv = _omega2(bb);
    var t = eu * ev + alpha * wv + beta * wu;
    if t % 2 != 0 { sign = -sign; }
    return sign;
  }
  if alpha % 2 != 0 && beta % 2 != 0 { sign = -sign; }
  if beta % 2 != 0 && math.number_theory.legendre_symbol(bb, p) == -1 { sign = -sign; }
  if alpha % 2 != 0 && math.number_theory.legendre_symbol(aa, p) == -1 { sign = -sign; }
  return sign;
}

// epsilon(x) = (x - 1)/2 mod 2 for odd x: 0 when x == 1 (mod 4), else 1.
fn _epsilon2(x: Int) -> Int {
  var r = x % 4;
  if r < 0 { r = r + 4; }
  if r == 1 { return 0; }
  return 1;
}

// omega(x) = (x^2 - 1)/8 mod 2 for odd x: 0 when x == 1 or 7 (mod 8), else 1.
fn _omega2(x: Int) -> Int {
  var r = x % 8;
  if r < 0 { r = r + 8; }
  if r == 1 || r == 7 { return 0; }
  return 1;
}

// Fast modular exponentiation base^exp mod m. Alias of
// xiom.math.arithmetic.pow_mod; returns 0 for m <= 0, m == 1 and exp < 0
// (documented). Complexity: O(log exp).
pub fn pow_mod_fast(base: Int, exp: Int, m: Int) -> Int {
  return math.arithmetic.pow_mod(base, exp, m);
}
