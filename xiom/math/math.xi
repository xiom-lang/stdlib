// XIOM -- Math Library
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math

use xiom.math.number_theory;
use xiom.math.factorial;
use xiom.math.modular;

use xiom.math.calculus;
use xiom.math.differential_equations;
use xiom.math.combinatorics;
use xiom.math.graph_theory;
use xiom.math.algebra;
use xiom.math.primitives;
use xiom.math.vectors;
use xiom.math.matrices;
use xiom.math.trig;
use xiom.math.transcendental;
use xiom.math.differential;
use xiom.math.integral;
use xiom.math.series;
use xiom.math.special;

// D4b manifest (2026-08-10): importing xiom.math pulls in the generic
// sub-modules. math/core hosts the generic numeric tower (3c) -- one
// implementation per concept serving every Num width.
use xiom.math.tower;
use xiom.math.numerical;
use xiom.math.signal;
use xiom.math.optimization;
use xiom.math.finance;
use xiom.math.constants;
use xiom.math.precision;
use xiom.math.interfaces;
use xiom.math.arithmetic;
use xiom.math.roots;
use xiom.math.exponential;
use xiom.math.rounding;
use xiom.math.decompose;
use xiom.math.trigonometry;
use xiom.math.inverse_trig;
use xiom.math.hyperbolic;
use xiom.math.trigonometric_constants;
use xiom.math.angular;
use xiom.math.set_theory;
use xiom.math.logic;
use xiom.math.information_theory;
use xiom.math.chaos;
use xiom.math.game_theory;
use xiom.math.queueing;
use xiom.math.control_theory;
use xiom.math.machine_learning;
use xiom.math.topology;
use xiom.math.number_systems;
use xiom.math.mathematical_logic;
use xiom.math.approximation;
use xiom.math.fuzzy;
use xiom.math.mathematical_physics;
use xiom.math.operations_research;
use xiom.math.mathematical_biology;
use xiom.math.mathematical_economics;
use xiom.math.algebra_extended;

use xiom.core.INT_MAX;
use xiom.core.INT_MIN;
use xiom.core.to_int;
use xiom.core.to_float;

// Fast math FFI -- uses C standard math library (libm)
// Link with -lm on Unix, automatically linked on Windows
extern "C" {
  fn sin(x: Float64) -> Float64;
  fn cos(x: Float64) -> Float64;
  fn tan(x: Float64) -> Float64;
  fn asin(x: Float64) -> Float64;
  fn acos(x: Float64) -> Float64;
  fn atan(x: Float64) -> Float64;
  fn atan2(y: Float64, x: Float64) -> Float64;
  fn sqrt(x: Float64) -> Float64;
  fn pow(base: Float64, exp: Float64) -> Float64;
  fn exp(x: Float64) -> Float64;
  fn log(x: Float64) -> Float64;
  fn log10(x: Float64) -> Float64;
  fn floor(x: Float64) -> Float64;
  fn ceil(x: Float64) -> Float64;
  fn fabs(x: Float64) -> Float64;
  fn fmod(x: Float64, y: Float64) -> Float64;
}

/// === Constants ===
pub const PI: Float64 = 3.141592653589793;
/// Euler's number e.
pub const E: Float64 = 2.718281828459045;
/// Full-circle constant tau (2*pi).
pub const TAU: Float64 = 6.283185307179586;

// === RNG State ===
var _rng_state: Int = 12345;

// === Internal helpers ===

fn _pow2(n: Int) -> Int {
  if n <= 0 { return 1; }
  var result = 1;
  var i = 0;
  while i < n {
    result = result * 2;
    i = i + 1;
  }
  return result;
}

fn _normalize_angle(x: Float64) -> Float64 {
  var result = x;
  while result > PI {
    result = result - TAU;
  }
  while result < -PI {
    result = result + TAU;
  }
  return result;
}

fn _sin_taylor(x: Float64) -> Float64 {
  var result = x;
  var term = x;
  var i = 1;
  while i <= 10 {
    term = -term * x * x / (((2 * i) * (2 * i + 1)) as Float64);
    result = result + term;
    i = i + 1;
  }
  return result;
}

