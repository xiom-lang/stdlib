// XIOM - Math: Arithmetic
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.arithmetic

// Depends on: xiom.math

use xiom.math;

// ============================================================================
// Integer arithmetic and number-theoretic helpers (concrete Int).
// Division conventions follow xiom.num (i64_div_floor etc.): native Int
// division truncates toward zero, `%` follows the dividend sign; the floor /
// ceil / mod variants adjust from that baseline. Division by zero returns 0
// (documented); the unrepresentable INT_MIN / -1 returns INT_MIN.
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so documented graceful fallbacks (div-by-zero, etc.)
// are guarded inside the body instead of declared as contracts.
// ============================================================================

// Greatest common divisor of a and b; always non-negative. gcd(0, 0) == 0.
// The one unrepresentable case gcd(INT_MIN, k) = 2^63 saturates to INT_MAX
// (documented). Complexity: O(log min(|a|,|b|)).
/// Greatest common divisor of a and b; always non-negative. gcd(0, 0) == 0.
/// The one unrepresentable case gcd(INT_MIN, k) = 2^63 saturates to INT_MAX
/// (documented). Complexity: O(log min(|a|,|b|)).
pub fn gcd(a: Int, b: Int) -> Int
  ensures: result >= 0
{
  // Work with negative magnitudes so INT_MIN never overflows on negation.
  var x = a;
  if x > 0 { x = -x; }
  var y = b;
  if y > 0 { y = -y; }
  while y != 0 {
    var t = x % y;
    x = y;
    y = t;
  }
  if x == -9223372036854775808 { return 9223372036854775807; }
  return -x;
}

// Least common multiple of |a| and |b|; always non-negative. 0 when either
// input is 0, and 0 (documented overflow) when the true lcm exceeds Int
// range. Complexity: O(gcd).
/// Least common multiple of |a| and |b|; always non-negative. 0 when either
/// input is 0, and 0 (documented overflow) when the true lcm exceeds Int
/// range. Complexity: O(gcd).
pub fn lcm(a: Int, b: Int) -> Int {
  if a == 0 || b == 0 { return 0; }
  var g = gcd(a, b);
  var x = a / g;
  var y = b;
  if x == -9223372036854775808 || y == -9223372036854775808 { return 0; }
  var ux = x;
  if ux < 0 { ux = -ux; }
  var uy = y;
  if uy < 0 { uy = -uy; }
  if ux > 9223372036854775807 / uy { return 0; }
  return ux * uy;
}

// True iff n is a positive power of two. is_power_of_two(0) == false,
// is_power_of_two(1) == true. Complexity: O(log n).
/// True iff n is a positive power of two. is_power_of_two(0) == false,
/// is_power_of_two(1) == true. Complexity: O(log n).
pub fn is_power_of_two(n: Int) -> Bool {
  if n <= 0 { return false; }
  var x = n;
  while x > 1 {
    if x % 2 != 0 { return false; }
    x = x / 2;
  }
  return true;
}

// Smallest power of two >= n. Returns 1 for n <= 0. When the next power of
// two would exceed Int range (n > 2^62) returns 0 (documented overflow).
// Complexity: O(log n).
/// Smallest power of two >= n. Returns 1 for n <= 0. When the next power of
/// two would exceed Int range (n > 2^62) returns 0 (documented overflow).
/// Complexity: O(log n).
pub fn next_power_of_two(n: Int) -> Int {
  if n <= 0 { return 1; }
  if n == 1 { return 1; }
  var p = 1;
  while p < n {
    if p >= 4611686018427387904 { return 0; }
    p = p * 2;
  }
  return p;
}

// Largest power of two <= n. Returns 0 for n <= 0 (no positive power fits).
// Complexity: O(log n).
/// Largest power of two <= n. Returns 0 for n <= 0 (no positive power fits).
/// Complexity: O(log n).
pub fn prev_power_of_two(n: Int) -> Int {
  if n <= 0 { return 0; }
  var p = 1;
  while p <= n / 2 {
    p = p * 2;
  }
  return p;
}

// Extended Euclid: returns (g, x, y) with a*x + b*y == g == gcd(a, b).
// g is non-negative. For a == b == 0 returns (0, 1, 0). Complexity: O(log).
/// Extended Euclid: returns (g, x, y) with a*x + b*y == g == gcd(a, b).
/// g is non-negative. For a == b == 0 returns (0, 1, 0). Complexity: O(log).
pub fn gcd_extended(a: Int, b: Int) -> (Int, Int, Int) {
  var old_r = a;
  var r = b;
  var old_s = 1;
  var s = 0;
  var old_t = 0;
  var t = 1;
  while r != 0 {
    var q = old_r / r;
    var new_r = old_r - q * r;
    var new_s = old_s - q * s;
    var new_t = old_t - q * t;
    old_r = r;
    r = new_r;
    old_s = s;
    s = new_s;
    old_t = t;
    t = new_t;
  }
  if old_r < 0 {
    return (-old_r, -old_s, -old_t);
  }
  return (old_r, old_s, old_t);
}

