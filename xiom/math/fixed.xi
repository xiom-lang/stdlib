// XIOM - Math: Fixed-Point Kernels
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.fixed

// Depends on: xiom.math.int (light), xiom.core. This module deliberately does
// NOT import the xiom.math barrel: the whole surface is pure XIOM integer
// arithmetic (128-bit intermediates) with no extern-C libm, so fixed-point /
// ML / codec consumers can use it standalone.
//
// Representation: a real value v is carried as the Int round(v * scale) for
// a positive scale S ("scaled integers"). Every function documents its
// rounding rule and its guard behaviour.
//
// Wave-165 wishlist rows:
//   11 -- scale-once multiply kernels mul(a,b,scale) + guarded sums
//         (sum_mul dot kernel, sum_sq norm kernel) that accumulate exactly in
//         128 bits and divide by the scale once.
//   27 -- fixed-point log2 (documented error) and the shared ln/exp/log2
//         machinery.
//   12 -- fixed-point sin/cos with 2*pi range reduction (degree-11 Taylor).
//   16 -- exp / ln / integer pow_class transcendentals with saturating
//         overflow guards.
//   8  -- fixed-point MSE matching the float stats semantics
//         (mean of squared errors), scale-once accumulation.
//   14 -- linear interpolation over an ordered (tick, value) table.
//   17 -- exact-sum softmax: floor + residue-to-max, denominator accumulated
//         exactly in 128 bits so long inputs do not drift.
//
// Supported scale domain: 1 <= scale <= 17592186044416 for sin/cos (2^44);
// the other functions accept any positive scale. Out-of-domain scales return
// 0 on the trig surface (documented per function).
// NOTE: requires/ensures clauses are runtime-enforced in this compiler and
// crash on violation, so all domain handling is guarded inside the bodies.

use xiom.math.int;
use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

// ---------------------------------------------------------------------------
// Internal 128-bit helpers
// ---------------------------------------------------------------------------

// |v| as an Int128 (INT_MIN-safe: the cast widens before negation).
fn _abs128(v: Int128) -> Int128 {
  if v < 0 { return 0 - v; }
  return v;
}

// floor(|n| / d) for n >= 0, d > 0 via 127-step restoring long division.
// This deliberately does NOT use the `/` operator: the pinned compiler
// miscompiles a runtime `sdiv i128` that gets inlined into a function which
// also contains a vector element-load loop (AV 0xC0000005 at run time; see
// the wave-165 entry in tools/known_failures/README.md). Shift/mask forms
// lower cleanly. Domain: n < 2^126, d <= 2^126 (all callers' ranges).
fn _divmod_pos(n: Int128, d: Int128) -> Int128 {
  var q: Int128 = 0;
  var r: Int128 = 0;
  var i = 126;
  while i >= 0 {
    r = r + r + ((n >> i) & (1 as Int128));
    var bit: Int128 = 0;
    if r >= d {
      r = r - d;
      bit = 1;
    }
    q = q + q + bit;
    i = i - 1;
  }
  return q;
}

// trunc(n / d) in 128 bits (sign of the quotient), no sdiv i128.
fn _div_trunc_i128(n: Int128, d: Int128) -> Int128 {
  var neg = (n < 0) != (d < 0);
  var q = _divmod_pos(_abs128(n), _abs128(d));
  if neg { q = 0 - q; }
  return q;
}

// round(n / d) to nearest, halves away from zero, in 128 bits.
// Caller guarantees d != 0; |n| and |d| stay under 2^126.
fn _div_round_i128(n: Int128, d: Int128) -> Int128 {
  var neg = (n < 0) != (d < 0);
  var na = _abs128(n);
  var da = _abs128(d);
  var q = _divmod_pos(na, da);
  var r = na - q * da;
  var twice = r + r;
  if twice >= da { q = q + 1; }
  if neg { q = 0 - q; }
  return q;
}

// Clamp a 128-bit intermediate back into the Int range.
fn _sat64(q: Int128) -> Int {
  var hi: Int128 = INT_MAX as Int128;
  var lo: Int128 = INT_MIN as Int128;
  if q > hi { return INT_MAX; }
  if q < lo { return INT_MIN; }
  return q as Int;
}

