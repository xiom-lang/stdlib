// XIOM - Conversion: TryFrom
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.tryfrom

// Depends on: xiom.convert.parse

// ============================================================================
// Trait-style TryFrom helpers that fail instead of losing information. The
// string parser delegates to xiom.convert.parse (different function name, so
// delegation is safe from the same-name miscompile); the numeric conversions
// are range-checked locally.
// ============================================================================

use xiom.convert;
use xiom.convert.parse;

/// Widen an integer to a float only when the conversion is lossless.
/// Parameters: n — the integer value.
/// Returns: Ok(Float64) when n fits exactly (|n| <= 2^53), Err otherwise.
/// Complexity: O(1).
pub fn try_from_int(n: Int) -> Result[Float64, Str] {
  var f = convert.int_to_float(n);
  var back = convert.float_to_int(f);
  if back == n {
    return Ok(f);
  }
  return Err("integer does not convert losslessly to a float");
}

/// Truncate a float to an integer only when the value fits an Int.
/// Parameters: f — the float value.
/// Returns: Ok(Int) for finite in-range values, Err for NaN or values
///          outside the Int range.
/// Complexity: O(1).
pub fn try_from_float(f: Float64) -> Result[Int, Str] {
  if f != f {
    return Err("cannot convert NaN to an integer");
  }
  if f >= 9223372036854775808.0 {
    return Err("float is out of integer range");
  }
  if f < -9223372036854775808.0 {
    return Err("float is out of integer range");
  }
  return Ok(convert.float_to_int(f));
}

/// Parse a string to an integer if valid.
/// Parameters: s — the decimal integer string (optional sign).
/// Returns: Ok(Int) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn try_from_str(s: Str) -> Result[Int, Str] {
  return parse.parse_int(s);
}