// Multiplicative inverse of a mod m: x with (a * x) % m == 1. Returns None
// when gcd(a, m) != 1 (no inverse exists), when m == 0 (no modulus), and
// Some(0) for m == 1 (everything is 0 mod 1). Complexity: O(log min(a, m)).
/// Multiplicative inverse of a mod m: x with (a * x) % m == 1. Returns None
/// when gcd(a, m) != 1 (no inverse exists), when m == 0 (no modulus), and
/// Some(0) for m == 1 (everything is 0 mod 1). Complexity: O(log min(a, m)).
pub fn mod_inverse(a: Int, m: Int) -> Option[Int] {
  if m == 0 { return None; }
  if m == 1 { return Some(0); }
  var old_r = a % m;
  if old_r < 0 { old_r = old_r + m; }
  var r = m;
  var old_s = 1;
  var s = 0;
  while r != 0 {
    var q = old_r / r;
    var new_r = old_r - q * r;
    var new_s = old_s - q * s;
    old_r = r;
    r = new_r;
    old_s = s;
    s = new_s;
  }
  if old_r != 1 { return None; }
  var result = old_s % m;
  if result < 0 { result = result + m; }
  return Some(result);
}

// base^exp mod m via exponentiation by squaring. Result in [0, m).
// exp < 0 returns 0 (documented; only non-negative exponents are supported),
// m == 1 returns 0, m == 0 returns 0 (documented, division by zero guard).
// Complexity: O(log exp).
/// base^exp mod m via exponentiation by squaring. Result in [0, m).
/// exp < 0 returns 0 (documented; only non-negative exponents are supported),
/// m == 1 returns 0, m == 0 returns 0 (documented, division by zero guard).
/// Complexity: O(log exp).
pub fn pow_mod(base: Int, exp: Int, m: Int) -> Int {
  if m == 0 { return 0; }
  if m == 1 { return 0; }
  if exp < 0 { return 0; }
  var result = 1;
  var b = base % m;
  if b < 0 { b = b + m; }
  var e = exp;
  while e > 0 {
    if e % 2 == 1 {
      result = (result * b) % m;
    }
    b = (b * b) % m;
    e = e / 2;
  }
  if result < 0 { result = result + m; }
  return result;
}

// True iff n is odd (sign-aware: -3 is odd).
/// True iff n is odd (sign-aware: -3 is odd).
pub fn is_odd(n: Int) -> Bool {
  return n % 2 != 0;
}

// True iff n is even (sign-aware: -4 is even).
/// True iff n is even (sign-aware: -4 is even).
pub fn is_even(n: Int) -> Bool {
  return n % 2 == 0;
}

// Integer division rounded toward positive infinity (ceiling).
// ceil(-7, 2) == -3. Division by zero returns 0; INT_MIN / -1 returns
// INT_MIN (unrepresentable +2^63). Complexity: O(1).
/// Integer division rounded toward positive infinity (ceiling).
/// ceil(-7, 2) == -3. Division by zero returns 0; INT_MIN / -1 returns
/// INT_MIN (unrepresentable +2^63). Complexity: O(1).
pub fn div_ceil(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == -9223372036854775808 && b == -1 { return -9223372036854775808; }
  var q = a / b;
  var r = a % b;
  if r != 0 && (r < 0) == (b < 0) { q = q + 1; }
  return q;
}

// Integer division rounded toward negative infinity (floor).
// floor(-7, 2) == -4. Division by zero returns 0; INT_MIN / -1 returns
// INT_MIN. Complexity: O(1).
/// Integer division rounded toward negative infinity (floor).
/// floor(-7, 2) == -4. Division by zero returns 0; INT_MIN / -1 returns
/// INT_MIN. Complexity: O(1).
pub fn div_floor(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == -9223372036854775808 && b == -1 { return -9223372036854775808; }
  var q = a / b;
  var r = a % b;
  if r != 0 && (r < 0) != (b < 0) { q = q - 1; }
  return q;
}

// Integer division truncated toward zero (native semantics).
// trunc(-7, 2) == -3. Division by zero returns 0; INT_MIN / -1 returns
// INT_MIN. Complexity: O(1).
/// Integer division truncated toward zero (native semantics).
/// trunc(-7, 2) == -3. Division by zero returns 0; INT_MIN / -1 returns
/// INT_MIN. Complexity: O(1).
pub fn div_trunc(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  if a == -9223372036854775808 && b == -1 { return -9223372036854775808; }
  return a / b;
}

// Modulus with result matching the divisor sign. mod_floor(-7, 2) == 1,
// mod_floor(7, -2) == -1. Division by zero returns 0. Complexity: O(1).
/// Modulus with result matching the divisor sign. mod_floor(-7, 2) == 1,
/// mod_floor(7, -2) == -1. Division by zero returns 0. Complexity: O(1).
pub fn mod_floor(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  var r = a % b;
  if r != 0 && (r < 0) != (b < 0) { r = r + b; }
  return r;
}

// Modulus with result matching the dividend sign (native semantics).
// mod_trunc(-7, 2) == -1, mod_trunc(7, -2) == 1. Division by zero returns 0.
// Complexity: O(1).
/// Modulus with result matching the dividend sign (native semantics).
/// mod_trunc(-7, 2) == -1, mod_trunc(7, -2) == 1. Division by zero returns 0.
/// Complexity: O(1).
pub fn mod_trunc(a: Int, b: Int) -> Int {
  if b == 0 { return 0; }
  return a % b;
}
