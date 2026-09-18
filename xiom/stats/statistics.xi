// XIOM - Stats: Statistics
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.statistics

// Depends on: xiom.math

// ============================================================================
// Descriptive statistics: central tendency, dispersion, shape, and dependence
// measures over Vec[Float64] samples.
//
// Implemented locally (the flat xiom.stats module exposes Int-based
// stats_mean/stats_median/... under different names; delegation by same name
// is avoided). NaN is returned for degenerate inputs. Complexity is
// documented per function.
// ============================================================================

use xiom.math;

// Arithmetic mean; 0 for an empty sample. Complexity: O(n).
/// Arithmetic mean; 0 for an empty sample. Complexity: O(n).
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

// Middle value of the sorted sample; average of the two middles when even.
// NaN for an empty sample. Complexity: O(n log n).
/// Middle value of the sorted sample; average of the two middles when even.
/// NaN for an empty sample. Complexity: O(n log n).
pub fn median(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var s = _sorted(data);
  if n % 2 == 1 {
    return s[n / 2];
  }
  return 0.5 * (s[n / 2 - 1] + s[n / 2]);
}

// Most frequently occurring value. NaN for an empty sample; the first mode
// wins ties (documented). Complexity: O(n^2).
/// Most frequently occurring value. NaN for an empty sample; the first mode
/// wins ties (documented). Complexity: O(n^2).
pub fn mode(data: &Vec[Float64]) -> Option[Float64] {
  var n = data.len();
  if n == 0 {
    return Option[Float64]{ is_some: false, value: 0.0 };
  }
  var best = data[0];
  var best_count = 1;
  var i = 0;
  while i < n {
    var count = 0;
    var j = 0;
    while j < n {
      if data[j] == data[i] {
        count = count + 1;
      }
      j = j + 1;
    }
    if count > best_count {
      best_count = count;
      best = data[i];
    }
    i = i + 1;
  }
  return Option[Float64]{ is_some: true, value: best };
}

// Sample variance (n - 1); 0 for fewer than 2 samples. Complexity: O(n).
/// Sample variance (n - 1); 0 for fewer than 2 samples. Complexity: O(n).
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

// Population variance (n); 0 for an empty sample. Complexity: O(n).
/// Population variance (n); 0 for an empty sample. Complexity: O(n).
pub fn variance_pop(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0; }
  var m = mean(data);
  var s = 0.0;
  var i = 0;
  while i < n {
    var d = data[i] - m;
    s = s + d * d;
    i = i + 1;
  }
  return s / (n as Float64);
}

// Sample standard deviation. Complexity: O(n).
/// Sample standard deviation. Complexity: O(n).
pub fn stddev(data: &Vec[Float64]) -> Float64 {
  return math.sqrt(variance(data));
}

// Population standard deviation. Complexity: O(n).
/// Population standard deviation. Complexity: O(n).
pub fn stddev_pop(data: &Vec[Float64]) -> Float64 {
  return math.sqrt(variance_pop(data));
}

// Range (max - min); 0 for an empty sample. Complexity: O(n).
/// Range (max - min); 0 for an empty sample. Complexity: O(n).
pub fn range(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0; }
  var mn = data[0];
  var mx = data[0];
  var i = 1;
  while i < n {
    if data[i] < mn { mn = data[i]; }
    if data[i] > mx { mx = data[i]; }
    i = i + 1;
  }
  return mx - mn;
}

// Interquartile range (Q3 - Q1). NaN for fewer than 2 samples.
// Complexity: O(n log n).
/// Interquartile range (Q3 - Q1). NaN for fewer than 2 samples.
/// Complexity: O(n log n).
pub fn iqr(data: &Vec[Float64]) -> Float64 {
  var q = quartiles(data);
  if q.len() != 3 { return 0.0 / 0.0; }
  return q[2] - q[0];
}

// Quartiles [Q1, Q2, Q3] by linear interpolation. Empty for an empty sample.
// Complexity: O(n log n).
/// Quartiles [Q1, Q2, Q3] by linear interpolation. Empty for an empty sample.
/// Complexity: O(n log n).
pub fn quartiles(data: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = data.len();
  if n == 0 { return out; }
  var s = _sorted(data);
  var q1 = _quantile_sorted(&s, 0.25);
  var q2 = _quantile_sorted(&s, 0.5);
  var q3 = _quantile_sorted(&s, 0.75);
  out.push(q1);
  out.push(q2);
  out.push(q3);
  return out;
}

