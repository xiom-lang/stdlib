// XIOM - Conversion: Exact
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.exact

// Depends on: xiom.num

// ============================================================================
// Exact arithmetic helpers that fail when a result is not representable.
// Integer division requires an exact quotient; float division requires the
// quotient to round-trip; ratios are reduced to lowest terms.
// ============================================================================

use xiom.num;
use xiom.core.INT_MIN;

/// a / b, returning Err on division by zero, the INT_MIN / -1 overflow, or a
/// non-exact quotient. Complexity: O(1).
pub fn exact_div(a: Int, b: Int) -> Result[Int, Str] {
  if b == 0 {
    return Err("division by zero");
  };
  if a == INT_MIN && b == -1 {
    return Err("division overflow");
  };
  if a % b != 0 {
    return Err("division is not exact");
  };
  Ok(a / b)
}

/// a / b in IEEE arithmetic, returning None on division by zero or when the
/// quotient does not round-trip (q * b != a), i.e. when the division lost
/// precision. Complexity: O(1).
pub fn exact_float(a: Float64, b: Float64) -> Option[Float64] {
  if b == 0.0 {
    return None;
  };
  var q = a / b;
  if q * b != a {
    return None;
  };
  Some(q)
}

/// Reduces a/b to lowest terms as (numerator, denominator) with a positive
/// denominator. Returns None on division by zero. Complexity: O(log max|a,b|).
pub fn exact_ratio(a: Int, b: Int) -> Option[(Int, Int)] {
  if b == 0 {
    return None;
  };
  var g = num.gcd(a, b);
  if g < 0 {
    g = 0 - g;
  };
  var num = a / g;
  var den = b / g;
  if den < 0 {
    num = 0 - num;
    den = 0 - den;
  };
  Some((num, den))
}
