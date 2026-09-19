// XIOM - Stats: Moments
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.moments

// Depends on: xiom.math

// ============================================================================
// Descriptive statistics: central tendency, dispersion, shape, and moments.
//
// Mean/median/variance/stddev here are the Float64 sample versions and are
// implemented locally (the flat xiom.stats module exposes Int-based
// stats_mean/stats_median under different names). NaN is returned for
// degenerate inputs where no meaningful value exists. Complexity is
// documented per function.
// ============================================================================

use xiom.math;

/// Arithmetic mean; 0 for an empty sample (documented). Complexity: O(n).
pub fn mean(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + data[i];
    i = i + 1;
  }
  return s / (n as Float64);
}

/// Sample variance (Bessel's correction, n - 1); 0 for fewer than 2 samples.
/// Complexity: O(n).
pub fn variance(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n < 2 { return 0.0; }
  var m = mean(data);
  var s = 0.0;
  var i = 0;
  while i < n {
    var d = data[i] - m;
    s = s + d * d;
    i = i + 1;
  }
  return s / ((n - 1) as Float64);
}

/// Sample standard deviation; 0 for fewer than 2 samples. Complexity: O(n).
pub fn stddev(data: &Vec[Float64]) -> Float64 {
  return math.sqrt(variance(data));
}

/// Standardized third central moment; NaN for fewer than 3 samples.
/// Complexity: O(n).
pub fn skewness(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n < 3 { return 0.0 / 0.0; }
  var m = mean(data);
  var m2 = 0.0;
  var m3 = 0.0;
  var i = 0;
  while i < n {
    var d = data[i] - m;
    m2 = m2 + d * d;
    m3 = m3 + d * d * d;
    i = i + 1;
  }
  var s2 = m2 / (n as Float64);
  var s3 = m3 / (n as Float64);
  var denom = math.pow(s2, 1.5);
  if denom == 0.0 { return 0.0 / 0.0; }
  return s3 / denom;
}

/// Excess kurtosis (fourth central moment, zero for a normal distribution);
/// NaN for fewer than 4 samples. Complexity: O(n).
pub fn kurtosis(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n < 4 { return 0.0 / 0.0; }
  var m = mean(data);
  var m2 = 0.0;
  var m4 = 0.0;
  var i = 0;
  while i < n {
    var d = data[i] - m;
    m2 = m2 + d * d;
    m4 = m4 + d * d * d * d;
    i = i + 1;
  }
  var v = m2 / (n as Float64);
  if v == 0.0 { return 0.0 / 0.0; }
  return m4 / (n as Float64) / (v * v) - 3.0;
}

/// k-th central moment about the mean; NaN for k < 2. Complexity: O(n).
pub fn central_moment(data: &Vec[Float64], k: Int) -> Float64 {
  var n = data.len();
  if n == 0 || k < 2 { return 0.0 / 0.0; }
  var m = mean(data);
  var s = 0.0;
  var i = 0;
  while i < n {
    var d = data[i] - m;
    s = s + math.pow(d, k as Float64);
    i = i + 1;
  }
  return s / (n as Float64);
}

/// k-th raw moment about zero; NaN for k < 1. Complexity: O(n).
pub fn raw_moment(data: &Vec[Float64], k: Int) -> Float64 {
  var n = data.len();
  if n == 0 || k < 1 { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + math.pow(data[i], k as Float64);
    i = i + 1;
  }
  return s / (n as Float64);
}

/// Sample covariance of x and y; NaN on length mismatch, 0 for fewer than 2
/// pairs. Complexity: O(n).
pub fn covariance(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if y.len() != n { return 0.0 / 0.0; }
  if n < 2 { return 0.0; }
  var mx = mean(x);
  var my = mean(y);
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + (x[i] - mx) * (y[i] - my);
    i = i + 1;
  }
  return s / ((n - 1) as Float64);
}

/// Mean weighted by weights; NaN on length mismatch or a zero weight sum.
/// Complexity: O(n).
pub fn weighted_mean(data: &Vec[Float64], weights: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if weights.len() != n { return 0.0 / 0.0; }
  var num = 0.0;
  var den = 0.0;
  var i = 0;
  while i < n {
    num = num + data[i] * weights[i];
    den = den + weights[i];
    i = i + 1;
  }
  if den == 0.0 { return 0.0 / 0.0; }
  return num / den;
}

/// Geometric mean via log-space; NaN for non-positive values. Complexity: O(n).
pub fn geometric_mean(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    if data[i] <= 0.0 { return 0.0 / 0.0; }
    s = s + math.ln(data[i]);
    i = i + 1;
  }
  return math.exp(s / (n as Float64));
}

/// Harmonic mean; NaN for non-positive values. Complexity: O(n).
pub fn harmonic_mean(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    if data[i] <= 0.0 { return 0.0 / 0.0; }
    s = s + 1.0 / data[i];
    i = i + 1;
  }
  if s == 0.0 { return 0.0 / 0.0; }
  return (n as Float64) / s;
}

// Insertion sort of the data indices by their values (ascending).
fn _sort_idx(v: &Vec[Float64], order: &mut Vec[Int]) {
  var n = order.len();
  var i = 1;
  while i < n {
    var j = i;
    while j > 0 {
      if v[order[j]] < v[order[j - 1]] {
        var t = order[j];
        order[j] = order[j - 1];
        order[j - 1] = t;
        j = j - 1;
      } else {
        j = 0;
      }
    }
    i = i + 1;
  }
}

// Copy a sorted copy of the data.
fn _sorted(data: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var order = Vec[Int].new();
  var i = 0;
  while i < data.len() {
    order.push(i);
    i = i + 1;
  }
  _sort_idx(data, &mut order);
  var j = 0;
  while j < order.len() {
    out.push(data[order[j]]);
    j = j + 1;
  }
  return out;
}

/// Middle value of the sorted sample; the average of the two middles when
/// even. NaN for an empty sample. Complexity: O(n log n).
pub fn median(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var s = _sorted(data);
  if n % 2 == 1 {
    return s[n / 2];
  }
  return 0.5 * (s[n / 2 - 1] + s[n / 2]);
}

/// q-th quantile by linear interpolation between the sorted values (q in
/// [0, 1]). NaN for invalid q. Complexity: O(n log n).
pub fn quantile(data: &Vec[Float64], q: Float64) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  if q < 0.0 || q > 1.0 { return 0.0 / 0.0; }
  if q == 0.0 { return _sorted(data)[0]; }
  if q == 1.0 { return _sorted(data)[n - 1]; }
  var s = _sorted(data);
  var pos = q * ((n - 1) as Float64);
  var lo = pos as Int;
  var frac = pos - (lo as Float64);
  if lo >= n - 1 { return s[n - 1]; }
  return s[lo] + frac * (s[lo + 1] - s[lo]);
}
