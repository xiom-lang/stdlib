// XIOM - Conversion: ToFloat
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.tofloat

// Depends on: none

// ============================================================================
// Int-to-float widening and string-to-float parsing strategies. `to_float`
// shadows the core intrinsic within this module only. The string parsers are
// implemented here directly: the core `to_float_from_str` path is unusable
// (it relies on Char range comparisons that miscompile -- see the module
// header of xiom.convert.lossy).
// ============================================================================

use xiom.string;

/// Widens an integer to a float (exact up to 2^53). Complexity: O(1).
pub fn to_float(n: Int) -> Float64 {
  n as Float64
}

/// Parses a string into a float, clamping on failure: malformed input
/// (empty, no digits, invalid characters) yields 0.0. Supports sign, decimal
/// point, and 'e'/'E' exponent. Complexity: O(n), n = string length.
pub fn to_float_saturating(s: Str) -> Float64 {
  var r = _parse_float(s);
  match r {
    Some(v) => { return v; },
    None => { return 0.0; },
  }
}

/// Parses a string into a float only when the input is well-formed. Returns
/// None on malformed input. Complexity: O(n), n = string length.
pub fn to_float_checked(s: Str) -> Option[Float64] {
  _parse_float(s)
}

/// Private decimal float parser. None on empty input, missing digits, invalid
/// characters, multiple decimal points, or a malformed exponent.
fn _parse_float(s: Str) -> Option[Float64] {
  let len = s.len();
  if len == 0 {
    return None;
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
    return None;
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
        return None;
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
          return None;
        };
        exp_val = exp_val * 10 + (eb - 48);
        exp_ok = true;
        i = i + 1;
      };
      if !exp_ok {
        return None;
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
      return Some(value);
    };
    if b < 48 || b > 57 {
      return None;
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
    return None;
  };
  var value = int_part + frac_part;
  if negative {
    value = -value;
  };
  Some(value)
}
