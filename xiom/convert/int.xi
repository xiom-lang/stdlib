// XIOM - Conversion: Int
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.int

// Depends on: xiom.string, xiom.convert.parse

// ============================================================================
// Integer/string and integer/base formatting and parsing. Decimal formatting
// is implemented locally (exact for INT_MIN); radix parsing delegates to
// xiom.convert.parse (different function name, so delegation is safe from the
// same-name miscompile).
//
// NOTE: the canonical xiom.convert.tostring is deliberately NOT imported —
// it pulls xiom.num.base, whose Int<->Float64 towers force the compiler to
// route conversions through the Into interface and emit a buggy `Int.into`
// (clang: tower.Int.to_float called with an alloca pointer). Local
// reimplementation avoids that entirely.
// ============================================================================

use xiom.string;
use xiom.convert.parse;

/// Format an integer as a decimal string. Exact for the full Int range
/// (including INT_MIN).
/// Parameters: n — the integer value.
/// Returns: the decimal representation.
/// Complexity: O(log_10 |n|).
pub fn int_to_string(n: Int) -> Str {
  if n == 0 {
    return "0";
  }
  var x = n;
  var neg = false;
  if x < 0 {
    neg = true;
  }
  if x > 0 {
    x = 0 - x;
  }
  var digits = Vec[Int].new();
  while x != 0 {
    var d = x % 10;
    if d < 0 {
      d = 0 - d;
    }
    digits.push(d);
    x = x / 10;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, string.str_slice("0123456789", d, d + 1));
    i = i - 1;
  }
  return result;
}

/// Parse a decimal string to an integer.
/// Parameters: s — the decimal integer string (optional sign).
/// Returns: Ok(Int) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn string_to_int(s: Str) -> Result[Int, Str] {
  return parse.parse_int(s);
}

/// Format an integer in an arbitrary base (2-36, lowercase digits).
/// Parameters: n — the integer value; base — the radix.
/// Returns: the base representation; "" for an invalid radix.
/// Complexity: O(log_base |n|).
pub fn int_to_base(n: Int, base: Int) -> Str {
  if base < 2 || base > 36 {
    return "";
  }
  if n == 0 {
    return "0";
  }
  var neg = false;
  var x = n;
  if x < 0 {
    neg = true;
  }
  if x > 0 {
    x = 0 - x;
  }
  var digits = Vec[Int].new();
  while x != 0 {
    var d = x % base;
    if d < 0 {
      d = 0 - d;
    }
    digits.push(d);
    x = x / base;
  }
  var result = "";
  if neg {
    result = "-";
  }
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, _digit_char(d));
    i = i - 1;
  }
  return result;
}

/// Parse an integer string in an arbitrary base (2-36, both digit cases).
/// Parameters: s — the digit string (optional sign); base — the radix.
/// Returns: Ok(Int) for well-formed input, Err for an invalid radix, an
///          empty string, an out-of-range digit, or overflow.
/// Complexity: O(n), n = string length.
pub fn base_to_int(s: Str, base: Int) -> Result[Int, Str] {
  return parse.parse_int_radix(s, base);
}

/// Format an integer as a lowercase hexadecimal string.
/// Parameters: n — the integer value.
/// Returns: the hexadecimal representation ("0" for zero).
/// Complexity: O(log_16 |n|).
pub fn int_to_hex(n: Int) -> Str {
  return int_to_base(n, 16);
}

/// Parse a hexadecimal string to an integer.
/// Parameters: s — the hex digit string (both digit cases accepted).
/// Returns: Ok(Int) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn int_from_hex(s: Str) -> Result[Int, Str] {
  return parse.parse_int_radix(s, 16);
}

/// Format an integer as a lowercase octal string.
/// Parameters: n — the integer value.
/// Returns: the octal representation ("0" for zero).
/// Complexity: O(log_8 |n|).
pub fn int_to_octal(n: Int) -> Str {
  return int_to_base(n, 8);
}

/// Format an integer as a binary string.
/// Parameters: n — the integer value.
/// Returns: the binary representation ("0" for zero).
/// Complexity: O(log_2 |n|).
pub fn int_to_binary(n: Int) -> Str {
  return int_to_base(n, 2);
}

// Map a base-2..36 digit value to its lowercase character.
fn _digit_char(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("abcdefghijklmnopqrstuvwxyz", d - 10, d - 9);
}
