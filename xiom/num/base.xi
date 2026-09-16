// XIOM - Num: Base
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.num.base

// Depends on: xiom.string

// ============================================================================
// Radix conversion for integers and floats, plus digit decomposition.
// Digits are 0-9 then a-z (lowercase; parsing accepts both cases). An
// invalid base (outside 2..36) is reported per function: to_base returns "",
// from_base / from_base_float return Err("invalid base"), digits_of returns
// an empty vector, from_digits returns 0.
// ============================================================================

use xiom.string;

const _ALPHABET: Str = "0123456789abcdefghijklmnopqrstuvwxyz";
const _INT_MAX: Int = 9223372036854775807;

/// The one-character string for digit value d (0..35). Caller guarantees range.
fn _digit_char(d: Int) -> Str {
  xiom.string.str_slice(_ALPHABET, d, d + 1)
}

/// Numeric value of a digit byte (0-9, a-z, A-Z); -1 for any other byte.
fn _digit_value(c: UInt8) -> Int {
  var code = c as Int;
  if code >= 48 && code <= 57 { return code - 48; }
  if code >= 97 && code <= 122 { return code - 87; }
  if code >= 65 && code <= 90 { return code - 55; }
  -1
}

/// Integer n as a string in the given base (2-36), lowercase digits.
/// n == 0 yields "0"; negatives get a "-" prefix. Invalid base yields "".
/// NOTE: INT_MIN's magnitude (2^63) has no positive i64 representation, so
/// to_base(INT_MIN, base) returns "-" (documented edge).
/// Complexity: O(log_base |n|).
pub fn to_base(n: Int, base: Int) -> Str {
  if base < 2 || base > 36 { return ""; }
  if n == 0 { return "0"; }
  var neg = false;
  var num = n;
  if num < 0 {
    neg = true;
    num = -num;
  }
  var digits = Vec[Int].new();
  while num > 0 {
    digits.push(num % base);
    num = num / base;
  }
  var result = "";
  if neg { result = "-"; }
  var i = digits.len() - 1;
  while i >= 0 {
    result = result + _digit_char(digits[i]);
    i = i - 1;
  }
  result
}

/// Parses a base-(2-36) string into an Int. An optional leading '-'/'+' is
/// accepted; both digit cases are. Err on invalid base, empty string, an
/// invalid digit, a digit out of range for the base, or overflow.
/// Complexity: O(len(s)).
pub fn from_base(s: Str, base: Int) -> Result[Int, Str] {
  if base < 2 || base > 36 { return Err("invalid base"); }
  if s.len() == 0 { return Err("empty string"); }
  var neg = false;
  var i = 0;
  var first = xiom.string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  }
  if i >= s.len() { return Err("no digits"); }
  var result: Int = 0;
  while i < s.len() {
    var d = _digit_value(xiom.string.byte_at(s, i));
    if d < 0 { return Err("invalid digit"); }
    if d >= base { return Err("digit out of range for base"); }
    if result > (_INT_MAX - d) / base { return Err("overflow"); }
    result = result * base + d;
    i = i + 1;
  }
  if neg { result = -result; }
  Ok(result)
}

/// Float f as a base-(2-36) string with prec fraction digits (truncated, not
/// rounded). Handles sign, "inf"/"-inf", and (for the future) "nan".
/// Returns "" for an invalid base/prec or for |f| >= 2^63 (the integer part
/// is then not representable). Complexity: O(prec + log_base |f|).
pub fn to_base_float(f: Float64, base: Int, prec: Int) -> Str {
  if base < 2 || base > 36 || prec < 0 { return ""; }
  // TODO(compiler): BUG 19 -- NaN cannot be produced today; the guard is kept
  // for the future and requires no NaN construction.
  if f != f { return "nan"; }
  if f == 1.0 / 0.0 { return "inf"; }
  if f == -1.0 / 0.0 { return "-inf"; }
  var neg = f < 0.0;
  var x = f;
  if neg { x = -x; }
  if x >= 9223372036854775808.0 { return ""; }
  var int_part = x as Int;
  var frac = x - (int_part as Float64);
  var result = to_base(int_part, base);
  if prec > 0 {
    result = result + ".";
    var k = 0;
    var bf = base as Float64;
    while k < prec {
      frac = frac * bf;
      var d = frac as Int;
      if d >= base {
        // Rounding pushed frac*base up to exactly base: exhaust the fraction.
        d = base - 1;
        frac = 0.0;
      }
      result = result + _digit_char(d);
      frac = frac - (d as Float64);
      k = k + 1;
    }
  }
  if neg { result = "-" + result; }
  result
}

/// Parses a base-(2-36) float string ("-1a.2f") into a Float64. An optional
/// sign and a single '.' are accepted; scientific notation is not. Err on
/// invalid base, empty string, bad digits, or multiple decimal points.
/// Complexity: O(len(s)).
pub fn from_base_float(s: Str, base: Int) -> Result[Float64, Str] {
  if base < 2 || base > 36 { return Err("invalid base"); }
  if s.len() == 0 { return Err("empty string"); }
  var neg = false;
  var i = 0;
  var first = xiom.string.byte_at(s, 0);
  if first == 45 {
    neg = true;
    i = 1;
  } elif first == 43 {
    i = 1;
  }
  if i >= s.len() { return Err("no digits"); }
  var value: Float64 = 0.0;
  var frac_div: Float64 = 1.0;
  var has_digit = false;
  var bf = base as Float64;
  while i < s.len() {
    var c = xiom.string.byte_at(s, i);
    if c == 46 {
      if frac_div != 1.0 { return Err("multiple decimal points"); }
      frac_div = bf;
      i = i + 1;
      continue;
    }
    var d = _digit_value(c);
    if d < 0 || d >= base { return Err("digit out of range for base"); }
    if frac_div == 1.0 {
      value = value * bf + (d as Float64);
    } else {
      value = value + (d as Float64) / frac_div;
      frac_div = frac_div * bf;
    }
    has_digit = true;
    i = i + 1;
  }
  if !has_digit { return Err("no digits"); }
  if neg { value = -value; }
  Ok(value)
}

/// Digits of |n| in the given base, least significant first (little-endian).
/// n == 0 yields [0]; negatives use the magnitude. Invalid base yields an
/// empty vector. Complexity: O(log_base |n|).
pub fn digits_of(n: Int, base: Int) -> Vec[Int] {
  var result = Vec[Int].new();
  if base < 2 || base > 36 { return result; }
  if n == 0 {
    result.push(0);
    return result;
  }
  var x = n;
  if x < 0 { x = -x; }
  while x > 0 {
    result.push(x % base);
    x = x / base;
  }
  result
}

/// Integer reconstructed from a little-endian digit vector in the given base
/// (inverse of digits_of). Returns 0 on an invalid base, an out-of-range
/// digit, or overflow (documented -- the signature cannot signal errors).
/// Complexity: O(len(digits)).
pub fn from_digits(digits: &Vec[Int], base: Int) -> Int {
  if base < 2 || base > 36 { return 0; }
  var result: Int = 0;
  var i = 0;
  while i < digits.len() {
    var d = digits[i];
    if d < 0 || d >= base { return 0; }
    if result > (_INT_MAX - d) / base { return 0; }
    result = result * base + d;
    i = i + 1;
  }
  result
}