// 2^k for 0 <= k <= 63 (loop form; no shift reliance).
fn _pow2_i128(k: Int) -> Int128 {
  var r: Int128 = 1;
  var i = 0;
  while i < k {
    r = r * 2;
    i = i + 1;
  }
  return r;
}

// round(num_1e12 / 1e12 * p): a real constant carried at 12 decimal digits,
// rescaled to the working precision p. Used for ln2 and tau.
fn _const_p(num_1e12: Int, p: Int128) -> Int128 {
  var n: Int128 = (num_1e12 as Int128) * p;
  return _div_round_i128(n, 1000000000000 as Int128);
}

// Working precision for the transcendental series: p = scale * 2^20 for
// scale <= 2^20, else p = scale. This keeps p <= 2^63 so every series
// product stays inside 128 bits while small scales keep ~6 extra digits.
fn _precision(scale: Int) -> Int128 {
  var p: Int128 = scale as Int128;
  if scale <= 1048576 { p = p * 1048576; }
  return p;
}

// The matching p / scale factor (2^20 or 1), kept separate from _precision
// so no runtime i128 division is needed.
fn _precision_factor(scale: Int) -> Int128 {
  if scale <= 1048576 { return 1048576; }
  return 1;
}

// e^(rp / p) * p for |rp| <= 0.35 * p (12-term Taylor; below 1 ulp).
fn _exp_series_p(rp: Int128, p: Int128) -> Int128 {
  var ssum = p;
  var term = p;
  var kk = 1;
  while kk <= 12 {
    term = _div_trunc_i128(_div_round_i128(term * rp, p), kk as Int128);
    ssum = ssum + term;
    kk = kk + 1;
  }
  return ssum;
}

// ln(m / s) * p for 0 < s <= m < 2s, via the atanh series
// ln(m/s) = 2 * (z + z^3/3 + z^5/5 + z^7/7 + z^9/9 + z^11/11) with
// z = (m - s) / (m + s) in [0, 1/3]; truncated at z^11, error < 2e-7.
fn _ln_ratio_p(m: Int128, s: Int128, p: Int128) -> Int128 {
  var zp = _div_round_i128((m - s) * p, m + s);
  var z2 = _div_round_i128(zp * zp, p);
  var z3 = _div_round_i128(z2 * zp, p);
  var z5 = _div_round_i128(z3 * z2, p);
  var z7 = _div_round_i128(z5 * z2, p);
  var z9 = _div_round_i128(z7 * z2, p);
  var z11 = _div_round_i128(z9 * z2, p);
  var ssum = zp + _div_trunc_i128(z3, 3 as Int128) + _div_trunc_i128(z5, 5 as Int128);
  ssum = ssum + _div_trunc_i128(z7, 7 as Int128) + _div_trunc_i128(z9, 9 as Int128) + _div_trunc_i128(z11, 11 as Int128);
  return ssum + ssum;
}

// Normalize m0 (positive) to m in [s, 2s) with e = floor(log2(m0 / s)).
// Returns e; the mantissa is written back through the struct so callers get
// both without recomputation.
type _Norm = { m: Int128; e: Int; }

fn _normalize(m0: Int128, s: Int128) -> _Norm {
  var m = m0;
  var e = 0;
  while m >= s + s {
    m = m >> 1;
    e = e + 1;
  }
  while m < s {
    m = m * 2;
    e = e - 1;
  }
  return _Norm{ m: m; e: e; };
}

// Reduce an angle carried in scale units (x = round(theta * scale)) into
// [-pi, pi] at the working precision p (f = p / scale as an exact factor).
// tau is carried at 12 decimal digits. The remainder is computed from the
// shift-based division so no sdiv/srem i128 is emitted.
fn _reduce_angle_p(x: Int, scale: Int, p: Int128, f: Int128) -> Int128 {
  var ap: Int128 = (x as Int128) * f;
  var taup = _const_p(6283185307180, p);
  if taup <= 0 { return ap; }
  var nq = _div_trunc_i128(ap, taup);
  var r = ap - nq * taup;
  var half = taup >> 1;
  if r > half { r = r - taup; }
  if r < (0 - half) { r = r + taup; }
  return r;
}

// ---------------------------------------------------------------------------
// Row 11: scale-once multiply kernels
// ---------------------------------------------------------------------------