fn _cos_taylor(x: Float64) -> Float64 {
  var result = 1.0;
  var term = 1.0;
  var i = 1;
  while i <= 10 {
    term = -term * x * x / (((2 * i - 1) * (2 * i)) as Float64);
    result = result + term;
    i = i + 1;
  }
  return result;
}

fn _atan_small(x: Float64) -> Float64 {
  var result = x;
  var term = x;
  var x2 = x * x;
  var i = 1;
  while i <= 15 {
    term = -term * x2;
    result = result + term / (2.0 * (i as Float64) + 1.0);
    i = i + 1;
  }
  return result;
}

fn _ln_impl(x: Float64) -> Float64 {
  if x <= 0.0 { return 0.0 / 0.0; }
  var y = (x - 1.0) / (x + 1.0);
  var y2 = y * y;
  var result = y;
  var term = y;
  var i = 1;
  while i <= 25 {
    term = term * y2;
    result = result + term / (2.0 * (i as Float64) + 1.0);
    i = i + 1;
  }
  return 2.0 * result;
}

fn _extract_lower(a: Int) -> Int {
  if a >= 0 { return a; }
  return INT_MAX + a + 1;
}

fn _combine_signed(sign: Bool, lower: Int) -> Int {
  if sign { return lower + INT_MIN; }
  return lower;
}

// === Basic ===

/// Square root of `x` via libm. Requires `x >= 0`.
pub fn sqrt(x: Float64) -> Float64
  requires: x >= 0.0
  ensures:  result >= 0.0
{
  unsafe { return sqrt(x); }
}

/// `base` raised to `exp` via libm. A negative base requires an integer
/// exponent.
pub fn pow(base: Float64, exp: Float64) -> Float64
  requires: base >= 0.0 || exp == to_int(exp)  // negative base only for integer exp
{
  unsafe { return pow(base, exp); }
}

/// Absolute value of an Int, returned as Int.
pub fn abs_int(x: Int) -> Int {
  if x >= 0 { return x; }
  return -x;
}

/// Absolute value of a Float64 via libm `fabs`.
pub fn abs_float(x: Float64) -> Float64
  requires: true
{
  unsafe { return fabs(x); }
}

/// Smaller of two Ints.
pub fn min_int(a: Int, b: Int) -> Int {
  if a < b { return a; }
  return b;
}

/// Larger of two Ints.
pub fn max_int(a: Int, b: Int) -> Int {
  if a > b { return a; }
  return b;
}

/// Smaller of two Float64s.
pub fn min_float(a: Float64, b: Float64) -> Float64 {
  if a < b { return a; }
  return b;
}

/// Larger of two Float64s.
pub fn max_float(a: Float64, b: Float64) -> Float64 {
  if a > b { return a; }
  return b;
}

/// Largest integer not greater than `x` (libm `floor`).
pub fn floor(x: Float64) -> Float64
  requires: true
{
  unsafe { return floor(x); }
}

/// Smallest integer not less than `x` (libm `ceil`).
pub fn ceil(x: Float64) -> Float64
  requires: true
{
  unsafe { return ceil(x); }
}

/// Nearest integer to `x`, halves rounded away from zero.
pub fn round(x: Float64) -> Int {
  if x >= 0.0 { return to_int(x + 0.5); }
  return to_int(x - 0.5);
}

// === Trig ===

/// Sine of `x` radians (libm).
pub fn sin(x: Float64) -> Float64
  requires: true
{
  unsafe { return sin(x); }
}

/// Cosine of `x` radians (libm).
pub fn cos(x: Float64) -> Float64
  requires: true
{
  unsafe { return cos(x); }
}

/// Tangent of `x` radians (libm).
pub fn tan(x: Float64) -> Float64
  requires: true
{
  unsafe { return tan(x); }
}

/// Arc sine of `x` in [-pi/2, pi/2]; requires `x` in [-1, 1] (libm).
pub fn asin(x: Float64) -> Float64
  requires: x >= -1.0 && x <= 1.0
{
  unsafe { return asin(x); }
}

