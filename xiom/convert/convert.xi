// XIOM -- Type Conversion Traits
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert

use xiom.string;

pub interface From[T] { fn from(value: T) -> Self; }
pub interface Into[T] { fn into(self) -> T; }
pub interface TryFrom[T] { fn try_from(value: T) -> Result<Self, Str>; }
pub interface TryInto[T] { fn try_into(self) -> Result<T, Str>; }

// 8B/M9: Parse a value from a string
pub interface FromStr {
  fn from_str(s: Str) -> Result<Self, Str>
    requires: s.len() > 0
    ensures: true
  ;
}

// Identity conversion
pub fn identity[T](x: T) -> T
{ x }

// Common conversions
pub fn int_to_float(n: Int) -> Float64 {
  return to_float(n);
}

pub fn float_to_int(f: Float64) -> Int {
  return to_int(f);
}

pub fn int_to_string(n: Int) -> Str {
  return to_string(n);
}

// -- Float64 -> Str (exact-ish decimal formatting) ----------------------------
// NOTE (2026-08-11): the previous implementation used `to_string(f)` on a
// Float64, which the compiler lowers to fptosi (bit-pattern truncation) -- it
// printed the f64 BITS, not the value. Replaced with scaled-integer rounding
// (half away from zero, like C printf). All conversions are lossless to 15
// significant digits (the f64 round-trip guarantee), then round.

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
      s = str_concat(s, ".");
      var z: Int = 0;
      while z < decimals {
        s = str_concat(s, "0");
        z = z + 1;
      }
    }
    return s;
  }
  var scaled = _f64_round_half_away(v * (scale as Float64));
  var int_part = scaled / scale;
  var frac = scaled % scale;
  var s = to_string(int_part);
  if decimals > 0 {
    s = str_concat(s, ".");
    var fs = to_string(frac);
    var need = decimals - str_len(fs);
    var z: Int = 0;
    while z < need {
      s = str_concat(s, "0");
      z = z + 1;
    }
    s = str_concat(s, fs);
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
  var scaled = _f64_round_half_away(m * (scale as Float64));
  // mantissa carry: 9.999... -> 10.000...
  if scaled >= scale * 10 {
    scaled = scaled / 10;
    e = e + 1;
  }
  var int_d = scaled / scale;
  var frac = scaled % scale;
  var s = to_string(int_d);
  if decimals > 0 {
    s = str_concat(s, ".");
    var fs = to_string(frac);
    var need = decimals - str_len(fs);
    var z: Int = 0;
    while z < need {
      s = str_concat(s, "0");
      z = z + 1;
    }
    s = str_concat(s, fs);
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
  while str_len(s) < 2 {
    s = str_concat("0", s);
  }
  return str_concat(sign, s);
}

// Remove trailing zeros in the fraction and a trailing '.'.
fn _f64_strip_frac(s: Str) -> Str {
  var dot = index_of(s, ".");
  if dot.is_none {
    return s;
  }
  var i = str_len(s) - 1;
  while i >= 0 {
    var c = str_slice(s, i, i + 1);
    if c == "0" {
      i = i - 1;
    } else {
      break;
    }
  }
  if i >= 0 {
    var c2 = str_slice(s, i, i + 1);
    if c2 == "." {
      i = i - 1;
    }
  }
  if i < 0 { return "0"; }
  return str_slice(s, 0, i + 1);
}

/// Formats `f` in fixed-point notation with exactly `decimals` fraction digits
/// (rounded half away from zero). Handles sign, "nan" and "inf".
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
  if neg { return str_concat("-", body); }
  return body;
}

/// Formats `f` in scientific notation "d.ddde+/-XX" with `decimals` fraction
/// digits (rounded half away from zero). Handles sign, "nan" and "inf".
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
    body = str_concat(sci.0, _f64_exp_text(sci.1, false));
  }
  if neg { return str_concat("-", body); }
  return body;
}

/// Default Float64 -> Str conversion: 15 significant digits, fixed notation
/// for 1e-4 <= |f| < 1e15, scientific otherwise (C `%.15g` semantics with
/// trailing zeros stripped). Handles "nan"/"inf".
/// Complexity: O(|exp10| + 15).
pub fn float_to_string(f: Float64) -> Str
  ensures: result.len() > 0
{
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
      body = str_concat(_f64_strip_frac(sci.0), _f64_exp_text(sci.1, false));
    } else {
      var dec = 14 - e;
      if dec < 0 { dec = 0; }
      body = _f64_strip_frac(_f64_fixed_abs(v, dec));
    }
  }
  if neg { return str_concat("-", body); }
  return body;
}

pub fn bool_to_string(b: Bool) -> Str {
  if b { return "true"; };
  return "false";
}

pub fn char_to_int(c: Char) -> Int {
  return to_int_from_char(c);
}

pub fn int_to_char(n: Int) -> Option[Char]
  ensures: true
{
  if n < 0 || n > 1114111 {
    return Option[Char]{ is_some: false, value: '\0' };
  };
  return Option[Char]{ is_some: true, value: to_char(n) };
}
