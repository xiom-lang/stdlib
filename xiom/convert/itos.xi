// XIOM - Conversion: Itos
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.itos

// Depends on: none

// ============================================================================
// Integer-to-string shorthand helpers built on the core `to_string` intrinsic
// (which is shadowed only locally and never re-entered from these helpers).
// ============================================================================

use xiom.string;

/// Magnitude digits of n as a string (no sign), exact for INT_MIN.
fn _magnitude(n: Int) -> Str {
  if n == 0 {
    return "0";
  };
  var x = n;
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
  var i = digits.len() - 1;
  while i >= 0 {
    var d = digits[i];
    result = string.str_concat(result, string.str_slice("0123456789", d, d + 1));
    i = i - 1;
  };
  result
}

/// Integer-to-string shorthand (decimal). Complexity: O(log_10 |n|).
pub fn itos(n: Int) -> Str {
  to_string(n)
}

/// Integer-to-string with zero padding to `width` characters (printf %0Nd
/// style: the sign, if any, precedes the padding). Widths smaller than the
/// digit count are ignored. Complexity: O(width).
pub fn itos_padded(n: Int, width: Int) -> Str {
  if width <= 0 {
    return to_string(n);
  };
  var neg = n < 0;
  var digits = _magnitude(n);
  var pad = width - string.str_len(digits);
  if neg {
    pad = pad - 1;
  };
  var result = "";
  if neg {
    result = "-";
  };
  while pad > 0 {
    result = string.str_concat(result, "0");
    pad = pad - 1;
  };
  string.str_concat(result, digits)
}

/// Integer-to-string with an explicit sign: positive values get a '+'
/// prefix; zero and negative values render normally. Complexity: O(log_10 n).
pub fn itos_signed(n: Int) -> Str {
  if n > 0 {
    return string.str_concat("+", to_string(n));
  };
  to_string(n)
}
