// XIOM - Conversion: Lossy
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.lossy

// Depends on: none

// ============================================================================
// Lossy conversion helpers that never fail: malformed input yields a
// documented best-effort default instead of an error.
// ============================================================================

use xiom.string;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

/// Parses a decimal integer string. Returns 0 on malformed input (empty,
/// invalid characters) and clamps to INT_MAX/INT_MIN on overflow -- the
/// function never fails. Complexity: O(n), n = string length.
pub fn lossy_from_str(s: Str) -> Int {
  let len = s.len();
  if len == 0 {
    return 0;
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
    return 0;
  };
  var result: Int = 0;
  while i < len {
    var b = string.byte_at(s, i) as Int;
    b = b & 0xFF;
    if b < 48 || b > 57 {
      return 0;
    };
    var digit = b - 48;
    if result > (INT_MAX - digit) / 10 {
      if negative {
        return INT_MIN;
      };
      return INT_MAX;
    };
    result = result * 10 + digit;
    i = i + 1;
  };
  if negative {
    result = -result;
  };
  result
}

/// Truncates a float toward zero, clamping to INT_MAX/INT_MIN on overflow.
/// NaN yields 0. Complexity: O(1).
pub fn lossy_from_float(f: Float64) -> Int {
  if f != f {
    return 0;
  };
  if f >= 9223372036854775808.0 {
    return INT_MAX;
  };
  if f < -9223372036854775808.0 {
    return INT_MIN;
  };
  f as Int
}

/// Parses a floating-point string, returning 0.0 on any parse failure.
/// Supports optional sign, decimal point, and 'e'/'E' exponent.
/// Complexity: O(n), n = string length.
pub fn lossy_to_float(s: Str) -> Float64 {
  let len = s.len();
  if len == 0 {
    return 0.0;
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
    return 0.0;
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
        return 0.0;
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
          return 0.0;
        };
        exp_val = exp_val * 10 + (eb - 48);
        exp_ok = true;
        i = i + 1;
      };
      if !exp_ok {
        return 0.0;
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
      return value;
    };
    if b < 48 || b > 57 {
      return 0.0;
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
    return 0.0;
  };
  var value = int_part + frac_part;
  if negative {
    value = -value;
  };
  value
}

/// Returns the first character of s, or '\0' (the null character) when the
/// string is empty. Complexity: O(1).
pub fn lossy_char(s: Str) -> Char {
  var opt = string.char_at(s, 0);
  if opt.is_some {
    return opt.value;
  };
  '\0'
}
