// XIOM - Math: Precision
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.precision

// Depends on: none

// ============================================================================
// Generic type-level precision queries over numeric widths. Each generic pub
// fn delegates to a per-width `PrecisionLimits` impl; calling convention is
// explicit type application, e.g. `math.precision.epsilon[Float64]()`.
// Integer conventions: digits = decimal digits, mantissa_digits = magnitude
// bits (signed) or all bits (unsigned), exponent queries return 0 for
// integers (exact values carry no binary exponent), bit_width/byte_width are
// the storage sizes.
// ============================================================================

pub interface PrecisionLimits[T] {
  fn min_value() -> T;
  fn max_value() -> T;
  fn epsilon() -> T;
  fn digits() -> Int;
  fn mantissa_digits() -> Int;
  fn exponent_bias() -> Int;
  fn min_exponent() -> Int;
  fn max_exponent() -> Int;
  fn is_signed() -> Bool;
  fn bit_width() -> Int;
  fn byte_width() -> Int;
}

impl PrecisionLimits[Int] {
  fn min_value() -> Int { return -9223372036854775808; }
  fn max_value() -> Int { return 9223372036854775807; }
  fn epsilon() -> Int { return 1; }
  fn digits() -> Int { return 19; }
  fn mantissa_digits() -> Int { return 63; }
  fn exponent_bias() -> Int { return 0; }
  fn min_exponent() -> Int { return 0; }
  fn max_exponent() -> Int { return 0; }
  fn is_signed() -> Bool { return true; }
  fn bit_width() -> Int { return 64; }
  fn byte_width() -> Int { return 8; }
}

impl PrecisionLimits[Int32] {
  fn min_value() -> Int32 { return (-2147483648) as Int32; }
  fn max_value() -> Int32 { return 2147483647 as Int32; }
  fn epsilon() -> Int32 { return 1 as Int32; }
  fn digits() -> Int { return 10; }
  fn mantissa_digits() -> Int { return 31; }
  fn exponent_bias() -> Int { return 0; }
  fn min_exponent() -> Int { return 0; }
  fn max_exponent() -> Int { return 0; }
  fn is_signed() -> Bool { return true; }
  fn bit_width() -> Int { return 32; }
  fn byte_width() -> Int { return 4; }
}

impl PrecisionLimits[Int64] {
  fn min_value() -> Int64 { return (-9223372036854775808) as Int64; }
  fn max_value() -> Int64 { return 9223372036854775807 as Int64; }
  fn epsilon() -> Int64 { return 1 as Int64; }
  fn digits() -> Int { return 19; }
  fn mantissa_digits() -> Int { return 63; }
  fn exponent_bias() -> Int { return 0; }
  fn min_exponent() -> Int { return 0; }
  fn max_exponent() -> Int { return 0; }
  fn is_signed() -> Bool { return true; }
  fn bit_width() -> Int { return 64; }
  fn byte_width() -> Int { return 8; }
}

impl PrecisionLimits[UInt64] {
  fn min_value() -> UInt64 { return 0 as UInt64; }
  fn max_value() -> UInt64 {
    var m = (9223372036854775807 as UInt64) * 2;
    return m + 1;
  }
  fn epsilon() -> UInt64 { return 1 as UInt64; }
  fn digits() -> Int { return 20; }
  fn mantissa_digits() -> Int { return 64; }
  fn exponent_bias() -> Int { return 0; }
  fn min_exponent() -> Int { return 0; }
  fn max_exponent() -> Int { return 0; }
  fn is_signed() -> Bool { return false; }
  fn bit_width() -> Int { return 64; }
  fn byte_width() -> Int { return 8; }
}

impl PrecisionLimits[Float32] {
  fn min_value() -> Float32 { return (-3.4028234663852886e38) as Float32; }
  fn max_value() -> Float32 { return 3.4028234663852886e38 as Float32; }
  fn epsilon() -> Float32 { return 1.1920928955078125e-07 as Float32; }
  fn digits() -> Int { return 6; }
  fn mantissa_digits() -> Int { return 24; }
  fn exponent_bias() -> Int { return 127; }
  fn min_exponent() -> Int { return -126; }
  fn max_exponent() -> Int { return 127; }
  fn is_signed() -> Bool { return true; }
  fn bit_width() -> Int { return 32; }
  fn byte_width() -> Int { return 4; }
}

impl PrecisionLimits[Float64] {
  fn min_value() -> Float64 { return -1.7976931348623157e308; }
  fn max_value() -> Float64 { return 1.7976931348623157e308; }
  fn epsilon() -> Float64 { return 2.220446049250313e-16; }
  fn digits() -> Int { return 15; }
  fn mantissa_digits() -> Int { return 53; }
  fn exponent_bias() -> Int { return 1023; }
  fn min_exponent() -> Int { return -1022; }
  fn max_exponent() -> Int { return 1023; }
  fn is_signed() -> Bool { return true; }
  fn bit_width() -> Int { return 64; }
  fn byte_width() -> Int { return 8; }
}

// Smallest finite value representable by T.
pub fn min_value[T: PrecisionLimits]() -> T {
  return PrecisionLimits[T].min_value();
}

// Largest finite value representable by T.
pub fn max_value[T: PrecisionLimits]() -> T {
  return PrecisionLimits[T].max_value();
}

// Machine epsilon of T: smallest x such that 1 + x != 1.
pub fn epsilon[T: PrecisionLimits]() -> T {
  return PrecisionLimits[T].epsilon();
}

// Number of significant decimal digits (floats) or decimal digits (integers).
pub fn digits[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].digits();
}

// Number of bits in the significand of T (magnitude bits for integers).
pub fn mantissa_digits[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].mantissa_digits();
}

// Exponent bias of T (floats); 0 for integers.
pub fn exponent_bias[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].exponent_bias();
}

// Minimum binary exponent of T (floats); 0 for integers.
pub fn min_exponent[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].min_exponent();
}

// Maximum binary exponent of T (floats); 0 for integers.
pub fn max_exponent[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].max_exponent();
}

// True iff T can represent negative values.
pub fn is_signed[T: PrecisionLimits]() -> Bool {
  return PrecisionLimits[T].is_signed();
}

// Number of bits in a value of T.
pub fn bit_width[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].bit_width();
}

// Number of bytes in a value of T.
pub fn byte_width[T: PrecisionLimits]() -> Int {
  return PrecisionLimits[T].byte_width();
}