/// Arc cosine of `x` in [0, pi]; requires `x` in [-1, 1] (libm).
pub fn acos(x: Float64) -> Float64
  requires: x >= -1.0 && x <= 1.0
{
  unsafe { return acos(x); }
}

/// Arc tangent of `x` in [-pi/2, pi/2] (libm).
pub fn atan(x: Float64) -> Float64
  requires: true
{
  unsafe { return atan(x); }
}

/// Arc tangent of `y/x` using both signs to pick the quadrant; `(0, 0)` is
/// rejected (libm `atan2`).
pub fn atan2(y: Float64, x: Float64) -> Float64
  requires: x != 0.0 || y != 0.0  // both zero is undefined
{
  unsafe { return atan2(y, x); }
}

// === Log/Exp ===

fn exp_inner(x: Float64) -> Float64 {
  if x < -700.0 { return 0.0; }
  if x > 700.0 { return 1.0 / 0.0; }
  var neg = x < 0.0;
  var val = x;
  if neg { val = -val; }
  var scale = 1;
  while val > 1.0 {
    val = val / 2.0;
    scale = scale * 2;
  }
  var result = 1.0;
  var term = 1.0;
  var i = 1;
  while i <= 25 {
    term = term * val / (i as Float64);
    result = result + term;
    i = i + 1;
  }
  var j = 1;
  while j < scale {
    result = result * result;
    j = j * 2;
  }
  if neg { return 1.0 / result; }
  return result;
}

/// e raised to `x` (libm).
pub fn exp(x: Float64) -> Float64
  requires: true
{
  unsafe { return exp(x); }
}

/// Natural logarithm of `x`; requires `x > 0` (libm).
pub fn ln(x: Float64) -> Float64
  requires: x > 0.0
{
  unsafe { return log(x); }
}

/// Base-10 logarithm of `x`; requires `x > 0` (libm).
pub fn log10(x: Float64) -> Float64
  requires: x > 0.0
{
  unsafe { return log10(x); }
}

/// Base-2 logarithm of `x`; requires `x > 0` (derived from libm `log`).
pub fn log2(x: Float64) -> Float64
  requires: x > 0.0
{
  unsafe { return log(x) / log(2.0); }
}

// === Bitwise ===

/// Bitwise AND of two Ints (two's-complement semantics, sign preserved).
pub fn bit_and(a: Int, b: Int) -> Int {
  var sign_a = a < 0;
  var sign_b = b < 0;
  var lower_a = _extract_lower(a);
  var lower_b = _extract_lower(b);
  var result = 0;
  var bit_val = 1;
  var aa = lower_a;
  var bb = lower_b;
  while aa > 0 || bb > 0 {
    if aa % 2 == 1 && bb % 2 == 1 {
      result = result + bit_val;
    }
    aa = aa / 2;
    bb = bb / 2;
    bit_val = bit_val * 2;
  }
  return _combine_signed(sign_a && sign_b, result);
}

/// Bitwise OR of two Ints (two's-complement semantics, sign preserved).
pub fn bit_or(a: Int, b: Int) -> Int {
  var sign_a = a < 0;
  var sign_b = b < 0;
  var lower_a = _extract_lower(a);
  var lower_b = _extract_lower(b);
  var result = 0;
  var bit_val = 1;
  var aa = lower_a;
  var bb = lower_b;
  while aa > 0 || bb > 0 {
    if aa % 2 == 1 || bb % 2 == 1 {
      result = result + bit_val;
    }
    aa = aa / 2;
    bb = bb / 2;
    bit_val = bit_val * 2;
  }
  return _combine_signed(sign_a || sign_b, result);
}

/// Bitwise XOR of two Ints (two's-complement semantics, sign preserved).
pub fn bit_xor(a: Int, b: Int) -> Int {
  var sign_a = a < 0;
  var sign_b = b < 0;
  var lower_a = _extract_lower(a);
  var lower_b = _extract_lower(b);
  var result = 0;
  var bit_val = 1;
  var aa = lower_a;
  var bb = lower_b;
  while aa > 0 || bb > 0 {
    if aa % 2 != bb % 2 {
      result = result + bit_val;
    }
    aa = aa / 2;
    bb = bb / 2;
    bit_val = bit_val * 2;
  }
  return _combine_signed(sign_a != sign_b, result);
}

