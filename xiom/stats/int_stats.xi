// XIOM - Stats: Integer-Domain Statistics Helpers
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.int_stats

// Depends on: xiom.core only. Integer fixed-point statistics usable without
// Vec[Float64] and without the xiom.math / xiom.stats barrels, matching the
// requester notes (climate, stats-ml, boosting, actor).
//
// Wave-165 wishlist rows:
//   4  -- stable argmax: first-wins index of the maximum, with the NaN policy
//         documented for the Float64 sibling (NaN never wins; empty or
//         all-NaN returns 0, matching the stats module's empty-input
//         convention of returning 0 for Int stats).
//   27 -- integer-domain stats helpers: rounded integer mean and the
//         least-squares slope over scaled Int pairs (no Float64 anywhere).
//
// Rounding is half away from zero everywhere; accumulation is exact in
// 128 bits. NOTE: requires/ensures clauses are runtime-enforced in this
// compiler and crash on violation, so all domain handling is guarded inside
// the bodies.

use xiom.core.INT_MAX;
use xiom.core.INT_MIN;

// |v| as an Int128 (INT_MIN-safe: the cast widens before negation).
fn _abs128(v: Int128) -> Int128 {
  if v < 0 { return 0 - v; }
  return v;
}

// Clamp a 128-bit intermediate back into the Int range.
fn _sat64(q: Int128) -> Int {
  var hi: Int128 = INT_MAX as Int128;
  var lo: Int128 = INT_MIN as Int128;
  if q > hi { return INT_MAX; }
  if q < lo { return INT_MIN; }
  return q as Int;
}

// floor(|n| / d) for n >= 0, d > 0 via 127-step restoring long division.
// This deliberately does NOT use the `/` operator: the pinned compiler
// miscompiles a runtime `sdiv i128` that gets inlined into a function which
// also contains a vector element-load loop (AV 0xC0000005 at run time; see
// the wave-165 entry in tools/known_failures/README.md). Shift/mask forms
// lower cleanly. Domain: |n| < 2^126, 0 < d <= 2^126.
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

// round(n / d) to nearest, halves away from zero, in 128 bits. d != 0.
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

/// Rounded integer mean of a scaled sample: round(sum(values) / n), halves
/// away from zero. The sum accumulates exactly in 128 bits (n * |value| can
/// never leave the 128-bit range for Int-length vectors), so the result is
/// the correctly rounded mean of the scaled values. Empty input returns 0
/// (documented, matching xiom.stats). Complexity: O(n).
pub fn int_mean(values: &Vec[Int]) -> Int
  ensures: (values.len() == 0) => (result == 0)
{
  var n = values.len();
  if n == 0 { return 0; }
  var acc: Int128 = 0;
  var i = 0;
  while i < n {
    acc = acc + (values[i] as Int128);
    i = i + 1;
  }
  var nn: Int128 = n as Int128;
  return _sat64(_div_round_i128(acc, nn));
}

/// Least-squares slope of y on x over scaled Int pairs: the inputs represent
/// real values x_i = X_i / S and y_i = Y_i / S for one common positive scale
/// S (S cancels in the ratio), and the result is round(scale * slope),
/// halves away from zero. Mean-centred normal equations
/// (sum dx*dy) / (sum dx^2) with exact 128-bit accumulation; exact while the
/// centred sums stay inside 128 bits (all realistic scaled samples).
/// Fewer than 2 points, a length mismatch, a zero x-variance or scale <= 0
/// returns 0 (documented). Complexity: O(n).
pub fn int_slope(x: &Vec[Int], y: &Vec[Int], scale: Int) -> Int
  ensures: (scale <= 0) => (result == 0)
  ensures: (x.len() < 2) || (y.len() != x.len()) => (result == 0)
{
  var n = x.len();
  if scale <= 0 { return 0; }
  if n < 2 || y.len() != n { return 0; }
  var mx = int_mean(x);
  var my = int_mean(y);
  var num: Int128 = 0;
  var den: Int128 = 0;
  var i = 0;
  while i < n {
    var dx: Int128 = (x[i] as Int128) - (mx as Int128);
    var dy: Int128 = (y[i] as Int128) - (my as Int128);
    num = num + dx * dy;
    den = den + dx * dx;
    i = i + 1;
  }
  if den == 0 { return 0; }
  return _sat64(_div_round_i128(num * (scale as Int128), den));
}

/// Index of the maximum with first-wins stability (FIFO tie-break): the
/// earliest index holding the largest value wins. Empty input returns 0
/// (documented, matching the xiom.stats empty-input convention for Int
/// stats; callers that need an absence signal pre-check len). Complexity:
/// O(n).
pub fn int_argmax(values: &Vec[Int]) -> Int
  ensures: (values.len() == 0) => (result == 0)
{
  var n = values.len();
  if n == 0 { return 0; }
  var best = 0;
  var i = 1;
  while i < n {
    if values[i] > values[best] { best = i; }
    i = i + 1;
  }
  return best;
}

/// Float64 sibling of int_argmax with the documented NaN policy: NaN entries
/// never win (they are skipped, whichever position they occupy) and ties keep
/// the first index. Empty input or an all-NaN input returns 0 (documented;
/// the stats module returns NaN itself for degenerate samples, but an index
/// result has no NaN form, so the empty-sentinel 0 is reused). Complexity:
/// O(n).
pub fn f64_argmax(values: &Vec[Float64]) -> Int
  ensures: (values.len() == 0) => (result == 0)
{
  var n = values.len();
  if n == 0 { return 0; }
  var best = 0;
  var found = false;
  var i = 0;
  while i < n {
    var v = values[i];
    if v == v {
      if !found {
        best = i;
        found = true;
      } elif v > values[best] {
        best = i;
      }
    }
    i = i + 1;
  }
  return best;
}
