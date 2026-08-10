// XIOM — BigFloat: arbitrary-precision decimal floating point (xiom.num.bigfloat)
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
//
// Category: num/ (D4). Imported as `use xiom.num.bigfloat;` (leaf calls:
// `bigfloat.bigfloat_add(...)`) or through the flat aggregate
// `use xiom.bigfloat;` (full dotted path `xiom.num.bigfloat.bigfloat_add`).
//
// Representation (Decision D3, power-of-10):
//   value = sign * significand * 10^exponent
// where `significand` is a normalized BigInt (no trailing zeros), `sign` is
// false for positive, and `precision` is the number of significant DECIMAL
// digits honored by arithmetic. Parse/format are string-level exact; all
// arithmetic rounds to max(a.precision, b.precision) with the current
// RoundMode (default Nearest, ties-to-even). Zero has an empty significand
// and sign = false.
//
// NOTE (2026-08-10): module-global initializers cannot call functions
// (compiler bug — docs/COMPILER_BUGS.md), so the spec constants are exposed
// as pure constructor functions (bigfloat_pi(), ...) that return fresh
// values. The round-mode global is updated by whole-value assignment only
// (global struct FIELD writes are also a logged compiler bug).

module xiom.num.bigfloat

use xiom.bigint;
use xiom.string;
use xiom.core.to_string;
use xiom.core.to_int_from_str;
use xiom.core.to_int;
use xiom.core.to_float;
use xiom.math;

pub type RoundMode = enum { Nearest, Up, Down, Zero }

pub type BigFloat = {
  sign: Bool;
  exponent: Int;
  significand: BigInt;
  precision: Int;
}

// Split result of _split_int_frac: magnitude = q + r / 10^d.
// PUB (not private): catalog fns returning module-local PRIVATE struct types
// are degraded to i64 by the checker (see docs/COMPILER_BUGS.md BUG 9) — the
// type must be part of the module's public surface.
pub type IntFrac = { q: BigInt; r: BigInt; d: Int; }

var _default_round: RoundMode = RoundMode.Nearest;
var _default_precision: Int = 64;

// ============================================================================
// Constants (constructor functions — see header note)
// ============================================================================

pub fn bigfloat_zero() -> BigFloat {
  return BigFloat{ sign: false; exponent: 0;
                   significand: xiom.bigint.bigint_zero(); precision: _default_precision; };
}

pub fn bigfloat_one() -> BigFloat {
  return bigfloat_from_int(1);
}

pub fn bigfloat_two() -> BigFloat {
  return bigfloat_from_int(2);
}

pub fn bigfloat_ten() -> BigFloat {
  return bigfloat_from_int(10);
}

pub fn bigfloat_half() -> BigFloat {
  return BigFloat{ sign: false; exponent: -1;
                   significand: xiom.bigint.bigint_from_int(5); precision: _default_precision; };
}

// pi to 100 decimal digits.
pub fn bigfloat_pi() -> BigFloat {
  var r = bigfloat_from_str("3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679");
  match r {
    Ok(v) => { return v; },
    Err(_) => { return bigfloat_zero(); },
  }
}

// e to 100 decimal digits.
pub fn bigfloat_e() -> BigFloat {
  var r = bigfloat_from_str("2.7182818284590452353602874713526624977572470936999595749669676277240766303535475945713821785251664274");
  match r {
    Ok(v) => { return v; },
    Err(_) => { return bigfloat_zero(); },
  }
}

// ============================================================================
// Private helpers
// ============================================================================

fn _copy_bf(f: &BigFloat) -> BigFloat {
  return BigFloat{ sign: f.sign; exponent: f.exponent;
                   significand: xiom.bigint.bigint_abs(&f.significand); precision: f.precision; };
}

fn _prec_of(a: &BigFloat, b: &BigFloat) -> Int {
  var p = a.precision;
  if b.precision > p { p = b.precision; }
  return p;
}