/// Bitwise complement of `a` (equivalent to `-1 - a`).
pub fn bit_not(a: Int) -> Int {
  return -1 - a;
}

/// Logical shift left by `n` bits; `n <= 0` returns `a` unchanged, `n >= 64`
/// returns 0.
pub fn shl(a: Int, n: Int) -> Int {
  if n <= 0 { return a; }
  if n >= 64 { return 0; }
  if n == 63 {
    if a % 2 == 0 { return 0; }
    return INT_MIN;
  }
  return a * _pow2(n);
}

/// Arithmetic shift right by `n` bits; `n <= 0` returns `a` unchanged, and
/// negative values shift in sign bits.
pub fn shr(a: Int, n: Int) -> Int {
  if n <= 0 { return a; }
  if n >= 64 {
    if a < 0 { return -1; }
    return 0;
  }
  if n == 63 {
    if a < 0 { return -1; }
    return 0;
  }
  var p = _pow2(n);
  if a >= 0 { return a / p; }
  if a % p == 0 { return a / p; }
  return a / p - 1;
}

// === Random ===

/// Seed the module-level Lehmer RNG; seed 0 is mapped to 1.
pub fn seed_rng(seed: Int) {
  if seed == 0 {
    _rng_state = 1;
  } else {
    _rng_state = seed;
  }
}

/// Next pseudo-random Float64 in [0, 1) from the module RNG (minstd LCG).
pub fn random() -> Float64
  ensures: result >= 0.0
  ensures: result < 1.0
{
  _rng_state = (_rng_state * 48271) % 2147483647;
  if _rng_state <= 0 {
    _rng_state = _rng_state + 2147483647;
  }
  return (_rng_state as Float64) / 2147483647.0;
}

/// Uniform Int in [min, max] (inclusive) from the module RNG.
pub fn random_range(min: Int, max: Int) -> Int
  requires: min <= max
  ensures:  result >= min
  ensures:  result <= max
{
  var f = random();
  var range = max - min + 1;
  var val = to_int(f * (range as Float64));
  if val >= range { val = range - 1; }
  return min + val;
}

/// Alias of `random`; the next Float64 in [0, 1).
pub fn random_float() -> Float64 {
  return random();
}

// === Misc ===

/// Clamp `x` into [lo, hi]; assumes `lo <= hi`.
pub fn clamp(x: Float64, lo: Float64, hi: Float64) -> Float64 {
  if x < lo { return lo; }
  if x > hi { return hi; }
  return x;
}

/// Linear interpolation: `a + (b - a) * t` (no clamping of `t`).
pub fn lerp(a: Float64, b: Float64, t: Float64) -> Float64 {
  return a + (b - a) * t;
}

/// True when `x` is NaN (`x != x`).
pub fn is_nan(x: Float64) -> Bool {
  return x != x;
}

/// True when `x` is positive or negative infinity.
pub fn is_inf(x: Float64) -> Bool {
  return x == 1.0 / 0.0 || x == -1.0 / 0.0;
}

// === Pure XIOM fallbacks (no libm required) ===
// These are the original Taylor series / iterative implementations
// available when libm FFI is unavailable or precision is preferred.

/// Pure-XIOM square root (Newton iteration); no libm needed.
pub fn sqrt_pure(x: Float64) -> Float64
  requires: x >= 0.0
  ensures:  result >= 0.0
{
  if x < 0.0 { return -1.0; }
  if x == 0.0 { return 0.0; }
  var guess = x / 2.0;
  var i = 0;
  while i < 50 {
    guess = (guess + x / guess) / 2.0;
    i = i + 1;
  }
  return guess;
}

