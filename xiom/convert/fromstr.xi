// XIOM - Conversion: FromStr
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.fromstr

// Depends on: xiom.convert.parse

// ============================================================================
// FromStr-style parse helpers for primitive types. All functions delegate to
// the canonical xiom.convert.parse parsers (function names differ here, so
// delegation is safe from the same-name miscompile).
// ============================================================================

use xiom.convert.parse;

/// Parse a string as an integer.
/// Parameters: s -- the decimal integer string (optional sign).
/// Returns: Ok(Int) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn from_str_int(s: Str) -> Result[Int, Str] {
  return parse.parse_int(s);
}

/// Parse a string as a float.
/// Parameters: s -- the decimal float string (optional sign, '.', 'e'/'E').
/// Returns: Ok(Float64) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn from_str_float(s: Str) -> Result[Float64, Str] {
  return parse.parse_float(s);
}

/// Parse a string as a boolean.
/// Parameters: s -- the string.
/// Returns: Some(true) for "true", Some(false) for "false" (exact, case
///          sensitive), None otherwise.
/// Complexity: O(1).
pub fn from_str_bool(s: Str) -> Option[Bool] {
  return parse.parse_bool(s);
}