// Strip trailing zeros from the significand (adjusting the exponent) so the
// representation is canonical: 31.40 -> 314 x 10^-1.
fn _normalize(f: &BigFloat) -> BigFloat {
  if xiom.bigint.bigint_is_zero(&f.significand) {
    return BigFloat{ sign: false; exponent: 0;
                     significand: xiom.bigint.bigint_zero(); precision: f.precision; };
  }
  var sig = xiom.bigint.bigint_abs(&f.significand);
  var exp = f.exponent;
  var ten = xiom.bigint.bigint_ten();
  var dm = xiom.bigint.bigint_div_mod(&sig, &ten);
  while xiom.bigint.bigint_is_zero(&dm.1) && !xiom.bigint.bigint_is_zero(&dm.0) {
    sig = dm.0;
    exp = exp + 1;
    dm = xiom.bigint.bigint_div_mod(&sig, &ten);
  }
  return BigFloat{ sign: f.sign; exponent: exp; significand: sig; precision: f.precision; };
}

// Decimal digit count of a positive BigInt (1 for zero).
fn _digits_of(b: &BigInt) -> Int {
  var s = xiom.bigint.bigint_to_str(b);
  return s.len();
}

// Round `f` to `digits` significant digits with the given mode. `f` need not
// be normalized. The result is NOT normalized — trailing zeros produced by
// the rounding stay significant (to_str_prec must render "1.41421356237310"
// as 15 digits, not the normalized 14-digit form). Arithmetic callers
// normalize via _round_to_precision / with_rounding.
fn _round_digits_raw(f: &BigFloat, digits: Int, mode: RoundMode) -> BigFloat {
  var sig_digits = _digits_of(&f.significand);
  if sig_digits <= digits {
    return _copy_bf(f);
  }
  var drop = sig_digits - digits;
  var divisor = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), drop);
  var dm = xiom.bigint.bigint_div_mod(&f.significand, &divisor);
  var q = dm.0;
  var r = dm.1;
  var round_up = false;
  match mode {
    RoundMode.Zero => {},
    RoundMode.Up => {
      if !xiom.bigint.bigint_is_zero(&r) {
        if f.sign == false { round_up = true; }
      }
    },
    RoundMode.Down => {
      if !xiom.bigint.bigint_is_zero(&r) {
        if f.sign == true { round_up = true; }
      }
    },
    RoundMode.Nearest => {
      var half = xiom.bigint.bigint_div(&divisor, &xiom.bigint.bigint_two());
      var cmp = xiom.bigint.bigint_compare(&r, &half);
      if cmp > 0 { round_up = true; }
      elif cmp == 0 {
        if xiom.bigint.bigint_is_odd(&q) { round_up = true; }
      }
    },
  }
  if round_up { q = xiom.bigint.bigint_add(&q, &xiom.bigint.bigint_one()); }
  return BigFloat{ sign: f.sign; exponent: f.exponent + drop;
                   significand: q; precision: f.precision; };
}

// Round using the thread-local default mode (normalized result).
fn _round_to_precision(f: &BigFloat) -> BigFloat {
  var r = _round_digits_raw(f, f.precision, _default_round);
  return _normalize(&r);
}

// ============================================================================
// Rounding mode (thread-local default; whole-value global assignment)
// ============================================================================

pub fn bigfloat_set_round_mode(mode: RoundMode) {
  _default_round = mode;
}

pub fn bigfloat_get_round_mode() -> RoundMode {
  return _default_round;
}

// ============================================================================
// Constructors
// ============================================================================

pub fn bigfloat_from_int(n: Int) -> BigFloat {
  var neg = n < 0;
  var absn = n;
  if neg { absn = -absn; }
  return BigFloat{ sign: neg; exponent: 0;
                   significand: xiom.bigint.bigint_from_int(absn); precision: _default_precision; };
}