/// Fixed-point multiply: round(a * b / scale), halves away from zero.
/// The product is formed exactly in 128 bits and divided by the scale ONCE,
/// so no intermediate is truncated (the classic overflow bug of
/// (a/scale)*b). Saturates at INT_MIN/INT_MAX when the true value exceeds
/// the Int range; scale <= 0 returns 0 (documented). Complexity: O(1).
pub fn mul(a: Int, b: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (a == 0) || (b == 0) => (result == 0)
  ensures: (scale > 0) && (b == scale) => (result == a)
{
  if scale <= 0 { return 0; }
  if a == 0 || b == 0 { return 0; }
  var p: Int128 = (a as Int128) * (b as Int128);
  return _sat64(_div_round_i128(p, scale as Int128));
}

/// Fixed-point dot product: round(sum_i(a[i] * b[i]) / scale), halves away
/// from zero. Products and their sum accumulate exactly in 128 bits and the
/// scale division happens ONCE at the end; the accumulator saturates to
/// INT_MAX/INT_MIN (documented) only if the raw product sum would leave the
/// 128-bit range. Empty vectors or a length mismatch return 0; scale <= 0
/// returns 0. Complexity: O(n).
pub fn sum_mul(a: &Vec[Int], b: &Vec[Int], scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (a.len() == 0) || (b.len() == 0) || (a.len() != b.len()) => (result == 0)
{
  var n = a.len();
  if scale <= 0 { return 0; }
  if n == 0 || b.len() != n { return 0; }
  var acc: Int128 = 0;
  var lim: Int128 = (INT_MIN as Int128) * (INT_MIN as Int128);
  var i = 0;
  while i < n {
    var p: Int128 = (a[i] as Int128) * (b[i] as Int128);
    if p > 0 {
      if acc > lim - p { return INT_MAX; }
    } elif p < 0 {
      if acc < (0 - lim) - p { return INT_MIN; }
    }
    acc = acc + p;
    i = i + 1;
  }
  return _sat64(_div_round_i128(acc, scale as Int128));
}

/// Fixed-point sum of squares: round(sum_i(v[i]^2) / scale), halves away
/// from zero. Exact 128-bit accumulation, one scale division at the end;
/// saturates at INT_MAX (documented) if the square sum would leave the
/// 128-bit range. Empty vector or scale <= 0 returns 0. Complexity: O(n).
pub fn sum_sq(values: &Vec[Int], scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (values.len() == 0) => (result == 0)
{
  var n = values.len();
  if scale <= 0 { return 0; }
  if n == 0 { return 0; }
  var acc: Int128 = 0;
  var lim: Int128 = (INT_MIN as Int128) * (INT_MIN as Int128);
  var i = 0;
  while i < n {
    var p: Int128 = (values[i] as Int128) * (values[i] as Int128);
    if acc > lim - p { return INT_MAX; }
    acc = acc + p;
    i = i + 1;
  }
  return _sat64(_div_round_i128(acc, scale as Int128));
}

// ---------------------------------------------------------------------------
// Rows 27 + 16: fixed-point log2 / ln / exp / pow
// ---------------------------------------------------------------------------

/// Fixed-point base-2 logarithm: round(log2(x / scale) * scale), halves away
/// from zero. x <= 0 or scale <= 0 returns 0 (documented). The result is
/// exact for exact powers of two; otherwise the atanh series is truncated at
/// z^11 (relative error below 1e-6 unit at the working precision) so the
/// last few output units may differ from a correctly-rounded libm value.
/// Complexity: O(log x).
pub fn log2(x: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x <= 0) => (result == 0)
  ensures: (scale > 0) && (x == scale) => (result == 0)
{
  if scale <= 0 { return 0; }
  if x <= 0 { return 0; }
  var p = _precision(scale);
  var s: Int128 = scale as Int128;
  var nm = _normalize(x as Int128, s);
  var lmp = _ln_ratio_p(nm.m, s, p);
  var ln_m_s = _div_round_i128(lmp * s, p);
  // log2(e) at 12 decimal digits (1442695040889 / 1e12).
  var frac = _div_round_i128(ln_m_s * 1442695040889, 1000000000000 as Int128);
  var acc: Int128 = (nm.e as Int128) * s + frac;
  return _sat64(acc);
}

/// Fixed-point natural logarithm: round(ln(x / scale) * scale), halves away
/// from zero. x <= 0 or scale <= 0 returns 0 (documented). ln(scale) is
/// exactly 0; other values carry the atanh-series truncation error
/// (relative error below 1e-6 unit at the working precision). Complexity:
/// O(log x).
pub fn ln(x: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x <= 0) => (result == 0)
  ensures: (scale > 0) && (x == scale) => (result == 0)
{
  if scale <= 0 { return 0; }
  if x <= 0 { return 0; }
  var p = _precision(scale);
  var s: Int128 = scale as Int128;
  var nm = _normalize(x as Int128, s);
  var lmp = _ln_ratio_p(nm.m, s, p);
  // ln2 at the working precision so that large |e| does not quantize the
  // result to whole scale units; one final division by p.
  var ln2p = _const_p(693147180560, p);
  var acc = _div_round_i128(((nm.e as Int128) * ln2p + lmp) * s, p);
  return _sat64(acc);
}

/// Fixed-point exponential: round(exp(x / scale) * scale), halves away from
/// zero. Argument reduction via k = round((x/scale) / ln2) with a 12-digit
/// ln2, e^r on |r| <= ln2/2 by a 12-term Taylor, then an exact 2^k scaling;
/// the true value saturates at INT_MAX for large x. Very negative x
/// (e^(x/scale) below half a scale unit) returns 0. x == 0 returns scale;
/// scale <= 0 returns 0. Complexity: O(1) (bounded series).
pub fn exp(x: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x == 0) && (scale > 0) => (result == scale)
{
  if scale <= 0 { return 0; }
  var p = _precision(scale);
  var f = _precision_factor(scale);
  var ln2p = _const_p(693147180560, p);
  var xp: Int128 = (x as Int128) * f;
  var k: Int128 = _div_round_i128(xp, ln2p);
  if k > (63 as Int128) { return INT_MAX; }
  if k < (0 - 64 as Int128) { return 0; }
  var kk = k as Int;
  var rp: Int128 = xp - k * ln2p;
  var sump = _exp_series_p(rp, p);
  // Apply 2^k as an exact factor BEFORE the single scale division: the
  // working precision is p = scale * F, so round(sump / F) would quantize
  // the result to whole 2^k-multiples and lose up to half a scale unit.
  var num: Int128 = sump;
  var dnm: Int128 = f;
  if kk >= 0 {
    num = num * _pow2_i128(kk);
  } else {
    dnm = dnm * _pow2_i128(0 - kk);
  }
  return _sat64(_div_round_i128(num, dnm));
}

// Square-and-multiply power through the saturating mul kernel.
fn _pow_loop(base: Int, e: Int, scale: Int) -> Int {
  var result = scale;
  var b = base;
  var ee = e;
  while ee > 0 {
    if ee % 2 == 1 { result = mul(result, b, scale); }
    ee = ee / 2;
    if ee > 0 { b = mul(b, b, scale); }
  }
  return result;
}

/// Fixed-point integer power: round((x / scale)^e * scale), halves away from
/// zero, e any sign. Positive exponents use square-and-multiply through the
/// saturating mul kernel; negative exponents reciprocate the positive power
/// (scale^2 / p), saturating to INT_MAX when that power underflows to 0
/// (including x == 0, documented). e == 0 or x == scale returns scale;
/// x == INT_MIN exponent is documented as 0 (pathological input).
/// scale <= 0 returns 0. Complexity: O(log |e|).
pub fn pow_int(x: Int, e: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (e == 0) && (scale > 0) => (result == scale)
  ensures: (x == scale) && (scale > 0) => (result == scale)
{
  if scale <= 0 { return 0; }
  if e == 0 { return scale; }
  if x == scale { return scale; }
  if e == 1 { return x; }
  if e == INT_MIN { return 0; }
  if e < 0 {
    var pos = _pow_loop(x, 0 - e, scale);
    if pos == 0 { return INT_MAX; }
    var num: Int128 = (scale as Int128) * (scale as Int128);
    return _sat64(_div_round_i128(num, pos as Int128));
  }
  return _pow_loop(x, e, scale);
}

// ---------------------------------------------------------------------------
// Row 12: fixed-point trigonometry
// ---------------------------------------------------------------------------

/// Fixed-point sine: round(sin(x / scale) * scale), halves away from zero,
/// where x/scale is the angle in radians. The angle is reduced modulo 2*pi
/// (12-digit tau) into [-pi, pi] and evaluated with the Taylor series through
/// x^13 (residual below 3e-7 rad); the total error stays under one scale unit
/// for scales up to ~2^10 and grows linearly beyond. Scale domain 1..2^44;
/// scale <= 0 or scale > 2^44 returns 0 (documented).
/// Complexity: O(1) (bounded series).
pub fn sin(x: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x == 0) && (scale > 0) && (scale <= 17592186044416) => (result == 0)
{
  if scale <= 0 { return 0; }
  if scale > 17592186044416 { return 0; }
  var p = _precision(scale);
  var f = _precision_factor(scale);
  var rp = _reduce_angle_p(x, scale, p, f);
  var r2 = _div_round_i128(rp * rp, p);
  var term = rp;
  var ssum = rp;
  var kk = 1;
  while kk <= 6 {
    var tq = _div_trunc_i128(_div_round_i128(term * r2, p), ((2 * kk) as Int128) * ((2 * kk + 1) as Int128));
    term = 0 - tq;
    ssum = ssum + term;
    kk = kk + 1;
  }
  return _sat64(_div_round_i128(ssum * (scale as Int128), p));
}

/// Fixed-point cosine: round(cos(x / scale) * scale), halves away from zero,
/// same range reduction as sin. The series runs through x^12 (residual below
/// 2e-5 rad at |x| = pi), keeping the total error under one scale unit for
/// scales up to ~2^12. cos(0) returns scale; scale <= 0 or scale > 2^44
/// returns 0 (documented). Complexity: O(1) (bounded series).
pub fn cos(x: Int, scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x == 0) && (scale > 0) && (scale <= 17592186044416) => (result == scale)
{
  if scale <= 0 { return 0; }
  if scale > 17592186044416 { return 0; }
  var p = _precision(scale);
  var f = _precision_factor(scale);
  var rp = _reduce_angle_p(x, scale, p, f);
  var r2 = _div_round_i128(rp * rp, p);
  var term = p;
  var ssum = p;
  var kk = 1;
  while kk <= 6 {
    var tq = _div_trunc_i128(_div_round_i128(term * r2, p), ((2 * kk - 1) as Int128) * ((2 * kk) as Int128));
    term = 0 - tq;
    ssum = ssum + term;
    kk = kk + 1;
  }
  return _sat64(_div_round_i128(ssum * (scale as Int128), p));
}

// ---------------------------------------------------------------------------
// Row 8: fixed-point MSE
// ---------------------------------------------------------------------------

/// Fixed-point mean squared error: round(sum_i((a[i] - p[i])^2) / (n * scale)),
/// halves away from zero. This matches the float stats semantics -- the mean
/// of the squared errors -- carried in scaled integers: with both vectors
/// scaled by S the real MSE is mean((d_i/S)^2), so the scaled result is
/// sum(d_i^2) / (n * S). Vector lengths must match; empty vectors, a length
/// mismatch or scale <= 0 return 0 (documented). Differences beyond +/-2^62
/// are clamped (outside the supported fixed-point domain) and the 128-bit
/// square sum saturates to INT_MAX (documented). Complexity: O(n).
pub fn mse(actual: &Vec[Int], predicted: &Vec[Int], scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (actual.len() == 0) || (predicted.len() != actual.len()) => (result == 0)
  ensures: result >= 0
{
  var n = actual.len();
  if scale <= 0 { return 0; }
  if n == 0 || predicted.len() != n { return 0; }
  var acc: Int128 = 0;
  var lim: Int128 = (INT_MIN as Int128) * (INT_MIN as Int128);
  var clamp_hi: Int128 = 4611686018427387904;
  var clamp_lo: Int128 = 0 - (4611686018427387904 as Int128);
  var i = 0;
  while i < n {
    var d: Int128 = (actual[i] as Int128) - (predicted[i] as Int128);
    if d > clamp_hi { d = clamp_hi; }
    if d < clamp_lo { d = clamp_lo; }
    var q: Int128 = d * d;
    if acc > lim - q { return INT_MAX; }
    acc = acc + q;
    i = i + 1;
  }
  var den: Int128 = (n as Int128) * (scale as Int128);
  return _sat64(_div_round_i128(acc, den));
}

// ---------------------------------------------------------------------------
// Row 14: table interpolation
// ---------------------------------------------------------------------------

/// Linear interpolation over an ordered (tick, value) table: returns the
/// value at x, rounded to nearest (halves away from zero). The tick table
/// must be non-decreasing (documented; unsorted tables are undefined).
/// x at or below ticks[0] clamps to values[0]; x at or above the last tick
/// clamps to the last value. Repeated ticks define zero-width segments and
/// are skipped. Empty/mismatched tables return 0 (documented). The exact
/// 128-bit numerator (v1 - v0) * (x - t0) is divided once by the tick span.
/// Complexity: O(n).
pub fn interp_linear(ticks: &Vec[Int], values: &Vec[Int], x: Int) -> Int
  ensures: (values.len() == 0) => (result == 0)
  ensures: (ticks.len() != values.len()) => (result == 0)
{
  var n = values.len();
  if n == 0 || ticks.len() != n { return 0; }
  if n == 1 { return values[0]; }
  if x <= ticks[0] { return values[0]; }
  if x >= ticks[n - 1] { return values[n - 1]; }
  var i = 0;
  while i < n - 1 {
    if ticks[i] <= x && x < ticks[i + 1] {
      var t0 = ticks[i];
      var t1 = ticks[i + 1];
      var v0 = values[i];
      var v1 = values[i + 1];
      var num: Int128 = ((v1 as Int128) - (v0 as Int128)) * ((x as Int128) - (t0 as Int128));
      var den: Int128 = (t1 as Int128) - (t0 as Int128);
      var delta = _div_round_i128(num, den);
      return _sat64((v0 as Int128) + delta);
    }
    i = i + 1;
  }
  return values[n - 1];
}

// ---------------------------------------------------------------------------
// Row 17: exact-sum softmax
// ---------------------------------------------------------------------------

/// Fixed-point softmax over scaled logits: returns a Vec[Int] of scaled
/// probabilities whose entries sum EXACTLY to scale (floor each entry, then
/// hand the whole residue to the first maximum -- the sheet's floor +
/// residue-to-max rule). The denominator accumulates exactly in 128 bits, so
/// long inputs do not drift. The maximum logit maps to exp(0) = scale, which
/// keeps the denominator >= scale and every entry non-negative; logit
/// differences below -2^62 are clamped (exp underflows to 0 anyway). Empty
/// input or scale <= 0 returns an empty vector (documented).
/// Complexity: O(n) plus the bounded exp series per element.
pub fn softmax(logits: &Vec[Int], scale: Int) -> Vec[Int]
  ensures: (scale <= 0) => (result.len() == 0)
  ensures: (scale > 0) => (result.len() == logits.len())
{
  var out = Vec[Int].new();
  var n = logits.len();
  if scale <= 0 || n == 0 { return out; }
  var m = logits[0];
  var i = 1;
  while i < n {
    if logits[i] > m { m = logits[i]; }
    i = i + 1;
  }
  var e = Vec[Int].new();
  var total: Int128 = 0;
  var clamp_lo: Int128 = 0 - (4611686018427387904 as Int128);
  i = 0;
  while i < n {
    var d: Int128 = (logits[i] as Int128) - (m as Int128);
    if d < clamp_lo { d = clamp_lo; }
    var ei = exp(d as Int, scale);
    e.push(ei);
    total = total + (ei as Int128);
    i = i + 1;
  }
  var acc: Int128 = 0;
  var best = 0;
  i = 0;
  while i < n {
    var oi: Int128 = _divmod_pos((e[i] as Int128) * (scale as Int128), total);
    out.push(oi as Int);
    acc = acc + oi;
    if e[i] > e[best] { best = i; }
    i = i + 1;
  }
  var residue: Int128 = (scale as Int128) - acc;
  if residue > 0 {
    out[best] = out[best] + (residue as Int);
  }
  return out;
}
