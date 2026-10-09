// XIOM - Conversion: ToString
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.tostring

// Depends on: none

// ============================================================================
// Formatting helpers for primitives as strings. The canonical Int formatter
// is xiom.convert.to_string (exposed on the parent module so `use
// xiom.convert;` resolves it); this module delegates to it and keeps the
// float/bool/char/radix helpers.
// ============================================================================

use xiom.string;
use xiom.convert;
use xiom.num.base;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Formats an integer as a decimal string. Exact for the full Int range
/// (including INT_MIN). Canonical implementation: `xiom.convert.to_string`;
/// this wrapper keeps the `xiom.convert.tostring` path working.
/// Complexity: O(log_10 |n|).
pub fn to_string(n: Int) -> Str
  ensures: (n == 0) => (result == "0")
{
  convert.to_string(n)
}

/// Formats a float as a string (15 significant digits, fixed or scientific,
/// handling "nan" and "inf"). Complexity: O(|exp10| + 15).
pub fn to_string_float(f: Float64) -> Str
  ensures: result.len() > 0
{
  convert.float_to_string(f)
}

/// Renders a boolean as "true" or "false". Complexity: O(1).
pub fn to_string_bool(b: Bool) -> Str
  ensures: ((b == true) => (result == "true")) && ((b == false) => (result == "false"))
{
  convert.bool_to_string(b)
}

/// Renders a character as a single-character UTF-8 string.
/// NOTE: U+0000 renders as "" -- the string backend truncates at a NUL byte
/// at construction time; every other code point yields a 1-4 byte string.
/// Complexity: O(1).
pub fn to_string_char(c: Char) -> Str
  ensures: (c != '\0') => (result.len() >= 1)
  ensures: (c == '\0') => (result.len() == 0)
{
  var tmp = Vec[UInt8].new();
  xiom.char.encode_utf8(c, &tmp);
  return Str::from_utf8(tmp);
}

/// Formats an integer in an arbitrary radix (2-36, lowercase digits).
/// Returns "" for an invalid radix. Complexity: O(log_radix |n|).
pub fn to_string_radix(n: Int, radix: Int) -> Str
  ensures: ((radix < 2 || radix > 36) => (result.len() == 0)) && ((radix >= 2 && radix <= 36) => (result.len() > 0))
{
  xiom.num.base.to_base(n, radix)
}