// Exact to 15 significant digits (the f64 round-trip guarantee); power-of-10
// inputs (0.1, 1e300, 3.14) come out exact.
pub fn bigfloat_from_float(f: Float64) -> BigFloat
  requires: !xiom.math.is_nan(f)
  requires: !xiom.math.is_inf(f)
{
  if f == 0.0 { return bigfloat_zero(); }
  var neg = f < 0.0;
  var x = f;
  if neg { x = -x; }
  // Normalize to [1, 10) tracking the decimal exponent.
  var exp10 = 0;
  while x >= 10.0 {
    x = x / 10.0;
    exp10 = exp10 + 1;
  }
  while x < 1.0 {
    x = x * 10.0;
    exp10 = exp10 - 1;
  }
  // Extract 17 significant digits (Float64 needs at most 17), then keep 15.
  var sig: Float64 = 0.0;
  var count = 0;
  while count < 17 {
    var d = xiom.core.to_int(x);
    sig = sig * 10.0 + xiom.core.to_float(d);
    x = (x - xiom.core.to_float(d)) * 10.0;
    count = count + 1;
  }
  exp10 = exp10 - 16;
  var sig_i = xiom.core.to_int(sig / 100.0);
  var bf = BigFloat{ sign: neg; exponent: exp10 + 2;
                     significand: xiom.bigint.bigint_from_int(sig_i); precision: _default_precision; };
  return _normalize(&bf);
}

// Parse decimal strings: "3.14159", "-1e-10", "2.5E+3", ".5", "3.".
// Exponent range is Int (i64). Result is normalized.
pub fn bigfloat_from_str(s: Str) -> Result[BigFloat, Str] {
  if s.len() == 0 { return Err("empty string"); }
  var neg = false;
  var pos = 0;
  var first = xiom.string.str_slice(s, 0, 1);
  if first == "-" { neg = true; pos = 1; }
  elif first == "+" { pos = 1; }
  if pos >= s.len() { return Err("no digits"); }
  // Split off the exponent part ("e"/"E").
  var mant = s;
  var exp_part = "";
  var ei = pos;
  while ei < s.len() {
    var ch = xiom.string.str_slice(s, ei, ei + 1);
    if ch == "e" || ch == "E" {
      mant = xiom.string.str_slice(s, pos, ei);
      exp_part = xiom.string.str_slice(s, ei + 1, s.len());
      break;
    }
    ei = ei + 1;
  }
  // Split mantissa at '.'.
  var int_str = mant;
  var frac_str = "";
  var dot_idx = -1;
  var i = 0;
  while i < mant.len() {
    if xiom.string.str_slice(mant, i, i + 1) == "." { dot_idx = i; break; }
    i = i + 1;
  }
  if dot_idx >= 0 {
    int_str = xiom.string.str_slice(mant, 0, dot_idx);
    frac_str = xiom.string.str_slice(mant, dot_idx + 1, mant.len());
  }
  if int_str.len() == 0 && frac_str.len() == 0 { return Err("no digits"); }
  var exp_val = 0;
  if exp_part.len() > 0 {
    var er = xiom.core.to_int_from_str(exp_part);
    match er {
      Ok(v) => { exp_val = v; },
      Err(_) => { return Err("invalid exponent"); },
    }
  }
  var sig_str = xiom.string.str_concat(int_str, frac_str);
  if sig_str.len() == 0 { sig_str = "0"; }
  var br = xiom.bigint.bigint_from_str(sig_str);
  match br {
    Ok(sig) => {
      var f = BigFloat{ sign: neg; exponent: exp_val - frac_str.len();
                        significand: sig; precision: _default_precision; };
      return Ok(_normalize(&f));
    },
    Err(e) => { return Err(e); },
  }
}

pub fn bigfloat_from_bigint(b: &BigInt) -> BigFloat {
  var neg = xiom.bigint.bigint_is_negative(b);
  var mag = xiom.bigint.bigint_abs(b);
  return BigFloat{ sign: neg; exponent: 0; significand: mag; precision: _default_precision; };
}

pub fn bigfloat_with_precision(n: Int, precision: Int) -> BigFloat
  requires: precision >= 1
{
  var f = bigfloat_from_int(n);
  f.precision = precision;
  return f;
}

// ============================================================================
// Conversions
// ============================================================================

