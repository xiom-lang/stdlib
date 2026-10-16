// XIOM - Math: Integer Helpers
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.int

// Depends on: xiom.core only (this module is intentionally IMPORT-FREE so that
// fixed-point / ML / codec consumers can use it without pulling the xiom.math
// barrel and its extern-C libm surface).
//
// Wave-165 wishlist rows:
//   9  -- saturating Int add/sub/mul clamping at INT_MIN/INT_MAX.
//   10 -- pinned rounding helpers div_round (half away from zero) and
//         div_ceil (ceiling division, rounded toward +infinity) over signed
//         ints. NOTE: the intake sheet's parenthetical "(toward zero)" for
//         div_ceil conflicts with the name; the stdlib convention (see
//         xiom.num.i64_div_ceil) is ceiling division, which is what ships.
//   12 -- standalone Newton isqrt usable without the xiom.math barrel.
//
// Division by zero returns 0 (documented; same convention as xiom.num).
// The one unrepresentable quotient (INT_MIN / -1) saturates to INT_MAX.
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.

use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

/// a + b, clamping at INT_MAX/INT_MIN on overflow. Complexity: O(1).
pub fn saturating_add(a: Int, b: Int) -> Int
  ensures: (b == 0) => (result == a)
{
  if b > 0 && a > INT_MAX - b { return INT_MAX; }
  if b < 0 && a < INT_MIN - b { return INT_MIN; }
  return a + b;
}

/// a - b, clamping at INT_MAX/INT_MIN on overflow. Complexity: O(1).
pub fn saturating_sub(a: Int, b: Int) -> Int
  ensures: (b == 0) => (result == a)
{
  if b < 0 && a > INT_MAX + b { return INT_MAX; }
  if b > 0 && a < INT_MIN + b { return INT_MIN; }
  return a - b;
}

/// a * b, clamping at INT_MAX/INT_MIN on overflow. The one unrepresentable
/// product INT_MIN * -1 saturates to INT_MAX (documented, same as
/// xiom.num.i64_mul_sat). Complexity: O(1).
pub fn saturating_mul(a: Int, b: Int) -> Int
  ensures: (b == 1) => (result == a)
  ensures: (a == 0) || (b == 0) => (result == 0)
{
  if a == 0 || b == 0 { return 0; }
  if a == -1 {
    if b == INT_MIN { return INT_MAX; }
    return -b;
  }
  if b == -1 {
    if a == INT_MIN { return INT_MAX; }
    return -a;
  }
  if a > 0 && b > 0 && a > INT_MAX / b { return INT_MAX; }
  if a > 0 && b < 0 && b < INT_MIN / a { return INT_MIN; }
  if a < 0 && b > 0 && a < INT_MIN / b { return INT_MIN; }
  if a < 0 && b < 0 && a < INT_MAX / b { return INT_MAX; }
  return a * b;
}

// floor(|n| / d) for n >= 0, d > 0 via 127-step restoring long division.
// This deliberately does NOT use the `/` operator: the pinned compiler
// miscompiles a runtime `sdiv i128` that gets inlined into a function which
// also contains a vector element-load loop (AV 0xC0000005 at run time; see
// the wave-165 entry in tools/known_failures/README.md). Shift/mask forms
// lower cleanly. Domain: 0 <= n < 2^65, 0 < d <= 2^64 (all callers' ranges).
fn _divmod_pos(n: Int128, d: Int128) -> Int128 {
  var q: Int128 = 0;
  var r: Int128 = 0;
  var i = 126;
  while i >= 0 {
    r = r + r + ((n >> i) & (1 as Int128));
    var bit: Int128 = 0;
    if r >= d {
      r = r - d;
      bit = 1;
    }
    q = q + q + bit;
    i = i - 1;
  }
  return q;
}

/// a / b rounded to nearest, halves away from zero: div_round(5, 2) == 3,
/// div_round(-5, 2) == -3, div_round(1, 2) == 1, div_round(-1, 2) == -1.
/// Division by zero returns 0. The one unrepresentable quotient
/// (INT_MIN / -1 = +2^63) saturates to INT_MAX. Magnitude arithmetic in
/// 128 bits (shift-based long division, no hardware i128 division), so no
/// intermediate overflows. Complexity: O(1).
pub fn div_round(a: Int, b: Int) -> Int
  ensures: (b == 0) => (result == 0)
  ensures: (b == 1) => (result == a)
{
  if b == 0 { return 0; }
  if b == 1 { return a; }
  var neg = (a < 0) != (b < 0);
  var ma: Int128 = a as Int128;
  if ma < 0 { ma = 0 - ma; }
  var mb: Int128 = b as Int128;
  if mb < 0 { mb = 0 - mb; }
  // floor((2*|a| + |b|) / (2*|b|)) is round-half-up on magnitudes, i.e.
  // round-half-away-from-zero on the signed result.
  var q: Int128 = _divmod_pos(ma + ma + mb, mb + mb);
  var hi: Int128 = INT_MAX as Int128;
  var lo: Int128 = INT_MIN as Int128;
  if neg {
    q = 0 - q;
    if q < lo { return INT_MIN; }
    return q as Int;
  }
  if q > hi { return INT_MAX; }
  return q as Int;
}

/// a / b rounded toward +infinity (ceiling division): div_ceil(7, 2) == 4,
/// div_ceil(-7, 2) == -3, div_ceil(6, 2) == 3. Division by zero returns 0.
/// The one unrepresentable quotient (INT_MIN / -1) returns INT_MIN
/// (documented, same sentinel as xiom.num.i64_div_ceil).
/// Complexity: O(1).
pub fn div_ceil(a: Int, b: Int) -> Int
  ensures: (b == 0) => (result == 0)
  ensures: (b == 1) => (result == a)
{
  if b == 0 { return 0; }
  if b == 1 { return a; }
  if a == INT_MIN && b == -1 { return INT_MIN; }
  var q = a / b;
  var r = a % b;
  if r != 0 && (r < 0) == (b < 0) { q = q + 1; }
  return q;
}

/// Integer square root: the largest r >= 0 with r * r <= n.
/// isqrt(n) == 0 for n <= 0 (documented). Newton iteration seeded at
/// n / 2 + 1 (the seed is >= sqrt(n) for every n >= 4 and the update
/// x -> (x + n / x) / 2 never overflows Int); this is the standalone
/// integer sqrt usable without the xiom.math barrel. Complexity: O(log n).
pub fn isqrt(n: Int) -> Int
  ensures: (n <= 0) => (result == 0)
  ensures: result >= 0
  ensures: result * result <= n || n < 0
{
  if n <= 0 { return 0; }
  if n < 4 { return 1; }
  var x = n / 2 + 1;
  var y = (x + n / x) / 2;
  while y < x {
    x = y;
    y = (x + n / x) / 2;
  }
  return x;
}
