// XIOM - Conversion: Parse
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
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
use xiom.core.INT_MIN;

/// Parses a decimal integer string. An optional leading '-'/'+' is accepted.
/// Returns Err on an empty string, an invalid character, or overflow.
/// Complexity: O(n), n = string length.
pub fn parse_int(s: Str) -> Result[Int, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
  _parse_int_radix(s, 10)
}

/// Parses an integer string in the given radix (2-36, both digit cases
/// accepted). An optional leading '-'/'+' is accepted. Returns Err on an
/// invalid radix, an empty string, an invalid digit, a digit out of range
/// for the radix, or overflow. Complexity: O(n), n = string length.
pub fn parse_int_radix(s: Str, radix: Int) -> Result[Int, Str]
  ensures: (radix < 2 || radix > 36) => (result.is_err == true)
  ensures: (s.len() == 0) => (result.is_err == true)
{
  if radix < 2 || radix > 36 {
    return Err("invalid radix");
  };
  _parse_int_radix(s, radix)
}

/// Shared radix parser (radix pre-validated by the caller).
/// Wave 161: the minus path accumulates in the negative domain so the
/// INT64_MIN magnitude (2^63, not representable as a positive Int) parses;
/// the positive-magnitude form rejected "-9223372036854775808" as overflow.
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
  if negative {
    var nres: Int = 0;
    while i < len {
      var digit = _digit_value(string.byte_at(s, i));
      if digit < 0 {
        return Err("invalid digit");
      };
      if digit >= radix {
        return Err("digit out of range for radix");
      };
      if nres < (INT_MIN + digit) / radix {
        return Err("overflow");
      };
      nres = nres * radix - digit;
      i = i + 1;
    };
    return Ok(nres);
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
pub fn parse_float(s: Str) -> Result[Float64, Str]
  ensures: (s.len() == 0) => (result.is_err == true)
{
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
pub fn parse_bool(s: Str) -> Option[Bool]
  ensures: (s == "true") => (result.is_some == true)
  ensures: ((s != "true") && (s != "false")) => (result.is_none == true)
{
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
pub fn parse_char(s: Str) -> Option[Char]
  ensures: (s.len() != 1) => (result.is_none == true)
{
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

// ============================================================================
// Wave 166 (2026-10-02 intake rows 28 + 45; requesters training, cloudlog,
// translate): strict Option-shaped decimal parsing and offset-carrying
// parsing. Reject empty input, any junk byte, a bare sign, and overflow --
// never a silent zero. `parse_int_at` reports the byte offset consumed (the
// caller-relocatable cursor the row-45 scanners asked for).
// ============================================================================

// Raw byte at `i` over a cached pointer (T007 confinement; callers bound i).
fn _parse_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}

// Decimal value of byte `i` (0-9), or -1 for any other byte.
fn _parse_dec_digit(base: *UInt8, i: Int) -> Int {
  let v = (_parse_raw(base, i) as Int) & 0xFF;
  if v >= 48 && v <= 57 {
    return v - 48;
  };
  -1
}

/// Strict decimal parse, Option-shaped: Some(value) only when the WHOLE
/// string is one optionally-signed decimal ("-"/"+" allowed) that fits an
/// Int. Empty input, any junk byte, a bare sign, and overflow all yield None
/// (never a silent zero). Complexity: O(n).
pub fn parse_int_opt(s: Str) -> Option[Int]
  requires: true  // cached raw-byte scan (T007 confinement)
{
  let len = s.len();
  if len == 0 {
    return None;
  };
  let base = s.c_str();
  var i: Int = 0;
  var negative = false;
  let first = (_parse_raw(base, 0) as Int) & 0xFF;
  if first == 45 {
    negative = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  };
  if i >= len {
    return None;
  };
  if negative {
    var nres: Int = 0;
    while i < len {
      let d = _parse_dec_digit(base, i);
      if d < 0 {
        return None;
      };
      if nres < (INT_MIN + d) / 10 {
        return None;
      };
      nres = nres * 10 - d;
      i = i + 1;
    };
    return Some(nres);
  };
  var result: Int = 0;
  while i < len {
    let d = _parse_dec_digit(base, i);
    if d < 0 {
      return None;
    };
    if result > (INT_MAX - d) / 10 {
      return None;
    };
    result = result * 10 + d;
    i = i + 1;
  };
  Some(result)
}

/// struct ParsedInt { value: Int; next: Int } -- `next` is the byte offset
/// just past the last consumed digit (the caller-relocatable cursor).
pub type ParsedInt = { value: Int; next: Int; }

/// Strict decimal parse starting at byte `start`: Some({value, next}) with
/// the maximal digit run after an optional sign at `start`; requires at
/// least one digit (a bare sign, junk, out-of-range `start`, and overflow
/// all yield None). Junk AFTER the digits is not consumed and not an error --
/// `next` tells the caller where parsing stopped. Complexity: O(digits).
pub fn parse_int_at(s: Str, start: Int) -> Option[ParsedInt]
  requires: true  // cached raw-byte scan (T007 confinement)
{
  let len = s.len();
  if start < 0 || start >= len {
    return None;
  };
  let base = s.c_str();
  var i = start;
  var negative = false;
  let first = (_parse_raw(base, i) as Int) & 0xFF;
  if first == 45 {
    negative = true;
    i = i + 1;
  } elif first == 43 {
    i = i + 1;
  };
  if i >= len {
    return None;
  };
  var saw_digit = false;
  if negative {
    var nres: Int = 0;
    while i < len {
      let d = _parse_dec_digit(base, i);
      if d < 0 {
        break;
      };
      if nres < (INT_MIN + d) / 10 {
        return None;
      };
      nres = nres * 10 - d;
      saw_digit = true;
      i = i + 1;
    };
    if !saw_digit {
      return None;
    };
    return Some(ParsedInt{ value: nres; next: i });
  };
  var result: Int = 0;
  while i < len {
    let d = _parse_dec_digit(base, i);
    if d < 0 {
      break;
    };
    if result > (INT_MAX - d) / 10 {
      return None;
    };
    result = result * 10 + d;
    saw_digit = true;
    i = i + 1;
  };
  if !saw_digit {
    return None;
  };
  Some(ParsedInt{ value: result; next: i })
}
