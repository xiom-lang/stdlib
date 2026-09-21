// XIOM - Conversion: From
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.from

// Depends on: xiom.convert

// ============================================================================
// Trait-style From helpers for primitive conversions. Numeric conversions
// delegate to the canonical xiom.convert functions (different names here, so
// delegation is safe from the same-name miscompile) -- this also avoids
// emitting duplicate tower.Int.to_float conversions, which clash with the
// core Into impl when combined in one program (BUG 25 family).
// ============================================================================

use xiom.convert;

/// Widen an integer to a float (exact up to 2^53).
/// Parameters: n -- the integer value.
/// Returns: n widened to Float64.
/// Complexity: O(1).
pub fn from_int(n: Int) -> Float64 {
  return convert.int_to_float(n);
}

/// Truncate a float toward zero to an integer.
/// Parameters: f -- the float value.
/// Returns: the truncated integer. Behavior for NaN/out-of-range input is
/// undefined (use the checked variants elsewhere).
/// Complexity: O(1).
pub fn from_float(f: Float64) -> Int {
  return convert.float_to_int(f);
}

/// Return a character's code point as an integer.
/// Parameters: c -- the character.
/// Returns: the Unicode code point of c.
/// Complexity: O(1).
pub fn from_char(c: Char) -> Int {
  return to_int_from_char(c);
}

/// Render a boolean as 0 or 1.
/// Parameters: b -- the boolean.
/// Returns: 1 when true, 0 when false.
/// Complexity: O(1).
pub fn from_bool(b: Bool) -> Int {
  if b {
    return 1;
  }
  return 0;
}