/// Pure-XIOM `base ^ exp` via `exp(exp * ln(base))`; negative base requires an
/// integer exponent.
pub fn pow_pure(base: Float64, exp: Float64) -> Float64
  requires: base >= 0.0 || exp == to_int(exp)
{
  if exp == 0.0 { return 1.0; }
  if base == 0.0 { return 0.0; }
  if base < 0.0 { return -1.0; }
  return exp_inner(exp * _ln_impl(base));
}

/// Pure-XIOM absolute value of a Float64.
pub fn abs_float_pure(x: Float64) -> Float64 {
  if x >= 0.0 { return x; }
  return -x;
}

/// Pure-XIOM floor (truncation adjusted for negatives).
pub fn floor_pure(x: Float64) -> Float64 {
  var i = to_int(x);
  if x >= 0.0 { return to_float(i); }
  if to_float(i) == x { return to_float(i); }
  return to_float(i - 1);
}

/// Pure-XIOM ceil (truncation adjusted for positives).
pub fn ceil_pure(x: Float64) -> Float64 {
  var i = to_int(x);
  if x <= 0.0 { return to_float(i); }
  if to_float(i) == x { return to_float(i); }
  return to_float(i + 1);
}

/// Pure-XIOM sine via angle reduction + 10-term Taylor series.
pub fn sin_pure(x: Float64) -> Float64 {
  return _sin_taylor(_normalize_angle(x));
}

/// Pure-XIOM cosine via angle reduction + 10-term Taylor series.
pub fn cos_pure(x: Float64) -> Float64 {
  return _cos_taylor(_normalize_angle(x));
}

/// Pure-XIOM tangent as `sin_pure / cos_pure`.
pub fn tan_pure(x: Float64) -> Float64 {
  return sin_pure(x) / cos_pure(x);
}

/// Pure-XIOM arc sine; requires `x` in [-1, 1].
pub fn asin_pure(x: Float64) -> Float64
  requires: x >= -1.0 && x <= 1.0
{
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  if x == 1.0 { return PI / 2.0; }
  if x == -1.0 { return -PI / 2.0; }
  return atan_pure(x / sqrt_pure(1.0 - x * x));
}

/// Pure-XIOM arc cosine; requires `x` in [-1, 1].
pub fn acos_pure(x: Float64) -> Float64
  requires: x >= -1.0 && x <= 1.0
{
  if x < -1.0 || x > 1.0 { return 0.0 / 0.0; }
  return PI / 2.0 - asin_pure(x);
}

/// Pure-XIOM arc tangent via series with reciprocal reduction.
pub fn atan_pure(x: Float64) -> Float64 {
  if x > 1.0 { return PI / 2.0 - _atan_small(1.0 / x); }
  if x < -1.0 { return -PI / 2.0 - _atan_small(1.0 / x); }
  return _atan_small(x);
}

/// Pure-XIOM two-argument arc tangent with quadrant selection; rejects
/// `(0, 0)`.
pub fn atan2_pure(y: Float64, x: Float64) -> Float64
  requires: x != 0.0 || y != 0.0
{
  if x > 0.0 { return atan_pure(y / x); }
  if x < 0.0 {
    if y >= 0.0 { return atan_pure(y / x) + PI; }
    return atan_pure(y / x) - PI;
  }
  if y > 0.0 { return PI / 2.0; }
  if y < 0.0 { return -PI / 2.0; }
  return 0.0;
}

/// Pure-XIOM `e ^ x` via range reduction + 25-term series (overflow guard).
pub fn exp_pure(x: Float64) -> Float64 {
  return exp_inner(x);
}

/// Pure-XIOM natural logarithm with atanh series; requires `x > 0`.
pub fn ln_pure(x: Float64) -> Float64
  requires: x > 0.0
{
  return _ln_impl(x);
}

/// Pure-XIOM base-10 logarithm; requires `x > 0`.
pub fn log10_pure(x: Float64) -> Float64
  requires: x > 0.0
{
  return _ln_impl(x) / 2.302585092994046;
}

/// Pure-XIOM base-2 logarithm; requires `x > 0`.
pub fn log2_pure(x: Float64) -> Float64
  requires: x > 0.0
{
  return _ln_impl(x) / 0.6931471805599453;
}

