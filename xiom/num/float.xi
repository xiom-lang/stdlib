// XIOM - Num: Float
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.float

// Depends on: none

// ============================================================================
// IEEE-754 float inspection: bit patterns, components, classification, and
// next-value operations.
//
// IMPLEMENTATION NOTE: there is NO i64<->f64 bitcast intrinsic in the
// language today (core.to_int / core.to_float are numeric, sitofp/fptosi,
// not reinterprets) and no stdlib module reinterprets float bits (verified:
// bits.xi, core.xi). IEEE NaN/Inf arithmetic semantics were FIXED 2026-08-11
// (BUG 19) — NaN is constructible via 0.0/0.0 and detected via f != f.
//
// Consequences:
//   * float_bits / bits_to_float / float_next_up / float_next_down / float_ulp
//     are implemented as DOCUMENTED FALLBACKS and carry a TODO(compiler)
//     marker — they need a bitcast intrinsic to be exact (still missing).
//   * float_mantissa / float_exponent are implemented exactly via repeated
//     halving/doubling (no bitcast, no precision loss: scaling by powers of
//     two is exact in binary floating point).
//   * float_is_subnormal uses the comparison |f| < 2^-1022 (exact definition).
//   * float_is_nan / classify's "nan" branch use f != f (IEEE-correct).
// ============================================================================

const _MIN_NORMAL: Float64 = 2.2250738585072014e-308;
const _TWO_POW_52: Float64 = 4503599627370496.0;
const _TWO_POW_63: Float64 = 9223372036854775808.0;

// TODO(compiler): needs an i64<->f64 bitcast intrinsic. The raw
// 64-bit IEEE pattern of a Float64 cannot be obtained by arithmetic in
// general (the sign of zero and NaN encodings are not distinguishable through
// numeric casts). Fallback: always 0.
/// Raw 64-bit IEEE-754 bit pattern of f.
/// FALLBACK (TODO(compiler): needs bitcast intrinsic): returns 0 until one
/// lands. Do not rely on the value.
pub fn float_bits(f: Float64) -> Int {
  return 0;
}

// TODO(compiler): needs an i64<->f64 bitcast intrinsic (see above).
/// Float64 reconstructed from a raw 64-bit IEEE-754 bit pattern.
/// FALLBACK (TODO(compiler): needs bitcast intrinsic): returns 0.0 until one
/// lands. Do not rely on the value.
pub fn bits_to_float(bits: Int) -> Float64 {
  return 0.0;
}

/// The significand of f as an integer (implicit leading bit included for
/// normal values; no implicit bit for subnormals). Zero, NaN, and infinities
/// map to 0 (documented). Exact: computed by scaling |f| by exact powers of
/// two until it lies in [1, 2), then multiplying by 2^52 (or 2^(e+1074) for
/// subnormals). Complexity: O(|exponent|) — at most ~1074 iterations.
pub fn float_mantissa(f: Float64) -> Int {
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
/// Exact via repeated halving/doubling. Complexity: O(|e|) — at most ~1074
/// iterations.
pub fn float_exponent(f: Float64) -> Int {
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
pub fn float_is_subnormal(f: Float64) -> Bool {
  if float_is_nan(f) { return false; }
  if float_is_infinite(f) { return false; }
  if f == 0.0 { return false; }
  var x = f;
  if x < 0.0 { x = -x; }
  x < _MIN_NORMAL
}

/// True iff f is NaN (f != f is the IEEE identity).
/// Complexity: O(1).
pub fn float_is_nan(f: Float64) -> Bool {
  f != f
}

/// True iff f is +inf or -inf (checked against 1.0/0.0 and -1.0/0.0).
/// Complexity: O(1).
pub fn float_is_infinite(f: Float64) -> Bool {
  f == 1.0 / 0.0 || f == -1.0 / 0.0
}

// TODO(compiler): needs an i64<->f64 bitcast intrinsic. The exact
// next-value operations are the classic integer ±1 on the bit pattern; the
// fallback returns f unchanged.
/// Smallest Float64 strictly greater than f.
/// FALLBACK (TODO(compiler): needs bitcast intrinsic): returns f unchanged until
/// intrinsic lands (exact next-up needs float_bits). Do not rely on the value.
pub fn float_next_up(f: Float64) -> Float64 {
  return f;
}

// TODO(compiler): needs an i64<->f64 bitcast intrinsic (see above).
/// Largest Float64 strictly less than f.
/// FALLBACK (TODO(compiler): needs bitcast intrinsic): returns f unchanged until
/// intrinsic lands. Do not rely on the value.
pub fn float_next_down(f: Float64) -> Float64 {
  return f;
}

// TODO(compiler): needs an i64<->f64 bitcast intrinsic (see above).
/// Unit in the last place of f: the distance to the next representable value.
/// FALLBACK (TODO(compiler): needs bitcast intrinsic): returns 0.0 until one
/// lands. Do not rely on the value.
pub fn float_ulp(f: Float64) -> Float64 {
  return 0.0;
}

/// Classification string: "nan", "inf", "-inf", "subnormal", "zero", or
/// "normal" (checked in that order). The "nan" branch uses f != f (IEEE).
/// Complexity: O(1).
pub fn float_classify(f: Float64) -> Str {
  // TODO(compiler): needs bitcast intrinsic — see module header. The f != f
  // check is correct (BUG 19 fixed); NaN is constructible via 0.0/0.0.
  if float_is_nan(f) { return "nan"; }
  if f == 1.0 / 0.0 { return "inf"; }
  if f == -1.0 / 0.0 { return "-inf"; }
  if f == 0.0 { return "zero"; }
  if float_is_subnormal(f) { return "subnormal"; }
  "normal"
}
