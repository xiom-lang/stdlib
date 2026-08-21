// XIOM - Conversion: Float
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.float

// Depends on: xiom.string, xiom.convert.parse

// ============================================================================
// Float formatting and parsing, and float/int conversions. Formatting names
// collide with xiom.convert (BUG 25 #1: same-name delegation miscompiles even
// when module-qualified) so the formatting engine is reimplemented here with
// the same scaled-integer rounding as the canonical convert module; parsing
// delegates to xiom.convert.parse (different name -- safe).
//
// All conversions are lossless to 15 significant digits (the f64 round-trip
// guarantee), then rounded half away from zero.
// ============================================================================

use xiom.string;
use xiom.convert.parse;

/// Format a float with 15 significant digits: fixed notation for
/// 1e-4 <= |f| < 1e15, scientific otherwise (C `%.15g` semantics with
/// trailing zeros stripped). Handles "nan"/"inf".
/// Parameters: f -- the float value.
/// Returns: the formatted string.
/// Complexity: O(|exp10| + 15).
pub fn float_to_string(f: Float64) -> Str {
  if f != f { return "nan"; }
  if f > 1.7976931348623157e308 { return "inf"; }
  if f < -1.7976931348623157e308 { return "-inf"; }
  var neg = false;
  var v = f;
  if f < 0.0 {
    neg = true;
    v = -f;
  }
  var body = "";
  if v == 0.0 {
    body = "0";
  } else {
    var e = _f64_exp10(v);
    if e >= 15 || e < -4 {
      var sci = _f64_sci_abs(v, 14);
      body = string.str_concat(_f64_strip_frac(sci.0), _f64_exp_text(sci.1, false));
    } else {
      var dec = 14 - e;
      if dec < 0 { dec = 0; }
      body = _f64_strip_frac(_f64_fixed_abs(v, dec));
    }
  }
  if neg { return string.str_concat("-", body); }
  return body;
}

/// Parse a string to a float.
/// Parameters: s -- the decimal float string (optional sign, '.', 'e'/'E').
/// Returns: Ok(Float64) for well-formed input, Err otherwise.
/// Complexity: O(n), n = string length.
pub fn string_to_float(s: Str) -> Result[Float64, Str] {
  return parse.parse_float(s);
}

/// Format a float in fixed-point notation with exactly `decimals` fraction
/// digits (rounded half away from zero). Handles "nan"/"inf".
/// Parameters: f -- the float value; decimals -- the fraction digit count.
/// Returns: the formatted string.
/// Complexity: O(decimals).
pub fn float_to_fixed_str(f: Float64, decimals: Int) -> Str {
  var neg = false;
  var v = f;
  if f != f { return "nan"; }
  if f > 1.7976931348623157e308 { return "inf"; }
  if f < -1.7976931348623157e308 { return "-inf"; }
  if f < 0.0 {
    neg = true;
    v = -f;
  }
  var body = _f64_fixed_abs(v, decimals);
  if neg { return string.str_concat("-", body); }
  return body;
}

/// Format a float in scientific notation "d.ddde+/-XX" with `decimals` fraction
/// digits (rounded half away from zero). Handles "nan"/"inf".
/// Parameters: f -- the float value; decimals -- the fraction digit count.
/// Returns: the formatted string.
/// Complexity: O(|exp10| + decimals).
pub fn float_to_sci_str(f: Float64, decimals: Int) -> Str {
  if f != f { return "nan"; }
  if f > 1.7976931348623157e308 { return "inf"; }
  if f < -1.7976931348623157e308 { return "-inf"; }
  var neg = false;
  var v = f;
  if f < 0.0 {
    neg = true;
    v = -f;
  }
  var body = "";
  if v == 0.0 {
    body = _f64_fixed_abs(0.0, decimals);
  } else {
    var sci = _f64_sci_abs(v, decimals);
    body = string.str_concat(sci.0, _f64_exp_text(sci.1, false));
  }
  if neg { return string.str_concat("-", body); }
  return body;
}

/// Truncate a float to an integer (toward zero).
/// Parameters: f -- the float value.
/// Returns: the truncated integer. Behavior for NaN/out-of-range input is
/// undefined (use checked variants elsewhere).
/// Complexity: O(1).
pub fn float_to_int(f: Float64) -> Int {
  return to_int(f);
}