// p-th percentile by linear interpolation (p in [0, 100]). NaN for invalid p.
// Complexity: O(n log n).
/// p-th percentile by linear interpolation (p in [0, 100]). NaN for invalid p.
/// Complexity: O(n log n).
pub fn percentile(data: &Vec[Float64], p: Float64) -> Float64 {
  if p < 0.0 || p > 100.0 { return 0.0 / 0.0; }
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var s = _sorted(data);
  return _quantile_sorted(&s, p / 100.0);
}

// Standardized third central moment. Complexity: O(n).
/// Standardized third central moment. Complexity: O(n).
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
  var v = m2 / (n as Float64);
  var denom = math.pow(v, 1.5);
  if denom == 0.0 { return 0.0 / 0.0; }
  return (m3 / (n as Float64)) / denom;
}

// Excess kurtosis (fourth central moment, zero for normal). Complexity: O(n).
/// Excess kurtosis (fourth central moment, zero for normal). Complexity: O(n).
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
  return (m4 / (n as Float64)) / (v * v) - 3.0;
}

// Sample covariance of x and y. Complexity: O(n).
/// Sample covariance of x and y. Complexity: O(n).
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

// Pearson correlation coefficient. Complexity: O(n).
/// Pearson correlation coefficient. Complexity: O(n).
pub fn correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if y.len() != n { return 0.0 / 0.0; }
  if n < 2 { return 0.0 / 0.0; }
  var mx = mean(x);
  var my = mean(y);
  var num = 0.0;
  var dx2 = 0.0;
  var dy2 = 0.0;
  var i = 0;
  while i < n {
    var dx = x[i] - mx;
    var dy = y[i] - my;
    num = num + dx * dy;
    dx2 = dx2 + dx * dx;
    dy2 = dy2 + dy * dy;
    i = i + 1;
  }
  var denom = math.sqrt(dx2) * math.sqrt(dy2);
  if denom == 0.0 { return 0.0; }
  return num / denom;
}

// Spearman rank correlation: the Pearson correlation of the ranks.
// Complexity: O(n log n).
/// Spearman rank correlation: the Pearson correlation of the ranks.
/// Complexity: O(n log n).
pub fn spearman_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if y.len() != n { return 0.0 / 0.0; }
  if n < 2 { return 0.0 / 0.0; }
  var rx = _ranks(x);
  var ry = _ranks(y);
  return correlation(&rx, &ry);
}

// Kendall tau-b rank correlation (concordant minus discordant pairs).
// Complexity: O(n^2).
/// Kendall tau-b rank correlation (concordant minus discordant pairs).
/// Complexity: O(n^2).
pub fn kendall_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 {
  var n = x.len();
  if y.len() != n { return 0.0 / 0.0; }
  if n < 2 { return 0.0 / 0.0; }
  var concordant = 0;
  var discordant = 0;
  var i = 0;
  while i < n {
    var j = i + 1;
    while j < n {
      var dx = x[i] - x[j];
      var dy = y[i] - y[j];
      if dx != 0.0 && dy != 0.0 {
        if (dx < 0.0 && dy < 0.0) || (dx > 0.0 && dy > 0.0) {
          concordant = concordant + 1;
        } else {
          discordant = discordant + 1;
        }
      }
      j = j + 1;
    }
    i = i + 1;
  }
  var total = (concordant + discordant) as Float64;
  if total == 0.0 { return 0.0; }
  return ((concordant - discordant) as Float64) / total;
}

// Root mean square of the sample; 0 for an empty sample. Complexity: O(n).
/// Root mean square of the sample; 0 for an empty sample. Complexity: O(n).
pub fn rms(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0; }
  var s = 0.0;
  var i = 0;
  while i < n {
    s = s + data[i] * data[i];
    i = i + 1;
  }
  return math.sqrt(s / (n as Float64));
}

// Geometric mean via log-space; NaN for non-positive values. Complexity: O(n).
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

// Harmonic mean; NaN for non-positive values. Complexity: O(n).
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

// Mean weighted by weights. Complexity: O(n).
/// Mean weighted by weights. Complexity: O(n).
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

