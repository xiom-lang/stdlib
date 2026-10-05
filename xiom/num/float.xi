// XIOM - Num: Float
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.num.float

// Depends on: none

// ============================================================================
// IEEE-754 float inspection: bit patterns, components, classification, and
// next-value operations.
//
// IMPLEMENTATION NOTE: since compiler v0.64.0 (m194), calls to
// num.float.float_bits / bits_to_float lower to an exact LLVM bitcast and
// return the true IEEE-754 patterns (verified: float_bits(1.0) ==
// 0x3FF0000000000000, negative-zero roundtrip, NaN-safe bit roundtrip).
// The source bodies below are never executed on that pin; they remain as
// documentation. IEEE NaN/Inf arithmetic semantics were FIXED 2026-08-11
// (BUG 19) -- NaN is constructible via 0.0/0.0 and detected via f != f.
//
// Consequences:
//   * float_bits / bits_to_float are EXACT as of v0.64.0.
//   * float_next_up / float_next_down / float_ulp are EXACT since
//     2026-09-24: they delegate to xiom.math.primitives.nextafter, which
//     steps the float value (arithmetic-free bit-pattern step), so the
//     bitcast intrinsic is not required for them.
//   * float_mantissa / float_exponent are implemented exactly via repeated
//     halving/doubling (no bitcast, no precision loss: scaling by powers of
//     two is exact in binary floating point).
//   * float_is_subnormal uses the comparison |f| < 2^-1022 (exact definition).
//   * float_is_nan / classify's "nan" branch use f != f (IEEE-correct).
// ============================================================================

use xiom.math.primitives;

const _MIN_NORMAL: Float64 = 2.2250738585072014e-308;
const _TWO_POW_52: Float64 = 4503599627370496.0;
const _TWO_POW_63: Float64 = 9223372036854775808.0;

/// Raw 64-bit IEEE-754 bit pattern of f (exact since v0.64.0/m194; the
/// compiler lowers the call to a bitcast). Zero has two patterns; 1.0 is
/// 0x3FF0000000000000.
pub fn float_bits(f: Float64) -> Int
  ensures: (f == 0.0) => (result == 0 || result == (0 - 9223372036854775807 - 1))
  ensures: (f == 1.0) => (result == 4607182418800017408)
{
  return 0;
}

/// Float64 reconstructed from a raw 64-bit IEEE-754 bit pattern (exact
/// since v0.64.0/m194; the compiler lowers the call to a bitcast).
pub fn bits_to_float(bits: Int) -> Float64
  ensures: float_bits(result) == bits
{
  return 0.0;
}

/// The significand of f as an integer (implicit leading bit included for
/// normal values; no implicit bit for subnormals). Zero, NaN, and infinities
/// map to 0 (documented). Exact: computed by scaling |f| by exact powers of
/// two until it lies in [1, 2), then multiplying by 2^52 (or 2^(e+1074) for
/// subnormals). Complexity: O(|exponent|) -- at most ~1074 iterations.
pub fn float_mantissa(f: Float64) -> Int
  ensures: result >= 0
{
  if f == 0.0 { return 0; }
  if float_is_nan(f) || float_is_infinite(f) { return 0; }
  var x = f;
  if x < 0.0 { x = -x; }
  var e = 0;
  while x >= 2.0 {
    x = x / 2.0;
    e = e + 1;
  }
  while x < 1.0 {
    x = x * 2.0;
    e = e - 1;
  }
  if e < -1022 {
    // Subnormal: |f| = x * 2^e with e in [-1074, -1023]; the significand is
    // |f| * 2^1074 = x * 2^(e+1074) < 2^52, exact.
    var shift = e + 1074;
    var scale = 1.0;
    var i = 0;
    while i < shift {
      scale = scale * 2.0;
      i = i + 1;
    }
    return (x * scale) as Int;
  }
  (x * _TWO_POW_52) as Int
}