// Exact decimal representation of the stored value ("shortest round-trip"
// by construction: the representation IS the decimal).
pub fn bigfloat_to_str(f: &BigFloat) -> Str {
  if xiom.bigint.bigint_is_zero(&f.significand) { return "0"; }
  var digits = xiom.bigint.bigint_to_str(&f.significand);
  var prefix = "";
  if f.sign { prefix = "-"; }
  if f.exponent >= 0 {
    var result = digits;
    var i = 0;
    while i < f.exponent {
      result = xiom.string.str_concat(result, "0");
      i = i + 1;
    }
    return xiom.string.str_concat(prefix, result);
  }
  var e = -f.exponent;
  if e >= digits.len() {
    var pad = e - digits.len();
    var zs = "";
    var i = 0;
    while i < pad {
      zs = xiom.string.str_concat(zs, "0");
      i = i + 1;
    }
    var body = xiom.string.str_concat("0.", zs);
    body = xiom.string.str_concat(body, digits);
    return xiom.string.str_concat(prefix, body);
  }
  var int_part = xiom.string.str_slice(digits, 0, digits.len() - e);
  var frac_part = xiom.string.str_slice(digits, digits.len() - e, digits.len());
  var body = xiom.string.str_concat(int_part, ".");
  body = xiom.string.str_concat(body, frac_part);
  return xiom.string.str_concat(prefix, body);
}

// Round to `digits` significant digits (current round mode) then format.
// Trailing zeros produced by rounding stay significant ("1.41421356237310"
// is 15 digits); a rounding carry that overflows the digit budget collapses
// to its normalized form ("1" for 0.999...9 -> 20 digits).
pub fn bigfloat_to_str_prec(f: &BigFloat, digits: Int) -> Str
  requires: digits >= 1
{
  var r = _round_digits_raw(f, digits, _default_round);
  if _digits_of(&r.significand) > digits {
    r = _normalize(&r);
  }
  return bigfloat_to_str(&r);
}

// Truncate toward zero.
pub fn bigfloat_to_bigint(f: &BigFloat) -> BigInt {
  var ten = xiom.bigint.bigint_ten();
  var mag = f.significand;
  if f.exponent >= 0 {
    mag = xiom.bigint.bigint_shift_left(&mag, f.exponent);
  } else {
    var divisor = xiom.bigint.bigint_pow(&ten, -f.exponent);
    mag = xiom.bigint.bigint_div(&mag, &divisor);
  }
  if f.sign { mag = xiom.bigint.bigint_neg(&mag); }
  return mag;
}

// Float64 conversion. None on exponent overflow/underflow beyond f64 range
// (|value| > ~1.8e308); values underflowing to 0.0 return Some(0.0).
pub fn bigfloat_to_float64(f: &BigFloat) -> Option[Float64] {
  if xiom.bigint.bigint_is_zero(&f.significand) { return Some(0.0); }
  var acc = 0.0;
  var i = f.significand.digits.len() - 1;
  while i >= 0 {
    acc = acc * 1000000000.0 + (f.significand.digits[i] as Float64);
    i = i - 1;
  }
  var e = f.exponent;
  if e > 0 {
    var k = 0;
    while k < e {
      acc = acc * 10.0;
      if xiom.math.is_inf(acc) { return None; }
      k = k + 1;
    }
  } else {
    var k = 0;
    while k < -e {
      acc = acc / 10.0;
      if acc == 0.0 { return Some(0.0); }
      k = k + 1;
    }
  }
  if f.sign { acc = -acc; }
  return Some(acc);
}

// ============================================================================
// Predicates
// ============================================================================

pub fn bigfloat_is_zero(f: &BigFloat) -> Bool {
  return xiom.bigint.bigint_is_zero(&f.significand);
}

pub fn bigfloat_is_negative(f: &BigFloat) -> Bool {
  return f.sign && !bigfloat_is_zero(f);
}

pub fn bigfloat_sign(f: &BigFloat) -> Int {
  if bigfloat_is_zero(f) { return 0; }
  if f.sign { return -1; }
  return 1;
}

pub fn bigfloat_precision(f: &BigFloat) -> Int {
  return f.precision;
}

// ============================================================================
// Arithmetic (result precision = max of operand precisions, rounded)
// ============================================================================

