// XIOM - Conversion: Strftime
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.strftime

// Depends on: xiom.time

// ============================================================================
// Date/time formatting with strftime-style format specifiers. The reference
// implementation lives in xiom.time.strftime; because the function name
// matches here (same-name delegation miscompiles -- BUG 25 #1) the formatting
// engine is reimplemented locally on top of the time/string primitives.
//
// Supported conversions: %Y %y %m %d %H %M %S %j %w %u %%. Unknown
// conversions are left as-is.
// ============================================================================

use xiom.time;
use xiom.string;

/// Format a date using a strftime specifier.
/// Parameters: spec -- the format string; d -- the date.
/// Returns: the formatted string. Unknown conversions pass through literally.
/// Complexity: O(|spec|).
pub fn strftime(spec: Str, d: &Date) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(spec);
  while i < len {
    var c = string.str_slice(spec, i, i + 1);
    if c == "%" && i + 1 < len {
      var conv = string.str_slice(spec, i + 1, i + 2);
      if conv == "%" {
        result = string.str_concat(result, "%");
        i = i + 2;
      } elif conv == "Y" {
        result = string.str_concat(result, _pad4(d.year));
        i = i + 2;
      } elif conv == "y" {
        var yy = d.year % 100;
        if yy < 0 { yy = yy + 100; }
        result = string.str_concat(result, _pad2(yy));
        i = i + 2;
      } elif conv == "m" {
        result = string.str_concat(result, _pad2(d.month));
        i = i + 2;
      } elif conv == "d" {
        result = string.str_concat(result, _pad2(d.day));
        i = i + 2;
      } elif conv == "H" {
        result = string.str_concat(result, "00");
        i = i + 2;
      } elif conv == "M" {
        result = string.str_concat(result, "00");
        i = i + 2;
      } elif conv == "S" {
        result = string.str_concat(result, "00");
        i = i + 2;
      } elif conv == "j" {
        var doy = time.date_day_of_year(d.year, d.month, d.day);
        result = string.str_concat(result, _pad3(doy));
        i = i + 2;
      } elif conv == "w" {
        var w = time.date_day_of_week(d.year, d.month, d.day);
        result = string.str_concat(result, to_string(w));
        i = i + 2;
      } elif conv == "u" {
        var w2 = time.date_day_of_week(d.year, d.month, d.day);
        var u = w2;
        if u == 0 { u = 7; }
        result = string.str_concat(result, to_string(u));
        i = i + 2;
      } else {
        result = string.str_concat(result, c);
        i = i + 1;
      }
    } else {
      result = string.str_concat(result, c);
      i = i + 1;
    }
  }
  return result;
}

/// Format the current date using a strftime specifier.
/// Parameters: spec -- the format string.
/// Returns: the formatted string for today's date.
/// Complexity: O(|spec|).
pub fn strftime_now(spec: Str) -> Str {
  let d = time.date_now();
  return strftime(spec, &d);
}

// Format n zero-padded to at least 2 digits.
fn _pad2(n: Int) -> Str {
  var s = to_string(n);
  while string.str_len(s) < 2 {
    s = string.str_concat("0", s);
  }
  return s;
}

// Format n zero-padded to at least 3 digits.
fn _pad3(n: Int) -> Str {
  var s = to_string(n);
  while string.str_len(s) < 3 {
    s = string.str_concat("0", s);
  }
  return s;
}

// Format n zero-padded to at least 4 digits.
fn _pad4(n: Int) -> Str {
  var s = to_string(n);
  while string.str_len(s) < 4 {
    s = string.str_concat("0", s);
  }
  return s;
}
