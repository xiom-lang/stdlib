// XIOM - Num: Fraction
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.num.fraction

// Depends on: none

// ============================================================================
// Exact rational numbers: construction, arithmetic, reduction, comparison.
// INVARIANT: every Fraction has den > 0 and gcd(|num|, den) == 1. Every
// construction path (fraction_new, fraction_reduce, all arithmetic) routes
// through fraction_new, so the invariant holds by induction.
// NOTE: cross-multiplication can overflow i64 for very large operands; the
// gcd-based pre-reduction below minimizes that risk (documented per fn).
// ============================================================================

use xiom.core.to_string;

/// A rational number num/den with den > 0, always in lowest terms.
pub type Fraction = { num: Int; den: Int; }

/// Greatest common divisor of |a| and |b| (Euclid). gcd(0,0) == 0.
/// Complexity: O(log max(|a|,|b|)).
fn _gcd(a: Int, b: Int) -> Int {
  var x = a;
  if x < 0 { x = -x; }
  var y = b;
  if y < 0 { y = -y; }
  while y != 0 {
    var r = x % y;
    x = y;
    y = r;
  }
  x
}

/// Truncation toward zero of a Float64 in [0, 2^63) -- equals floor there.
/// Callers guarantee the range (the cast is undefined outside i64).
fn _floor_nonneg(x: Float64) -> Int {
  x as Int
}

/// Constructs a reduced fraction from num/den, normalizing the sign to the
/// denominator. den == 0 returns the zero fraction 0/1 (documented fallback
/// for the requires-clause violation). Result satisfies the module invariant.
/// Complexity: O(log max(|num|,|den|)).
pub fn fraction_new(num: Int, den: Int) -> Fraction
  requires: den != 0
  ensures:  result.den > 0
{
  if den == 0 {
    return Fraction{ num: 0; den: 1; };
  }
  var g = _gcd(num, den);
  if g == 0 { g = 1; }
  var n = num / g;
  var d = den / g;
  if d < 0 {
    n = -n;
    d = -d;
  }
  Fraction{ num: n; den: d; }
}

/// Best rational approximation of f via continued-fraction convergents.
/// The first convergent that would overflow i64 (or the first exact one) is
/// returned. Zero, NaN, and infinities map to 0/1 (documented). |f| must be
/// < 2^63 for the floor cast; larger magnitudes return the current convergent.
/// Complexity: O(log |f|) iterations.
pub fn fraction_from_float(f: Float64) -> Fraction {
  // IEEE NaN guard (x != x); NaN/inf map to 0/1 (documented).
  if f != f { return Fraction{ num: 0; den: 1; }; }
  if f == 1.0 / 0.0 || f == -1.0 / 0.0 { return Fraction{ num: 0; den: 1; }; }
  if f == 0.0 { return Fraction{ num: 0; den: 1; }; }
  var neg = f < 0.0;
  var x = f;
  if neg { x = -x; }
  // Continued-fraction convergents h_i/k_i of x. h0/h1, k0/k1 are the two
  // most recent convergents; the next is h2 = a*h1 + h0.
  var h0 = 0;
  var h1 = 1;
  var k0 = 1;
  var k1 = 0;
  var guard = 0;
  while guard < 64 {
    if x >= 9223372036854775808.0 { break; }
    var a = _floor_nonneg(x);
    // Overflow guards for h2 = a*h1 + h0 and k2 = a*k1 + k0. The guards are
    // only needed when the coefficient (h1 / k1) is non-zero; after a first
    // partial quotient of 0, h1 (or k1) is 0 and h2 == h0 fits by induction.
    // Nested ifs (not &&) because the compiler mis-compiles a short-circuit
    // whose right operand divides by a possibly-zero value.
    if h1 != 0 {
      if a > (9223372036854775807 - h0) / h1 { break; }
    }
    if k1 != 0 {
      if a > (9223372036854775807 - k0) / k1 { break; }
    }
    var h2 = a * h1 + h0;
    var k2 = a * k1 + k0;
    h0 = h1;
    h1 = h2;
    k0 = k1;
    k1 = k2;
    var frac = x - (a as Float64);
    if frac == 0.0 { break; }
    x = 1.0 / frac;
    guard = guard + 1;
  }
  var n = h1;
  if neg { n = -n; }
  Fraction{ num: n; den: k1; }
}

/// a + b. Pre-reduces by gcd(a.den, b.den) to limit overflow; the result is
/// re-reduced. Cross-products may still overflow i64 for very large
/// denominators (documented). Complexity: O(log max(a.den, b.den)).
pub fn fraction_add(a: Fraction, b: Fraction) -> Fraction {
  var g = _gcd(a.den, b.den);
  if g == 0 { g = 1; }
  var num = a.num * (b.den / g) + b.num * (a.den / g);
  var den = (a.den / g) * b.den;
  fraction_new(num, den)
}

/// a - b. Complexity: O(log max(a.den, b.den)).
pub fn fraction_sub(a: Fraction, b: Fraction) -> Fraction {
  var nb = Fraction{ num: -b.num; den: b.den; };
  fraction_add(a, nb)
}

/// a * b. Cross-cancels via gcd before multiplying, minimizing overflow.
/// Complexity: O(log max(|num|, den)).
pub fn fraction_mul(a: Fraction, b: Fraction) -> Fraction {
  var g1 = _gcd(a.num, b.den);
  if g1 == 0 { g1 = 1; }
  var g2 = _gcd(b.num, a.den);
  if g2 == 0 { g2 = 1; }
  var num = (a.num / g1) * (b.num / g2);
  var den = (a.den / g2) * (b.den / g1);
  fraction_new(num, den)
}

/// a / b as a / (b^-1). None when b is zero (no silent division by zero).
/// Complexity: O(log max(|num|, den)).
pub fn fraction_div(a: Fraction, b: Fraction) -> Option[Fraction] {
  if b.num == 0 { return None; }
  var r = Fraction{ num: b.den; den: b.num; };
  Some(fraction_mul(a, r))
}

/// Reduces f to lowest terms with a positive denominator. Identity when f
/// already satisfies the module invariant. Complexity: O(log max(|num|,|den|)).
pub fn fraction_reduce(f: Fraction) -> Fraction {
  fraction_new(f.num, f.den)
}

/// Converts to Float64 (numerator / denominator division). A zero denominator
/// (invariant violation) returns 0.0 (documented). Complexity: O(1).
pub fn fraction_to_float(f: Fraction) -> Float64 {
  if f.den == 0 { return 0.0; }
  (f.num as Float64) / (f.den as Float64)
}

/// Renders as "num/den". Complexity: O(1) string building.
pub fn fraction_to_str(f: Fraction) -> Str {
  to_string(f.num) + "/" + to_string(f.den)
}

/// Returns true iff the numerator is zero. Complexity: O(1).
pub fn fraction_is_zero(f: Fraction) -> Bool {
  f.num == 0
}

/// Three-way comparison via gcd-reduced cross-multiplication: -1, 0, or 1.
/// Valid because denominators are positive. Cross-products can overflow i64
/// for large fractions (documented). Complexity: O(log max(den)).
pub fn fraction_compare(a: Fraction, b: Fraction) -> Int {
  var g = _gcd(a.den, b.den);
  if g == 0 { g = 1; }
  var lhs = a.num * (b.den / g);
  var rhs = b.num * (a.den / g);
  if lhs < rhs { return -1; }
  if lhs > rhs { return 1; }
  0
}