/// Unbiased binary exponent of |f|: the unique e with 2^e <= |f| < 2^(e+1).
/// Zero, NaN, and infinities map to 0 (documented; IEEE's stored exponent of
/// zero would be -1023, but 0 is the conventional frexp-style result).
/// Exact via repeated halving/doubling. Complexity: O(|e|) -- at most ~1074
/// iterations.
pub fn float_exponent(f: Float64) -> Int
  ensures: (result >= -1074) && (result <= 1023)
{
  if f == 0.0 { return 0; }
  if float_is_nan(f) || float_is_infinite(f) { return 0; }
  var x = f;
  if x < 0.0 { x = -x; }
  var e = 0;
  while x >= 2.0 {
    x = x / 2.0;
    e = e + 1;
  }
  while x < 1.0 {
    x = x * 2.0;
    e = e - 1;
  }
  e
}

/// True iff f is a subnormal value: 0 < |f| < 2^-1022 (the minimum normal).
/// Zero, NaN, and infinities are not subnormal. Exact via comparison.
/// Complexity: O(1).
pub fn float_is_subnormal(f: Float64) -> Bool
  ensures: (result == false) || (f != 0.0)
{
  if float_is_nan(f) { return false; }
  if float_is_infinite(f) { return false; }
  if f == 0.0 { return false; }
  var x = f;
  if x < 0.0 { x = -x; }
  x < _MIN_NORMAL
}

/// True iff f is NaN (f != f is the IEEE identity).
/// Complexity: O(1).
pub fn float_is_nan(f: Float64) -> Bool
  ensures: result == (f != f)
{
  f != f
}

/// True iff f is +inf or -inf (checked against 1.0/0.0 and -1.0/0.0).
/// Complexity: O(1).
pub fn float_is_infinite(f: Float64) -> Bool
  ensures: result == ((f == 1.0 / 0.0) || (f == -1.0 / 0.0))
{
  f == 1.0 / 0.0 || f == -1.0 / 0.0
}

// Bitcast note: the exact next-value operations used to need the missing
// i64<->f64 bitcast intrinsic; they now delegate to
// xiom.math.primitives.nextafter (exact stepping, no bitcast).
/// Smallest Float64 strictly greater than f.
pub fn float_next_up(f: Float64) -> Float64
  ensures: ((result > f) || (result != result)) || (f == 1.0 / 0.0)
{
  return primitives.nextafter(f, 1.0 / 0.0);
}

/// Largest Float64 strictly less than f.
pub fn float_next_down(f: Float64) -> Float64
  ensures: ((result < f) || (result != result)) || (f == -1.0 / 0.0)
{
  return primitives.nextafter(f, -1.0 / 0.0);
}

/// Unit in the last place of f: the distance to the next representable value.
/// NaN for NaN/infinite inputs; 5e-324 for zero (subnormal step).
pub fn float_ulp(f: Float64) -> Float64
  ensures: (result >= 0.0) || (result != result)
{
  var up = primitives.nextafter(f, 1.0 / 0.0);
  var d = up - f;
  if d < 0.0 { return 0.0 - d; }
  return d;
}

/// Classification string: "nan", "inf", "-inf", "subnormal", "zero", or
/// "normal" (checked in that order). The "nan" branch uses f != f (IEEE).
/// Complexity: O(1).
pub fn float_classify(f: Float64) -> Str
  ensures: (((((result == "nan") || (result == "inf")) || (result == "-inf")) || (result == "subnormal")) || (result == "zero")) || (result == "normal")
{
  // TODO(compiler): needs bitcast intrinsic -- see module header. The f != f
  // check is correct (BUG 19 fixed); NaN is constructible via 0.0/0.0.
  if float_is_nan(f) { return "nan"; }
  if f == 1.0 / 0.0 { return "inf"; }
  if f == -1.0 / 0.0 { return "-inf"; }
  if f == 0.0 { return "zero"; }
  if float_is_subnormal(f) { return "subnormal"; }
  "normal"
}