pub fn bigfloat_add(a: &BigFloat, b: &BigFloat) -> BigFloat {
  var prec = _prec_of(a, b);
  var e = a.exponent;
  if b.exponent < e { e = b.exponent; }
  var sa = xiom.bigint.bigint_shift_left(&a.significand, a.exponent - e);
  var sb = xiom.bigint.bigint_shift_left(&b.significand, b.exponent - e);
  var sum = BigFloat{ sign: false; exponent: e;
                      significand: xiom.bigint.bigint_zero(); precision: prec; };
  if a.sign == b.sign {
    sum.significand = xiom.bigint.bigint_add(&sa, &sb);
    sum.sign = a.sign;
  } else {
    var cmp = xiom.bigint.bigint_compare(&sa, &sb);
    if cmp == 0 {
      sum.significand = xiom.bigint.bigint_zero();
      sum.sign = false;
    } elif cmp > 0 {
      sum.significand = xiom.bigint.bigint_sub(&sa, &sb);
      sum.sign = a.sign;
    } else {
      sum.significand = xiom.bigint.bigint_sub(&sb, &sa);
      sum.sign = b.sign;
    }
  }
  var n = _normalize(&sum);
  return _round_to_precision(&n);
}

pub fn bigfloat_sub(a: &BigFloat, b: &BigFloat) -> BigFloat {
  var nb = _copy_bf(b);
  nb.sign = !b.sign;
  return bigfloat_add(a, &nb);
}

pub fn bigfloat_mul(a: &BigFloat, b: &BigFloat) -> BigFloat {
  var prec = _prec_of(a, b);
  if bigfloat_is_zero(a) || bigfloat_is_zero(b) {
    return BigFloat{ sign: false; exponent: 0;
                     significand: xiom.bigint.bigint_zero(); precision: prec; };
  }
  var sig = xiom.bigint.bigint_mul(&a.significand, &b.significand);
  var result = BigFloat{ sign: a.sign != b.sign; exponent: a.exponent + b.exponent;
                         significand: sig; precision: prec; };
  var n = _normalize(&result);
  return _round_to_precision(&n);
}

// Truncating long division with guard digits, then rounded to precision.
// Requires a non-zero divisor.
pub fn bigfloat_div(a: &BigFloat, b: &BigFloat) -> BigFloat
  requires: !bigfloat_is_zero(b)
{
  var prec = _prec_of(a, b);
  if bigfloat_is_zero(b) { return bigfloat_zero(); }
  if bigfloat_is_zero(a) {
    return BigFloat{ sign: false; exponent: 0;
                     significand: xiom.bigint.bigint_zero(); precision: prec; };
  }
  var digits_a = _digits_of(&a.significand);
  var digits_b = _digits_of(&b.significand);
  var k = prec + 2 + digits_b - digits_a;
  if k < 0 { k = 0; }
  var scale = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), k);
  var num = xiom.bigint.bigint_mul(&a.significand, &scale);
  var q = xiom.bigint.bigint_div(&num, &b.significand);
  var result = BigFloat{ sign: a.sign != b.sign; exponent: a.exponent - b.exponent - k;
                         significand: q; precision: prec; };
  var n = _normalize(&result);
  return _round_to_precision(&n);
}

pub fn bigfloat_neg(f: &BigFloat) -> BigFloat {
  var result = _copy_bf(f);
  if !bigfloat_is_zero(f) { result.sign = !f.sign; }
  return result;
}

pub fn bigfloat_abs(f: &BigFloat) -> BigFloat {
  var result = _copy_bf(f);
  result.sign = false;
  return result;
}

// 1/f with guard digits, rounded to precision.
pub fn bigfloat_inv(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_zero(f)
{
  if bigfloat_is_zero(f) { return bigfloat_zero(); }
  var k = _digits_of(&f.significand) + f.precision + 2;
  var scale = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), k);
  var q = xiom.bigint.bigint_div(&scale, &f.significand);
  var result = BigFloat{ sign: f.sign; exponent: -f.exponent - k;
                         significand: q; precision: f.precision; };
  var n = _normalize(&result);
  return _round_to_precision(&n);
}

