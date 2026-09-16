// XIOM - Conversion: Strptime
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.strptime

// Depends on: xiom.time

// ============================================================================
// Date/time parsing with strptime-style format specifiers. The reference
// implementation lives in xiom.time.strptime; because the function name
// matches here (same-name delegation miscompiles -- BUG 25 #1) the parsing
// engine is reimplemented locally on top of the time/string primitives.
//
// Supported conversions: %Y %m %d %H %M %S %%. The result uses the
// xiom.time.DateParse struct (is_ok + date) to avoid Option-of-struct
// collisions (BUG 12 family).
// ============================================================================

use xiom.time;
use xiom.string;

/// Parse a string with a strptime specifier.
/// Parameters: s -- the input string; spec -- the format string.
/// Returns: a DateParse whose is_ok is true when the input matches the spec
///          and the parsed month/day are in range; unsupported conversions
///          and mismatches yield is_ok = false.
/// Complexity: O(|s| + |spec|).
pub fn strptime(s: Str, spec: Str) -> DateParse {
  var year: Int = 0;
  var month: Int = 1;
  var day: Int = 1;
  var have_y = false;
  var have_m = false;
  var have_d = false;
  var pos: Int = 0;
  var i: Int = 0;
  var slen = string.str_len(s);
  var speclen = string.str_len(spec);
  while i < speclen {
    var c = string.str_slice(spec, i, i + 1);
    if c == "%" && i + 1 < speclen {
      var conv = string.str_slice(spec, i + 1, i + 2);
      var digits = "";
      if conv == "%" {
        if pos >= slen {
          return _parse_fail();
        }
        var lit = string.str_slice(s, pos, pos + 1);
        if lit != "%" {
          return _parse_fail();
        }
        pos = pos + 1;
        i = i + 2;
      } elif conv == "Y" {
        while pos < slen && string.str_len(digits) < 4 {
          var ch = string.str_slice(s, pos, pos + 1);
          if ch >= "0" && ch <= "9" {
            digits = string.str_concat(digits, ch);
            pos = pos + 1;
          } else {
            break;
          }
        }
        if string.str_len(digits) != 4 {
          return _parse_fail();
        }
        year = _parse_int(digits);
        have_y = true;
        i = i + 2;
      } elif conv == "m" {
        while pos < slen && string.str_len(digits) < 2 {
          var ch2 = string.str_slice(s, pos, pos + 1);
          if ch2 >= "0" && ch2 <= "9" {
            digits = string.str_concat(digits, ch2);
            pos = pos + 1;
          } else {
            break;
          }
        }
        if string.str_len(digits) != 2 {
          return _parse_fail();
        }
        month = _parse_int(digits);
        have_m = true;
        i = i + 2;
      } elif conv == "d" {
        while pos < slen && string.str_len(digits) < 2 {
          var ch3 = string.str_slice(s, pos, pos + 1);
          if ch3 >= "0" && ch3 <= "9" {
            digits = string.str_concat(digits, ch3);
            pos = pos + 1;
          } else {
            break;
          }
        }
        if string.str_len(digits) != 2 {
          return _parse_fail();
        }
        day = _parse_int(digits);
        have_d = true;
        i = i + 2;
      } elif conv == "H" || conv == "M" || conv == "S" {
        while pos < slen && string.str_len(digits) < 2 {
          var ch4 = string.str_slice(s, pos, pos + 1);
          if ch4 >= "0" && ch4 <= "9" {
            digits = string.str_concat(digits, ch4);
            pos = pos + 1;
          } else {
            break;
          }
        }
        if string.str_len(digits) != 2 {
          return _parse_fail();
        }
        i = i + 2;
      } else {
        return _parse_fail();
      }
    } else {
      if pos >= slen {
        return _parse_fail();
      }
      var sc = string.str_slice(s, pos, pos + 1);
      if sc != c {
        return _parse_fail();
      }
      pos = pos + 1;
      i = i + 1;
    }
  }
  if !have_y || !have_m || !have_d {
    return _parse_fail();
  }
  if month < 1 || month > 12 {
    return _parse_fail();
  }
  if day < 1 || day > time.date_days_in_month(year, month) {
    return _parse_fail();
  }
  return DateParse{ is_ok: true; date: Date{ year: year; month: month; day: day; }; };
}

/// Parse an ISO 8601 "YYYY-MM-DD" date string.
/// Parameters: s -- the date string.
/// Returns: a DateParse with is_ok true when the string is well-formed.
/// Complexity: O(|s|).
pub fn strptime_iso8601(s: Str) -> DateParse {
  return strptime(s, "%Y-%m-%d");
}

// Failed-parse marker (mirrors xiom.time's DateParse convention).
fn _parse_fail() -> DateParse {
  return DateParse{ is_ok: false; date: Date{ year: 0; month: 1; day: 1; }; };
}

// Parse an ASCII digit string into an Int (leading zeros accepted).
fn _parse_int(s: Str) -> Int {
  var v: Int = 0;
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var c = string.str_slice(s, i, i + 1);
    if c == "0" { v = v * 10 + 0; }
    elif c == "1" { v = v * 10 + 1; }
    elif c == "2" { v = v * 10 + 2; }
    elif c == "3" { v = v * 10 + 3; }
    elif c == "4" { v = v * 10 + 4; }
    elif c == "5" { v = v * 10 + 5; }
    elif c == "6" { v = v * 10 + 6; }
    elif c == "7" { v = v * 10 + 7; }
    elif c == "8" { v = v * 10 + 8; }
    elif c == "9" { v = v * 10 + 9; }
    i = i + 1;
  }
  return v;
}