/// Widen an integer to a float (exact up to 2^53).
/// Parameters: n -- the integer value.
/// Returns: n widened to Float64.
/// Complexity: O(1).
pub fn int_to_float(n: Int) -> Float64 {
  return to_float(n);
}

// Decimal exponent: v = m * 10^e with 1 <= m < 10 (v >= 0; 0 -> e = 0).
fn _f64_exp10(v: Float64) -> Int {
  var e: Int = 0;
  var t = v;
  while t >= 10.0 {
    t = t / 10.0;
    e = e + 1;
  }
  while t < 1.0 {
    t = t * 10.0;
    e = e - 1;
  }
  return e;
}

// 10^p as exact Int (p in 0..=15 -- 1e15 fits i64).
fn _f64_scale(p: Int) -> Int {
  var s: Int = 1;
  var k: Int = 0;
  while k < p {
    s = s * 10;
    k = k + 1;
  }
  return s;
}

// Round half away from zero (x >= 0).
fn _f64_round_half_away(x: Float64) -> Int {
  return to_int(x + 0.5);
}

// Fixed-point digits for v >= 0 with exactly `decimals` fraction digits,
// rounded half-away-from-zero. Overflow guard: |v| >= 1e17 renders without a
// fraction (beyond that f64 granularity makes decimals meaningless).
fn _f64_fixed_abs(v: Float64, decimals: Int) -> Str {
  var scale = _f64_scale(decimals);
  if v >= 100000000000000000.0 {
    var s = to_string(to_int(v));
    if decimals > 0 {
      s = string.str_concat(s, ".");
      var z: Int = 0;
      while z < decimals {
        s = string.str_concat(s, "0");
        z = z + 1;
      }
    }
    return s;
  }
  var scaled = _f64_round_half_away(v * to_float(scale));
  var int_part = scaled / scale;
  var frac = scaled % scale;
  var s = to_string(int_part);
  if decimals > 0 {
    s = string.str_concat(s, ".");
    var fs = to_string(frac);
    var need = decimals - string.str_len(fs);
    var z: Int = 0;
    while z < need {
      s = string.str_concat(s, "0");
      z = z + 1;
    }
    s = string.str_concat(s, fs);
  }
  return s;
}

// Scientific digits for v >= 0: ("d.fff", exp10), `decimals` fraction digits.
fn _f64_sci_abs(v: Float64, decimals: Int) -> (Str, Int) {
  var e = _f64_exp10(v);
  var m = v;
  var k: Int = 0;
  while k < e {
    m = m / 10.0;
    k = k + 1;
  }
  while k > e {
    m = m * 10.0;
    k = k - 1;
  }
  var scale = _f64_scale(decimals);
  var scaled = _f64_round_half_away(m * to_float(scale));
  if scaled >= scale * 10 {
    scaled = scaled / 10;
    e = e + 1;
  }
  var int_d = scaled / scale;
  var frac = scaled % scale;
  var s = to_string(int_d);
  if decimals > 0 {
    s = string.str_concat(s, ".");
    var fs = to_string(frac);
    var need = decimals - string.str_len(fs);
    var z: Int = 0;
    while z < need {
      s = string.str_concat(s, "0");
      z = z + 1;
    }
    s = string.str_concat(s, fs);
  }
  return (s, e);
}

// "e+/-XX" (exponent at least 2 digits), upper -> "E+/-XX".
fn _f64_exp_text(e_in: Int, upper: Bool) -> Str {
  var e = e_in;
  var sign = "e-";
  if e < 0 {
    sign = "e-";
    e = 0 - e;
  } else {
    sign = "e+";
  }
  if upper {
    if sign == "e+" {
      sign = "E+";
    } else {
      sign = "E-";
    }
  }
  var s = to_string(e);
  while string.str_len(s) < 2 {
    s = string.str_concat("0", s);
  }
  return string.str_concat(sign, s);
}

// Remove trailing zeros in the fraction and a trailing '.'.
fn _f64_strip_frac(s: Str) -> Str {
  var dot = string.index_of(s, ".");
  if dot.is_none {
    return s;
  }
  var i = string.str_len(s) - 1;
  while i >= 0 {
    var c = string.str_slice(s, i, i + 1);
    if c == "0" {
      i = i - 1;
    } else {
      break;
    }
  }
  if i >= 0 {
    var c2 = string.str_slice(s, i, i + 1);
    if c2 == "." {
      i = i - 1;
    }
  }
  if i < 0 { return "0"; }
  return string.str_slice(s, 0, i + 1);
}