// Square root via Newton on the significand (bigint_sqrt is floor-exact),
// with 2 guard digits. Requires a non-negative operand.
pub fn bigfloat_sqrt(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(f)
{
  if bigfloat_is_zero(f) { return bigfloat_zero(); }
  var sig = f.significand;
  var exp = f.exponent;
  if exp % 2 != 0 {
    sig = xiom.bigint.bigint_mul(&sig, &xiom.bigint.bigint_ten());
    exp = exp - 1;
  }
  var k = f.precision + 2;
  var scale = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), k * 2);
  var scaled = xiom.bigint.bigint_mul(&sig, &scale);
  var s = xiom.bigint.bigint_sqrt(&scaled);
  var result = BigFloat{ sign: false; exponent: exp / 2 - k;
                         significand: s; precision: f.precision; };
  var n = _normalize(&result);
  return _round_to_precision(&n);
}

// Integer power (exp >= 0) by square-and-multiply.
pub fn bigfloat_pow(base: &BigFloat, exp: Int) -> BigFloat
  requires: exp >= 0
{
  if exp < 0 { return bigfloat_zero(); }
  if exp == 0 {
    return BigFloat{ sign: false; exponent: 0;
                     significand: xiom.bigint.bigint_one(); precision: base.precision; };
  }
  if bigfloat_is_zero(base) { return bigfloat_zero(); }
  var result = BigFloat{ sign: false; exponent: 0;
                         significand: xiom.bigint.bigint_one(); precision: base.precision; };
  var b = _copy_bf(base);
  var e = exp;
  while e > 0 {
    if e % 2 == 1 { result = bigfloat_mul(&result, &b); }
    e = e / 2;
    if e > 0 { b = bigfloat_mul(&b, &b); }
  }
  return result;
}

// ============================================================================
// Rounding: floor / ceil / round (ties-to-even) / trunc / fract
// ============================================================================

// Split the magnitude into integer part q and fractional limbs r / 10^d.
// Named struct (not a tuple) — tuple-of-struct returns were a fresh compiler
// bug (BUG 1, docs/COMPILER_BUGS.md); structs are the proven-safe ABI.
fn _split_int_frac(f: &BigFloat) -> IntFrac {
  if f.exponent >= 0 {
    var whole = xiom.bigint.bigint_shift_left(&f.significand, f.exponent);
    return IntFrac{ q: whole; r: xiom.bigint.bigint_zero(); d: 0; };
  }
  var d = -f.exponent;
  var divisor = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), d);
  var dm = xiom.bigint.bigint_div_mod(&f.significand, &divisor);
  return IntFrac{ q: dm.0; r: dm.1; d: d; };
}

pub fn bigfloat_trunc(f: &BigFloat) -> BigFloat {
  var split = _split_int_frac(f);
  return BigFloat{ sign: f.sign; exponent: 0;
                   significand: split.q; precision: f.precision; };
}

pub fn bigfloat_floor(f: &BigFloat) -> BigFloat {
  var split = _split_int_frac(f);
  var q = split.q;
  var r = split.r;
  if f.sign == true && !xiom.bigint.bigint_is_zero(&r) {
    q = xiom.bigint.bigint_add(&q, &xiom.bigint.bigint_one());
  }
  return BigFloat{ sign: f.sign; exponent: 0;
                   significand: q; precision: f.precision; };
}

pub fn bigfloat_ceil(f: &BigFloat) -> BigFloat {
  var split = _split_int_frac(f);
  var q = split.q;
  var r = split.r;
  if f.sign == false && !xiom.bigint.bigint_is_zero(&r) {
    q = xiom.bigint.bigint_add(&q, &xiom.bigint.bigint_one());
  }
  return BigFloat{ sign: f.sign; exponent: 0;
                   significand: q; precision: f.precision; };
}

