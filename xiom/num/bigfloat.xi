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

// Copy with a new precision (working-precision plumbing for transcendentals).
fn _set_prec(f: &BigFloat, prec: Int) -> BigFloat {
  var r = _copy_bf(f);
  r.precision = prec;
  return r;
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

/// 10^e as Float128 for e in [-300, 300] via repeated scaling (one loop).
/// Split out of bigfloat_to_float128: a single fn containing MULTIPLE fp128
/// loop shapes crashes at runtime (TODO(compiler): BUG 36, BUG 24 family).
fn _f128_pow10(e: Int) -> Float128 {
  var acc = 1.0 as Float128;
  var k = 0;
  if e >= 0 {
    while k < e {
      acc = acc * (10.0 as Float128);
      k = k + 1;
    }
  } else {
    while k < -e {
      acc = acc / (10.0 as Float128);
      k = k + 1;
    }
  }
  acc
}

/// Apply the sign flag to an fp128 value. Kept as a separate fn: any sign
/// statement inside bigfloat_to_float128 breaks that fn's fp128 codegen
/// shape (TODO(compiler): BUG 36).
fn _f128_neg(acc: Float128, neg: Bool) -> Float128 {
  if neg { (0.0 as Float128) - acc } else { acc }
}

/// Float128 conversion. Same accumulation strategy as bigfloat_to_float64 but
/// in fp128: ~34 significant digits of the significand survive, and the
/// exponent range extends to ~1.1e4932. Values whose exponent exceeds the
/// fp128 range saturate to +/-inf (fp128 IEEE-754 semantics).
/// TODO(compiler): BUG 33 — Option[Float128] payload unwrap emits a load of
/// the undefined `%struct.Float128` (opaque) instead of native `fp128`, so
/// the Option-returning form cannot be consumed yet; returns the value
/// directly until the unwrap path is fixed.
pub fn bigfloat_to_float128(f: &BigFloat) -> Float128 {
  if xiom.bigint.bigint_is_zero(&f.significand) { return 0.0 as Float128; }
  var acc = 0.0 as Float128;
  var i = f.significand.digits.len() - 1;
  while i >= 0 {
    var limb: Int = f.significand.digits[i];
    acc = acc * (1000000000.0 as Float128) + (limb as Float128);
    i = i - 1;
  }
  acc = acc * _f128_pow10(f.exponent);
  return _f128_neg(acc, f.sign);
}

/// Float64 conversion. None on exponent overflow/underflow beyond f64 range
/// (|value| > ~1.8e308); values underflowing to 0.0 return Some(0.0).
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

pub fn bigfloat_is_one(f: &BigFloat) -> Bool {
  var one = _one_at(f.precision);
  return bigfloat_eq(f, &one);
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
// PHASE C — Transcendentals (pure XIOM series; zero external deps)
// ============================================================================
// Strategy: working precision = max(operand precisions, 64) + 4 guard digits;
// all intermediates carry the working precision; the result is rounded back
// to the operand precision with the current RoundMode. Argument reduction
// uses decimal scaling (exact in this representation) and the stored
// constants pi / ln(10) / sqrt(10) computed at working precision.
//
// Complexity is O(prec^2) series (no acceleration); fine for stdlib use up
// to a few thousand digits. Arguments are limited to |x| < ~9e18 (the
// reduction needs x/ln10 or x/(pi/2) to fit an Int).

fn _work_prec(a: &BigFloat, b: &BigFloat) -> Int {
  var p = a.precision;
  if b.precision > p { p = b.precision; }
  if p < 64 { p = 64; }
  return p + 4;
}

fn _one_at(prec: Int) -> BigFloat {
  return BigFloat{ sign: false; exponent: 0;
                   significand: xiom.bigint.bigint_one(); precision: prec; };
}

fn _two_at(prec: Int) -> BigFloat {
  return BigFloat{ sign: false; exponent: 0;
                   significand: xiom.bigint.bigint_two(); precision: prec; };
}

fn _ten_at(prec: Int) -> BigFloat {
  return BigFloat{ sign: false; exponent: 1;
                   significand: xiom.bigint.bigint_one(); precision: prec; };
}

// 10^-(prec+2): series-termination threshold.
fn _epsilon_at(prec: Int) -> BigFloat {
  return BigFloat{ sign: false; exponent: -(prec + 2);
                   significand: xiom.bigint.bigint_one(); precision: prec; };
}

// atan(t) = t - t^3/3 + t^5/5 - ... for |t| <= 0.25 (argument pre-halved).
fn _atan_series(t: &BigFloat, prec: Int) -> BigFloat {
  var t2 = bigfloat_mul(t, t);
  var term = _copy_bf(t);
  var sum = _copy_bf(t);
  var n = 1;
  var subtract = true;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    term = bigfloat_mul(&term, &t2);
    var den = bigfloat_from_int(2 * n + 1);
    var q = bigfloat_div(&term, &den);
    if subtract { sum = bigfloat_sub(&sum, &q); }
    else { sum = bigfloat_add(&sum, &q); }
    if bigfloat_lt(&bigfloat_abs(&q), &eps) { break; }
    subtract = !subtract;
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// atanh(t) = t + t^3/3 + t^5/5 + ... for |t| <= 0.52.
fn _atanh_series(t: &BigFloat, prec: Int) -> BigFloat {
  var t2 = bigfloat_mul(t, t);
  var term = _copy_bf(t);
  var sum = _copy_bf(t);
  var n = 1;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    term = bigfloat_mul(&term, &t2);
    var den = bigfloat_from_int(2 * n + 1);
    var q = bigfloat_div(&term, &den);
    sum = bigfloat_add(&sum, &q);
    if bigfloat_lt(&bigfloat_abs(&q), &eps) { break; }
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// exp(r) = sum r^n / n! for |r| <= ln(10)/2 (decimal-reduced).
fn _exp_series(r: &BigFloat, prec: Int) -> BigFloat {
  var term = _one_at(prec);
  var sum = _one_at(prec);
  var n = 1;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    var nf = bigfloat_from_int(n);
    term = bigfloat_div(&bigfloat_mul(&term, r), &nf);
    sum = bigfloat_add(&sum, &term);
    if bigfloat_lt(&bigfloat_abs(&term), &eps) { break; }
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// sin(r) = r - r^3/3! + r^5/5! - ... for |r| <= pi/4.
fn _sin_series(r: &BigFloat, prec: Int) -> BigFloat {
  var r2neg = bigfloat_neg(&bigfloat_mul(r, r));
  var term = _copy_bf(r);
  var sum = _copy_bf(r);
  var n = 1;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    term = bigfloat_mul(&term, &r2neg);
    term = bigfloat_div(&term, &bigfloat_from_int(2 * n));
    term = bigfloat_div(&term, &bigfloat_from_int(2 * n + 1));
    sum = bigfloat_add(&sum, &term);
    if bigfloat_lt(&bigfloat_abs(&term), &eps) { break; }
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// cos(r) = 1 - r^2/2! + r^4/4! - ... for |r| <= pi/4.
fn _cos_series(r: &BigFloat, prec: Int) -> BigFloat {
  var r2neg = bigfloat_neg(&bigfloat_mul(r, r));
  var term = _one_at(prec);
  var sum = _one_at(prec);
  var n = 1;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    term = bigfloat_mul(&term, &r2neg);
    term = bigfloat_div(&term, &bigfloat_from_int(2 * n - 1));
    term = bigfloat_div(&term, &bigfloat_from_int(2 * n));
    sum = bigfloat_add(&sum, &term);
    if bigfloat_lt(&bigfloat_abs(&term), &eps) { break; }
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// pi to `prec` digits via Machin: pi = 16*atan(1/5) - 4*atan(1/239).
fn _pi_at(prec: Int) -> BigFloat {
  var fifth = BigFloat{ sign: false; exponent: -1;
                        significand: xiom.bigint.bigint_two(); precision: prec; };
  var a = _atan_series(&fifth, prec);
  var one = _one_at(prec);
  var t239 = bigfloat_div(&one, &bigfloat_from_int(239));
  var b = _atan_series(&t239, prec);
  var sixteen = bigfloat_from_int(16);
  var four = bigfloat_from_int(4);
  var pi = bigfloat_sub(&bigfloat_mul(&sixteen, &a), &bigfloat_mul(&four, &b));
  return pi;
}

// e to `prec` digits via e = sum 1/n!.
fn _e_at(prec: Int) -> BigFloat {
  var term = _one_at(prec);
  var sum = _one_at(prec);
  var n = 1;
  var eps = _epsilon_at(prec);
  var limit = 20000;
  while limit > 0 {
    term = bigfloat_div(&term, &bigfloat_from_int(n));
    sum = bigfloat_add(&sum, &term);
    if bigfloat_lt(&bigfloat_abs(&term), &eps) { break; }
    n = n + 1;
    limit = limit - 1;
  }
  return sum;
}

// ln(10) to `prec` digits: ln(10) = 3*ln(2) + 2*atanh(1/9);
// ln(2) = 2*atanh(1/3).
fn _ln10_at(prec: Int) -> BigFloat {
  var one = _one_at(prec);
  var third = bigfloat_div(&one, &bigfloat_from_int(3));
  var ln2 = bigfloat_mul(&_two_at(prec), &_atanh_series(&third, prec));
  var ninth = bigfloat_div(&one, &bigfloat_from_int(9));
  var l = bigfloat_add(&bigfloat_mul(&bigfloat_from_int(3), &ln2),
                       &bigfloat_mul(&_two_at(prec), &_atanh_series(&ninth, prec)));
  return l;
}

// atan(x) for x >= 0, x <= 1: halve the argument until <= 0.25, series, double back.
fn _atan_positive(x: &BigFloat, prec: Int) -> BigFloat {
  var t = _copy_bf(x);
  var doublings = 0;
  var quarter = BigFloat{ sign: false; exponent: -2;
                          significand: xiom.bigint.bigint_from_int(25); precision: prec; };
  var one = _one_at(prec);
  var limit = 100;
  while bigfloat_compare(&t, &quarter) > 0 && limit > 0 {
    // t = t / (1 + sqrt(1 + t^2))   (NOT 1 + sqrt(t^2))
    var t2 = bigfloat_mul(&t, &t);
    var inner = bigfloat_add(&one, &t2);
    var s = bigfloat_add(&one, &bigfloat_sqrt(&inner));
    t = bigfloat_div(&t, &s);
    doublings = doublings + 1;
    limit = limit - 1;
  }
  var result = _atan_series(&t, prec);
  var d = 0;
  while d < doublings {
    result = bigfloat_add(&result, &result);
    d = d + 1;
  }
  return result;
}

fn _finish(result: &BigFloat, target: Int) -> BigFloat {
  var r = _copy_bf(result);
  r.precision = target;
  return _round_to_precision(&r);
}

// pi / e at explicit precision.
pub fn bigfloat_pi_with_precision(precision: Int) -> BigFloat
  requires: precision >= 1
{
  var p = precision;
  if p < 10 { p = 10; }
  var pi = _pi_at(p + 4);
  return _finish(&pi, precision);
}

pub fn bigfloat_e_with_precision(precision: Int) -> BigFloat
  requires: precision >= 1
{
  var p = precision;
  if p < 10 { p = 10; }
  var e = _e_at(p + 4);
  return _finish(&e, precision);
}

// exp(x) = exp(r) * 10^k with r = x - k*ln(10) in [-ln(10)/2, ln(10)/2].
pub fn bigfloat_exp(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  var x = _set_prec(f, prec);
  var l10 = _ln10_at(prec);
  var q = bigfloat_div(&x, &l10);
  var qr = bigfloat_round(&q);
  var qi = bigfloat_to_bigint(&qr);
  var ki = xiom.bigint.bigint_to_int(&qi);
  var k = 0;
  match ki {
    Ok(v) => { k = v; },
    Err(_) => { return bigfloat_zero(); },  // |x| too large for Int reduction
  }
  var r = bigfloat_sub(&x, &bigfloat_mul(&bigfloat_from_int(k), &l10));
  var s = _exp_series(&r, prec);
  // s * 10^k is an exact exponent shift in this representation.
  s.exponent = s.exponent + k;
  return _finish(&s, f.precision);
}

// ln(x): x = m * 10^k with m in [1, 10); reduce m to [1, sqrt(10)) via one
// sqrt; ln(x) = 2*atanh((m-1)/(m+1)) + k*ln(10).
pub fn bigfloat_ln(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(f)
  requires: !bigfloat_is_zero(f)
{
  var prec = _work_prec(f, f);
  var one = _one_at(prec);
  var ten = _ten_at(prec);
  var m = _set_prec(f, prec);
  var k = 0;
  while bigfloat_compare(&m, &ten) >= 0 {
    m = bigfloat_div(&m, &ten);
    k = k + 1;
  }
  while bigfloat_compare(&m, &one) < 0 {
    m = bigfloat_mul(&m, &ten);
    k = k - 1;
  }
  var factor2 = false;
  var root10 = bigfloat_sqrt(&ten);
  if bigfloat_compare(&m, &root10) > 0 {
    m = bigfloat_sqrt(&m);
    factor2 = true;
  }
  var t = bigfloat_div(&bigfloat_sub(&m, &one), &bigfloat_add(&m, &one));
  // ln(m) = 2*atanh(t); the sqrt reduction adds another factor 2.
  var ah = _atanh_series(&t, prec);
  var s = bigfloat_add(&ah, &ah);
  if factor2 { s = bigfloat_add(&s, &s); }
  var l10 = _ln10_at(prec);
  if k != 0 {
    s = bigfloat_add(&s, &bigfloat_mul(&bigfloat_from_int(k), &l10));
  }
  return _finish(&s, f.precision);
}

pub fn bigfloat_log10(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(f)
  requires: !bigfloat_is_zero(f)
{
  var l = bigfloat_ln(f);
  var l10 = _ln10_at(_work_prec(&l, &l));
  return bigfloat_div(&l, &l10);
}

fn _sincos(f: &BigFloat, want_cos: Bool) -> BigFloat {
  var prec = _work_prec(f, f);
  var x = _set_prec(f, prec);
  if want_cos && bigfloat_is_zero(&x) {
    return _finish(&_one_at(prec), f.precision);
  }
  var half_pi = bigfloat_div(&_pi_at(prec), &_two_at(prec));
  var q = bigfloat_round(&bigfloat_div(&x, &half_pi));
  var qi = bigfloat_to_bigint(&q);
  var ki = xiom.bigint.bigint_to_int(&qi);
  var k = 0;
  match ki {
    Ok(v) => { k = v; },
    Err(_) => { return bigfloat_zero(); },  // |x| too large for Int reduction
  }
  var r = bigfloat_sub(&x, &bigfloat_mul(&bigfloat_from_int(k), &half_pi));
  var s = _sin_series(&r, prec);
  var c = _cos_series(&r, prec);
  var qm = k % 4;
  if qm < 0 { qm = qm + 4; }
  var result = _one_at(prec);
  if want_cos {
    if qm == 0 { result = c; }
    elif qm == 1 { result = bigfloat_neg(&s); }
    elif qm == 2 { result = bigfloat_neg(&c); }
    else { result = s; }
  } else {
    if qm == 0 { result = s; }
    elif qm == 1 { result = c; }
    elif qm == 2 { result = bigfloat_neg(&s); }
    else { result = bigfloat_neg(&c); }
  }
  return _finish(&result, f.precision);
}

pub fn bigfloat_sin(f: &BigFloat) -> BigFloat {
  return _sincos(f, false);
}

pub fn bigfloat_cos(f: &BigFloat) -> BigFloat {
  return _sincos(f, true);
}

pub fn bigfloat_tan(f: &BigFloat) -> BigFloat {
  var s = bigfloat_sin(f);
  var c = bigfloat_cos(f);
  return bigfloat_div(&s, &c);
}

// atan(x) in [-pi/2, pi/2].
pub fn bigfloat_atan(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  if bigfloat_is_zero(f) { return bigfloat_zero(); }
  var sign = bigfloat_is_negative(f);
  var x = bigfloat_abs(f);
  x.precision = prec;
  var one = _one_at(prec);
  var result = _one_at(prec);
  if bigfloat_compare(&x, &one) > 0 {
    // atan(x) = pi/2 - atan(1/x)
    var inv = bigfloat_div(&one, &x);
    var half_pi = bigfloat_div(&_pi_at(prec), &_two_at(prec));
    result = bigfloat_sub(&half_pi, &_atan_positive(&inv, prec));
  } else {
    result = _atan_positive(&x, prec);
  }
  if sign { result = bigfloat_neg(&result); }
  return _finish(&result, f.precision);
}

// atan2(y, x) in [-pi, pi].
pub fn bigfloat_atan2(y: &BigFloat, x: &BigFloat) -> BigFloat {
  var prec = _work_prec(y, x);
  var target = y.precision;
  if x.precision > target { target = x.precision; }
  var yz = bigfloat_is_zero(y);
  var xz = bigfloat_is_zero(x);
  var pi = _pi_at(prec);
  var half_pi = bigfloat_div(&pi, &_two_at(prec));
  if yz && !xz {
    if bigfloat_is_negative(x) { return _finish(&pi, target); }
    return _finish(&bigfloat_zero(), target);
  }
  if xz {
    if yz { return _finish(&bigfloat_zero(), target); }
    if bigfloat_is_negative(y) { return _finish(&bigfloat_neg(&half_pi), target); }
    return _finish(&half_pi, target);
  }
  var t = _atan_positive(&bigfloat_abs(&bigfloat_div(y, x)), prec);
  var result = _one_at(prec);
  if !bigfloat_is_negative(x) {
    // x > 0: result = atan(y/x) — sign of y applies.
    result = t;
    if bigfloat_is_negative(y) { result = bigfloat_neg(&result); }
  } else {
    // x < 0: y > 0 -> pi - t; y < 0 -> t - pi.
    if bigfloat_is_negative(y) { result = bigfloat_sub(&t, &pi); }
    else { result = bigfloat_sub(&pi, &t); }
  }
  return _finish(&result, target);
}

// base^exp for base >= 0 via exp(exp * ln(base)); negative exponents via inv.
pub fn bigfloat_pow_bf(base: &BigFloat, exp: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(base)
{
  var target = base.precision;
  if exp.precision > target { target = exp.precision; }
  if bigfloat_is_zero(exp) {
    return _finish(&_one_at(_work_prec(base, exp)), target);
  }
  if bigfloat_is_zero(base) {
    return _finish(&bigfloat_zero(), target);
  }
  if bigfloat_is_negative(exp) {
    var p = bigfloat_pow_bf(base, &bigfloat_neg(exp));
    return bigfloat_inv(&p);
  }
  // BUG 24 fix (2026-08-12): `base` is already `&BigFloat` — `&base` passed
  // the ADDRESS OF THE POINTER SLOT to is_one(f: &BigFloat), which read the
  // slot as a BigFloat struct (garbage → per-program-shape wrong values/AVs
  // in bigfloat_pow_bf). The compiler now rejects double-addresses like this.
  if bigfloat_is_one(base) { return _finish(&_one_at(_work_prec(base, exp)), target); }
  var l = bigfloat_ln(base);
  var prod = bigfloat_mul(exp, &l);
  return bigfloat_exp(&prod);
}

// ============================================================================
// PHASE C.5 — Additional elementary functions (built on the Phase C primitives)
// ============================================================================

// ln(2) to `prec` digits: ln(2) = 2*atanh(1/3).
fn _ln2_at(prec: Int) -> BigFloat {
  var third = bigfloat_div(&_one_at(prec), &bigfloat_from_int(3));
  return bigfloat_mul(&_two_at(prec), &_atanh_series(&third, prec));
}

// log2(x) = ln(x) / ln(2).
pub fn bigfloat_log2(f: &BigFloat) -> BigFloat
  requires: !bigfloat_is_negative(f)
  requires: !bigfloat_is_zero(f)
{
  var l = bigfloat_ln(f);
  var l2 = _ln2_at(_work_prec(&l, &l));
  return bigfloat_div(&l, &l2);
}

// exp2(x) = exp(x * ln(2)).
pub fn bigfloat_exp2(f: &BigFloat) -> BigFloat {
  var l2 = _ln2_at(_work_prec(f, f));
  var prod = bigfloat_mul(f, &l2);
  return bigfloat_exp(&prod);
}

// Cube root (Newton: x = (2x + n/x^2)/3). Works for negative operands via
// sign symmetry; the significand is scaled to a multiple-of-3 exponent so
// the final 10^(exp/3) shift is exact.
pub fn bigfloat_cbrt(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  if bigfloat_is_zero(f) { return bigfloat_zero(); }
  var sign = bigfloat_is_negative(f);
  var x = bigfloat_abs(f);
  x.precision = prec;
  // x = sig * 10^exp; pull the exponent to a multiple of 3.
  var e = x.exponent % 3;
  if e < 0 { e = e + 3; }
  var m = _copy_bf(&x);
  m.exponent = m.exponent - e;
  var n = BigFloat{ sign: false; exponent: 0;
                    significand: xiom.bigint.bigint_shift_left(&m.significand, e);
                    precision: prec; };
  // n in [1, 1000): cbrt in [1, 10); Newton from 10.
  var guess = _ten_at(prec);
  var two = _two_at(prec);
  var three = bigfloat_from_int(3);
  var guard = 0;
  while guard < 30 {
    var x2 = bigfloat_mul(&guess, &guess);
    var next = bigfloat_div(&bigfloat_add(&bigfloat_mul(&two, &guess),
                                          &bigfloat_div(&n, &x2)), &three);
    if bigfloat_eq(&next, &guess) { break; }
    guess = next;
    guard = guard + 1;
  }
  guess.exponent = guess.exponent + m.exponent / 3;
  if sign { guess = bigfloat_neg(&guess); }
  return _finish(&guess, f.precision);
}

// hypot(a, b) = sqrt(a^2 + b^2).
pub fn bigfloat_hypot(a: &BigFloat, b: &BigFloat) -> BigFloat {
  var prec = _work_prec(a, b);
  var target = a.precision;
  if b.precision > target { target = b.precision; }
  var a2 = bigfloat_mul(a, a);
  var b2 = bigfloat_mul(b, b);
  var s = bigfloat_add(&a2, &b2);
  var r = bigfloat_sqrt(&s);
  return _finish(&r, target);
}

// Hyperbolic functions via exp.
pub fn bigfloat_sinh(f: &BigFloat) -> BigFloat {
  var e = bigfloat_exp(f);
  var en = bigfloat_exp(&bigfloat_neg(f));
  return bigfloat_div(&bigfloat_sub(&e, &en), &bigfloat_two());
}

pub fn bigfloat_cosh(f: &BigFloat) -> BigFloat {
  var e = bigfloat_exp(f);
  var en = bigfloat_exp(&bigfloat_neg(f));
  return bigfloat_div(&bigfloat_add(&e, &en), &bigfloat_two());
}

pub fn bigfloat_tanh(f: &BigFloat) -> BigFloat {
  var s = bigfloat_sinh(f);
  var c = bigfloat_cosh(f);
  return bigfloat_div(&s, &c);
}

// asin(x) = atan(x / sqrt(1 - x^2)); asin(+-1) = +-pi/2.
pub fn bigfloat_asin(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  var one = _one_at(prec);
  if bigfloat_eq(f, &one) {
    var half_pi = bigfloat_div(&_pi_at(prec), &_two_at(prec));
    return _finish(&half_pi, f.precision);
  }
  if bigfloat_eq(f, &bigfloat_neg(&one)) {
    var half_pi = bigfloat_div(&_pi_at(prec), &_two_at(prec));
    return _finish(&bigfloat_neg(&half_pi), f.precision);
  }
  var x2 = bigfloat_mul(f, f);
  var inner = bigfloat_sqrt(&bigfloat_sub(&one, &x2));
  var t = bigfloat_div(f, &inner);
  return bigfloat_atan(&t);
}

// acos(x) = pi/2 - asin(x). Exact endpoints: acos(1) = 0, acos(-1) = pi.
pub fn bigfloat_acos(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  var one = _one_at(prec);
  if bigfloat_eq(f, &one) { return bigfloat_zero(); }
  if bigfloat_eq(f, &bigfloat_neg(&one)) {
    return _finish(&_pi_at(prec), f.precision);
  }
  var a = bigfloat_asin(f);
  var hp = bigfloat_div(&_pi_at(prec), &_two_at(prec));
  return bigfloat_sub(&hp, &a);
}

// asinh(x) = ln(x + sqrt(x^2 + 1)).
pub fn bigfloat_asinh(f: &BigFloat) -> BigFloat {
  var prec = _work_prec(f, f);
  var x2 = bigfloat_mul(f, f);
  var inner = bigfloat_sqrt(&bigfloat_add(&x2, &_one_at(prec)));
  var s = bigfloat_add(f, &inner);
  return bigfloat_ln(&s);
}

// acosh(x) = ln(x + sqrt(x^2 - 1)); requires x >= 1.
pub fn bigfloat_acosh(f: &BigFloat) -> BigFloat
  requires: !bigfloat_lt(f, &bigfloat_one())
{
  var prec = _work_prec(f, f);
  var x2 = bigfloat_mul(f, f);
  var inner = bigfloat_sqrt(&bigfloat_sub(&x2, &_one_at(prec)));
  var s = bigfloat_add(f, &inner);
  return bigfloat_ln(&s);
}

// atanh(x) = ln((1 + x)/(1 - x)) / 2; requires |x| < 1.
pub fn bigfloat_atanh(f: &BigFloat) -> BigFloat
  requires: bigfloat_lt(&bigfloat_abs(f), &bigfloat_one())
{
  var prec = _work_prec(f, f);
  var one = _one_at(prec);
  var num = bigfloat_add(&one, f);
  var den = bigfloat_sub(&one, f);
  var l = bigfloat_ln(&bigfloat_div(&num, &den));
  return bigfloat_div(&l, &bigfloat_two());
}

// Scientific notation: d.ddd...e[+-]k with `digits` significant digits.
// Zero renders as "0".
pub fn bigfloat_to_str_sci(f: &BigFloat, digits: Int) -> Str
  requires: digits >= 1
{
  if bigfloat_is_zero(f) { return "0"; }
  var raw = _round_digits_raw(f, digits, _default_round);
  var r = _normalize(&raw);
  var sig = xiom.bigint.bigint_to_str(&r.significand);
  var n = sig.len();
  var e10 = r.exponent + n - 1;
  var mantissa: Str = "";
  if n == 1 {
    mantissa = sig;
  } else {
    mantissa = xiom.string.str_concat(xiom.string.str_slice(sig, 0, 1), ".");
    mantissa = xiom.string.str_concat(mantissa, xiom.string.str_slice(sig, 1, n));
  }
  var prefix = "";
  if r.sign { prefix = "-"; }
  var es = "";
  if e10 < 0 { es = "-"; e10 = -e10; }
  else { es = "+"; }
  var body = xiom.string.str_concat(mantissa, "e");
  body = xiom.string.str_concat(body, es);
  body = xiom.string.str_concat(body, xiom.core.to_string(e10));
  return xiom.string.str_concat(prefix, body);
}

// Exact rational n/d at the default precision.
pub fn bigfloat_from_ratio(n: Int, d: Int) -> BigFloat
  requires: d != 0
{
  if d == 0 { return bigfloat_zero(); }
  return bigfloat_div(&bigfloat_from_int(n), &bigfloat_from_int(d));
}

// Exact x * 10^n (pure exponent shift; no rounding).
pub fn bigfloat_pow10(f: &BigFloat, n: Int) -> BigFloat {
  var r = _copy_bf(f);
  r.exponent = r.exponent + n;
  return r;
}

// Integer-valued helpers (range-checked to i64).
pub fn bigfloat_floor_int(f: &BigFloat) -> Result[Int, Str] {
  return xiom.bigint.bigint_to_int(&bigfloat_to_bigint(&bigfloat_floor(f)));
}

pub fn bigfloat_ceil_int(f: &BigFloat) -> Result[Int, Str] {
  return xiom.bigint.bigint_to_int(&bigfloat_to_bigint(&bigfloat_ceil(f)));
}

pub fn bigfloat_round_int(f: &BigFloat) -> Result[Int, Str] {
  return xiom.bigint.bigint_to_int(&bigfloat_to_bigint(&bigfloat_round(f)));
}

pub fn bigfloat_trunc_int(f: &BigFloat) -> Result[Int, Str] {
  return xiom.bigint.bigint_to_int(&bigfloat_to_bigint(&bigfloat_trunc(f)));
}




