// XIOM - Conversion: Atoi
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.atoi

// Depends on: none

// ============================================================================
// C-style ASCII-to-integer helpers: leading whitespace is skipped, an
// optional sign is accepted, and parsing stops at the first non-digit
// (trailing garbage is ignored). No malformed input ever fails -- results
// clamp to INT_MAX/INT_MIN on overflow.
// ============================================================================

use xiom.string;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

/// True iff the byte is C whitespace (space, \t, \n, \v, \f, \r).
fn _is_space(b: Int) -> Bool {
  if b == 32 { return true; }
  if b == 9 { return true; }
  if b == 10 { return true; }
  if b == 11 { return true; }
  if b == 12 { return true; }
  if b == 13 { return true; }
  false
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

/// Shared C-style parser. `radix` must be in [2, 36] (caller checks). Parses
/// as many leading digits as possible. Returns (value, 1 if any digit was
/// consumed, 0 otherwise).
fn _atoi_radix(s: Str, radix: Int) -> (Int, Int) {
  let len = s.len();
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i) as Int;
    b = b & 0xFF;
    if !_is_space(b) {
      break;
    };
    i = i + 1;
  };
  var negative = false;
  if i < len {
    var c = string.byte_at(s, i);
    if c == 45 {
      negative = true;
      i = i + 1;
    } elif c == 43 {
      i = i + 1;
    };
  };
  var result: Int = 0;
  var has_digit = false;
  while i < len {
    var digit = _digit_value(string.byte_at(s, i));
    if digit < 0 || digit >= radix {
      break;
    };
    if result > (INT_MAX - digit) / radix {
      if negative {
        return (INT_MIN, 1);
      };
      return (INT_MAX, 1);
    };
    result = result * radix + digit;
    has_digit = true;
    i = i + 1;
  };
  if !has_digit {
    return (0, 0);
  };
  if negative {
    return (-result, 1);
  };
  (result, 1)
}

/// Parses a decimal integer, returning zero on failure. C atoi semantics:
/// leading whitespace is skipped, an optional sign is accepted, and parsing
/// stops at the first non-digit. Overflow clamps to INT_MAX/INT_MIN.
/// Complexity: O(n), n = string length.
pub fn atoi(s: Str) -> Int {
  var r = _atoi_radix(s, 10);
  r.0
}

/// Parses an integer in the given radix (2-36), returning zero on failure or
/// an invalid radix. C-style prefix skipping; overflow clamps.
/// Complexity: O(n), n = string length.
pub fn atoi_radix(s: Str, radix: Int) -> Int {
  if radix < 2 || radix > 36 {
    return 0;
  };
  var r = _atoi_radix(s, radix);
  r.0
}

/// Parses a decimal integer with a fallback value: returns `default` when no
/// digits can be parsed (a genuine "0" still returns 0).
/// Complexity: O(n), n = string length.
pub fn atoi_or(s: Str, default: Int) -> Int {
  var r = _atoi_radix(s, 10);
  if r.1 == 1 {
    return r.0;
  };
  default
}
