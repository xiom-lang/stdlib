// XIOM - Conversion: Parse
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.parse

// Depends on: none

// ============================================================================
// String parsing helpers for primitive types. Implemented here directly: the
// core `to_int_from_str`/`to_float_from_str` paths are unreliable (Char range
// comparisons miscompile -- see the module header of xiom.convert.lossy), and
// the same-named xiom.num helpers cannot be imported without triggering the
// same-name delegation miscompile (see xiom.convert.base58).
// ============================================================================

use xiom.string;
use xiom.core.INT_MAX;

/// Parses a decimal integer string. An optional leading '-'/'+' is accepted.
/// Returns Err on an empty string, an invalid character, or overflow.
/// Complexity: O(n), n = string length.
pub fn parse_int(s: Str) -> Result[Int, Str] {
  _parse_int_radix(s, 10)
}

/// Parses an integer string in the given radix (2-36, both digit cases
/// accepted). An optional leading '-'/'+' is accepted. Returns Err on an
/// invalid radix, an empty string, an invalid digit, a digit out of range
/// for the radix, or overflow. Complexity: O(n), n = string length.
pub fn parse_int_radix(s: Str, radix: Int) -> Result[Int, Str] {
  if radix < 2 || radix > 36 {
    return Err("invalid radix");
  };
  _parse_int_radix(s, radix)
}

/// Shared radix parser (radix pre-validated by the caller).
fn _parse_int_radix(s: Str, radix: Int) -> Result[Int, Str] {
  let len = s.len();
  if len == 0 {
    return Err("empty string");
  };
  var i: Int = 0;
  var negative = false;
  var first = string.byte_at(s, 0);
  if first == 45 {
    negative = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= len {
    return Err("no digits");
  };
  var result: Int = 0;
  while i < len {
    var digit = _digit_value(string.byte_at(s, i));
    if digit < 0 {
      return Err("invalid digit");
    };
    if digit >= radix {
      return Err("digit out of range for radix");
    };
    if result > (INT_MAX - digit) / radix {
      return Err("overflow");
    };
    result = result * radix + digit;
    i = i + 1;
  };
  if negative {
    result = -result;
  };
  Ok(result)
}

/// Numeric value of a digit byte (0-9, a-z, A-Z); -1 otherwise.
fn _digit_value(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 48 && code <= 57 { return code - 48; }
  if code >= 97 && code <= 122 { return code - 87; }
  if code >= 65 && code <= 90 { return code - 55; }
  -1
}

/// Parses a floating-point string. Supports an optional sign, a decimal
/// point, and an 'e'/'E' exponent. Returns Err on empty input, missing
/// digits, invalid characters, multiple decimal points, or a malformed
/// exponent. Complexity: O(n), n = string length.
pub fn parse_float(s: Str) -> Result[Float64, Str] {
  let len = s.len();
  if len == 0 {
    return Err("empty string");
  };
  var i: Int = 0;
  var negative = false;
  var first = string.byte_at(s, 0);
  if first == 45 {
    negative = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= len {
    return Err("no digits");
  };
  var int_part: Float64 = 0.0;
  var frac_part: Float64 = 0.0;
  var frac_div: Float64 = 10.0;
  var has_frac = false;
  var has_digit = false;
  while i < len {
    var b = string.byte_at(s, i) as Int;
    b = b & 0xFF;
    if b == 46 {
      if has_frac {
        return Err("multiple decimal points");
      };
      has_frac = true;
      i = i + 1;
      continue;
    };
    if b == 101 || b == 69 {
      i = i + 1;
      var exp_negative = false;
      if i < len {
        var ec = string.byte_at(s, i);
        if ec == 45 {
          exp_negative = true;
          i = i + 1;
        } elif ec == 43 {
          i = i + 1;
        };
      };
      var exp_val: Int = 0;
      var exp_ok = false;
      while i < len {
        var eb = string.byte_at(s, i) as Int;
        eb = eb & 0xFF;
        if eb < 48 || eb > 57 {
          return Err("invalid character in exponent");
        };
        exp_val = exp_val * 10 + (eb - 48);
        exp_ok = true;
        i = i + 1;
      };
      if !exp_ok {
        return Err("missing exponent digits");
      };
      var value = int_part + frac_part;
      var mult: Float64 = 1.0;
      if exp_negative {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 0.1;
          j = j + 1;
        };
      } else {
        var j: Int = 0;
        while j < exp_val {
          mult = mult * 10.0;
          j = j + 1;
        };
      };
      value = value * mult;
      if negative {
        value = -value;
      };
      return Ok(value);
    };
    if b < 48 || b > 57 {
      return Err("invalid character in float string");
    };
    var digit = (b - 48) as Float64;
    if has_frac {
      frac_part = frac_part + digit / frac_div;
      frac_div = frac_div * 10.0;
    } else {
      int_part = int_part * 10.0 + digit;
    };
    has_digit = true;
    i = i + 1;
  };
  if !has_digit {
    return Err("no digits");
  };
  var value = int_part + frac_part;
  if negative {
    value = -value;
  };
  Ok(value)
}

/// Parses "true" or "false" (exact, case-sensitive). Returns None otherwise.
/// Complexity: O(1).
pub fn parse_bool(s: Str) -> Option[Bool] {
  if s == "true" {
    return Some(true);
  };
  if s == "false" {
    return Some(false);
  };
  None
}

/// Returns the first character of a single-character string. Returns None for
/// an empty string or a multi-character string (documented: this helper
/// parses exactly one character). Complexity: O(1).
pub fn parse_char(s: Str) -> Option[Char] {
  let len = s.len();
  if len != 1 {
    return None;
  };
  var opt = string.char_at(s, 0);
  if opt.is_some {
    return Some(opt.value);
  };
  None
}
