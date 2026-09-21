// XIOM - Conversion: Into
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.into

// Depends on: none

// ============================================================================
// Trait-style Into helpers for primitive conversions. into_str dispatches to
// the Display to_str implementation, which is exact for Int.
//
// NOTE: combining this module's numeric conversions with xiom.num.base (e.g.
// via xiom.convert.tostring) makes the compiler route Int<->Float64 through
// the Into interface and emit a buggy `Int.into` (clang: tower.Int.to_float
// called with an alloca pointer -- see the compiler-bug report). The to_float
// / to_int intrinsics are used directly here; users should avoid pulling
// xiom.num.base into the same program until the compiler bug is fixed.
// ============================================================================

/// Truncate a float toward zero to an integer.
/// Parameters: n -- the float value.
/// Returns: the truncated integer. Behavior for NaN/out-of-range input is
/// undefined (use the checked variants elsewhere).
/// Complexity: O(1).
pub fn into_int(n: Float64) -> Int {
  return to_int(n);
}

/// Widen an integer to a float (exact up to 2^53).
/// Parameters: n -- the integer value.
/// Returns: n widened to Float64.
/// Complexity: O(1).
pub fn into_float(n: Int) -> Float64 {
  return to_float(n);
}

/// Convert a generic value to a string via its Display to_str implementation.
/// Parameters: v -- the value to render.
/// Returns: the value's to_str() representation.
/// Complexity: O(1) for primitives.
pub fn into_str[T](v: T) -> Str {
  return v.to_str();
}
