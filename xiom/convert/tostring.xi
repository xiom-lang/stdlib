// XIOM - Conversion: ToString
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.tostring

// Depends on: none

// ============================================================================
// Formatting helpers for primitives as strings. `to_string` shadows the core
// intrinsic within this module only; the float/bool/radix helpers delegate to
// the canonical xiom.convert / xiom.num.base implementations (different
// function names, so delegation is safe from the same-name miscompile).
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
/// (including INT_MIN, which the core implementation mishandles by negating
/// in place). Complexity: O(log_10 |n|).
pub fn to_string(n: Int) -> Str {
  if n == 0 {
    return "0";
  };
  var x = n;
  var neg = false;
  if x < 0 {
    neg = true;
  };
  if x > 0 {
    x = 0 - x;
  };
  var digits = Vec[Int].new();
  while x != 0 {
    var d = x % 10;
    if d < 0 {
      d = 0 - d;
    };
    digits.push(d);
    x = x / 10;
  };
  var result = "";
  if neg {
    result = "-";
  };
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, string.str_slice("0123456789", d, d + 1));
    i = i - 1;
  };
  result
}

/// Formats a float as a string (15 significant digits, fixed or scientific,
/// handling "nan" and "inf"). Complexity: O(|exp10| + 15).
pub fn to_string_float(f: Float64) -> Str {
  convert.float_to_string(f)
}

/// Renders a boolean as "true" or "false". Complexity: O(1).
pub fn to_string_bool(b: Bool) -> Str {
  convert.bool_to_string(b)
}

/// Renders a character as a single-character UTF-8 string.
/// Complexity: O(1).
pub fn to_string_char(c: Char) -> Str {
  var tmp = Vec[UInt8].new();
  xiom.char.encode_utf8(c, &tmp);
  let blen = tmp.len();
  unsafe {
    var buf = malloc(blen + 1);
    var i: Int = 0;
    while i < blen {
      buf[i] = tmp[i];
      i = i + 1;
    };
    buf[blen] = 0;
    return Str.from_cstring(buf);
  }
}

/// Formats an integer in an arbitrary radix (2-36, lowercase digits).
/// Returns "" for an invalid radix. Complexity: O(log_radix |n|).
pub fn to_string_radix(n: Int, radix: Int) -> Str {
  xiom.num.base.to_base(n, radix)
}