// Mean after removing the fraction `trim` from each sorted tail.
// NaN for invalid trim or an over-trimmed sample. Complexity: O(n log n).
/// Mean after removing the fraction `trim` from each sorted tail.
/// NaN for invalid trim or an over-trimmed sample. Complexity: O(n log n).
pub fn trimmed_mean(data: &Vec[Float64], trim: Float64) -> Float64 {
  var n = data.len();
  if trim < 0.0 || trim >= 0.5 { return 0.0 / 0.0; }
  if n == 0 { return 0.0 / 0.0; }
  var k = (trim * (n as Float64)) as Int;
  if 2 * k >= n { return 0.0 / 0.0; }
  var s = _sorted(data);
  var sum = 0.0;
  var i = k;
  while i < n - k {
    sum = sum + s[i];
    i = i + 1;
  }
  return sum / ((n - 2 * k) as Float64);
}

// Mean with the fraction `trim` of each tail winsorized to the tail values.
// NaN for invalid trim. Complexity: O(n log n).
/// Mean with the fraction `trim` of each tail winsorized to the tail values.
/// NaN for invalid trim. Complexity: O(n log n).
pub fn winsorized_mean(data: &Vec[Float64], trim: Float64) -> Float64 {
  var n = data.len();
  if trim < 0.0 || trim >= 0.5 { return 0.0 / 0.0; }
  if n == 0 { return 0.0 / 0.0; }
  var k = (trim * (n as Float64)) as Int;
  if 2 * k >= n { return 0.0 / 0.0; }
  var s = _sorted(data);
  var lo = s[k];
  var hi = s[n - 1 - k];
  var sum = 0.0;
  var i = 0;
  while i < n {
    var v = s[i];
    if v < lo { v = lo; }
    if v > hi { v = hi; }
    sum = sum + v;
    i = i + 1;
  }
  return sum / (n as Float64);
}

// Median absolute deviation from the median. NaN for an empty sample.
// Complexity: O(n log n).
/// Median absolute deviation from the median. NaN for an empty sample.
/// Complexity: O(n log n).
pub fn mad(data: &Vec[Float64]) -> Float64 {
  var n = data.len();
  if n == 0 { return 0.0 / 0.0; }
  var med = median(data);
  var dev = Vec[Float64].new();
  var i = 0;
  while i < n {
    var d = data[i] - med;
    if d < 0.0 { d = -d; }
    dev.push(d);
    i = i + 1;
  }
  return median(&dev);
}

// Standardized score (x - mean) / stddev. Complexity: O(1).
/// Standardized score (x - mean) / stddev. Complexity: O(1).
pub fn z_score(x: Float64, mean: Float64, stddev: Float64) -> Float64 {
  if stddev == 0.0 { return 0.0 / 0.0; }
  return (x - mean) / stddev;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

// Insertion sort of the indices by their values (ascending).
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

// Sorted ascending copy of the data.
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

// q-th quantile (q in [0, 1]) of an already-sorted sample.
fn _quantile_sorted(s: &Vec[Float64], q: Float64) -> Float64 {
  var n = s.len();
  if n == 0 { return 0.0; }
  if q <= 0.0 { return s[0]; }
  if q >= 1.0 { return s[n - 1]; }
  var pos = q * ((n - 1) as Float64);
  var lo = pos as Int;
  var frac = pos - (lo as Float64);
  if lo >= n - 1 { return s[n - 1]; }
  return s[lo] + frac * (s[lo + 1] - s[lo]);
}

// Average ranks of the data (ties share the mean rank).
fn _ranks(data: &Vec[Float64]) -> Vec[Float64] {
  var n = data.len();
  var ranks = Vec[Float64].new();
  var order = Vec[Int].new();
  var i = 0;
  while i < n {
    ranks.push(0.0);
    order.push(i);
    i = i + 1;
  }
  _sort_idx(data, &mut order);
  var pos = 0;
  while pos < n {
    var end = pos;
    while end + 1 < n && data[order[end + 1]] == data[order[pos]] {
      end = end + 1;
    }
    var avg = ((pos + end) as Float64) / 2.0 + 1.0;
    var k = pos;
    while k <= end {
      ranks[order[k]] = avg;
      k = k + 1;
    }
    pos = end + 1;
  }
  return ranks;
}
