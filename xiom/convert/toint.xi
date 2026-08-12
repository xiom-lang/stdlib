// XIOM - Conversion: ToInt
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.toint

// Depends on: none

// ============================================================================
// Float-to-int conversion strategies (truncating, saturating, checked).
// `to_int` shadows the core intrinsic within this module only; the saturating
// variant delegates to the canonical xiom.num.f64_trunc_to_int (different
// function name, so delegation is safe from the same-name miscompile).
// ============================================================================

use xiom.num;

/// Truncates a float toward zero. Behavior for NaN and out-of-range values is
/// undefined (use the checked/saturating variants for those inputs).
/// Complexity: O(1).
pub fn to_int(n: Float64) -> Int {
  n as Int
}

/// Truncates a float toward zero, clamping to INT_MAX/INT_MIN on overflow.
/// NaN yields 0. Complexity: O(1).
pub fn to_int_saturating(f: Float64) -> Int {
  num.f64_trunc_to_int(f)
}

/// Truncates a float toward zero only when the result fits an Int. Returns
/// None for NaN or values outside [INT_MIN, INT_MAX). Complexity: O(1).
pub fn to_int_checked(f: Float64) -> Option[Int] {
  if f != f {
    return None;
  };
  if f >= 9223372036854775808.0 {
    return None;
  };
  if f < -9223372036854775808.0 {
    return None;
  };
  Some(f as Int)
}

/// Returns a character's code point as an integer.
/// Complexity: O(1).
pub fn to_int_from_char(c: Char) -> Int {
  c as Int
}