// Round to the nearest integer, ties to even (magnitude rounding).
pub fn bigfloat_round(f: &BigFloat) -> BigFloat {
  var split = _split_int_frac(f);
  var q = split.q;
  var r = split.r;
  if !xiom.bigint.bigint_is_zero(&r) {
    var d = split.d;
    var divisor = xiom.bigint.bigint_pow(&xiom.bigint.bigint_ten(), d);
    var half = xiom.bigint.bigint_div(&divisor, &xiom.bigint.bigint_two());
    var cmp = xiom.bigint.bigint_compare(&r, &half);
    if cmp > 0 {
      q = xiom.bigint.bigint_add(&q, &xiom.bigint.bigint_one());
    } elif cmp == 0 {
      if xiom.bigint.bigint_is_odd(&q) {
        q = xiom.bigint.bigint_add(&q, &xiom.bigint.bigint_one());
      }
    }
  }
  return BigFloat{ sign: f.sign; exponent: 0;
                   significand: q; precision: f.precision; };
}

// Fractional part with the sign of f: f - trunc(f).
pub fn bigfloat_fract(f: &BigFloat) -> BigFloat {
  if f.exponent >= 0 {
    return BigFloat{ sign: false; exponent: 0;
                     significand: xiom.bigint.bigint_zero(); precision: f.precision; };
  }
  var split = _split_int_frac(f);
  var result = BigFloat{ sign: f.sign; exponent: -split.d;
                         significand: split.r; precision: f.precision; };
  return _normalize(&result);
}

// Explicit rounding of `f` to `digits` significant digits with `mode`.
pub fn bigfloat_with_rounding(f: &BigFloat, mode: RoundMode, digits: Int) -> BigFloat
  requires: digits >= 1
{
  var r = _round_digits_raw(f, digits, mode);
  return _normalize(&r);
}

// ============================================================================
// Comparisons
// ============================================================================

pub fn bigfloat_compare(a: &BigFloat, b: &BigFloat) -> Int {
  var az = bigfloat_is_zero(a);
  var bz = bigfloat_is_zero(b);
  if az && bz { return 0; }
  if az {
    if b.sign { return 1; }
    return -1;
  }
  if bz {
    if a.sign { return -1; }
    return 1;
  }
  if a.sign != b.sign {
    if a.sign { return -1; }
    return 1;
  }
  var e = a.exponent;
  if b.exponent < e { e = b.exponent; }
  var sa = xiom.bigint.bigint_shift_left(&a.significand, a.exponent - e);
  var sb = xiom.bigint.bigint_shift_left(&b.significand, b.exponent - e);
  var cmp = xiom.bigint.bigint_compare(&sa, &sb);
  if a.sign { return -cmp; }
  return cmp;
}

pub fn bigfloat_eq(a: &BigFloat, b: &BigFloat) -> Bool {
  return bigfloat_compare(a, b) == 0;
}

pub fn bigfloat_lt(a: &BigFloat, b: &BigFloat) -> Bool {
  return bigfloat_compare(a, b) < 0;
}

pub fn bigfloat_le(a: &BigFloat, b: &BigFloat) -> Bool {
  return bigfloat_compare(a, b) <= 0;
}

pub fn bigfloat_gt(a: &BigFloat, b: &BigFloat) -> Bool {
  return bigfloat_compare(a, b) > 0;
}

pub fn bigfloat_ge(a: &BigFloat, b: &BigFloat) -> Bool {
  return bigfloat_compare(a, b) >= 0;
}

// ============================================================================
// PHASE C TODO — Transcendentals (planned signatures, follow-up session)
// ============================================================================
// MPFR-style series with argument reduction; stdlib stays zero-dependency
// (a C MPFR binding would be a PACKAGE, per D3). Planned API:
//
//   pub fn bigfloat_pi_with_precision(precision: Int) -> BigFloat   // Machin series
//   pub fn bigfloat_e_with_precision(precision: Int) -> BigFloat    // Taylor series
//   pub fn bigfloat_exp(f: &BigFloat) -> BigFloat                   // Taylor + range reduction
//   pub fn bigfloat_ln(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_log10(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_sin(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_cos(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_tan(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_atan(f: &BigFloat) -> BigFloat
//   pub fn bigfloat_atan2(y: &BigFloat, x: &BigFloat) -> BigFloat
//   pub fn bigfloat_pow_bf(base: &BigFloat, exp: &BigFloat) -> BigFloat  // via exp(exp*ln(base))
// All honor precision and the current RoundMode; argument reduction needs
// pi() at working precision first.




