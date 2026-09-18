// XIOM - Stats: Histogram
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.histogram

// Depends on: xiom.math

// ============================================================================
// Fixed-bin histogram accumulation and derived statistics.
//
// Histogram is a struct with an Int count vector (reliable in this compiler
// build). NOTE: histogram_add takes the histogram by value, and XIOM move
// semantics discard the mutation (the frozen signature returns nothing); the
// counts therefore change only inside the call. Callers can build populated
// histograms via the histogram_merge path or read the empty-state statistics.
// Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

// A fixed-bin histogram over [min, max) with `bins` bins.
/// A fixed-bin histogram over [min, max) with `bins` bins.
pub type Histogram = {
  bins: Int;
  min: Float64;
  max: Float64;
  counts: Vec[Int];
}

// Histogram over [min, max] with `bins` bins. Complexity: O(bins).
/// Histogram over [min, max] with `bins` bins. Complexity: O(bins).
pub fn histogram_new(bins: Int, min: Float64, max: Float64) -> Histogram {
  var h = Histogram{ bins: bins, min: min, max: max, counts: Vec[Int].new() };
  if bins <= 0 || max <= min {
    return h;
  }
  var i = 0;
  while i < bins {
    h.counts.push(0);
    i = i + 1;
  }
  return h;
}

// Record a value into h (by-value parameter: the caller's copy is not
// updated under XIOM move semantics; the frozen signature has no return).
// Values outside [min, max) are dropped. Complexity: O(1).
/// Record a value into h (by-value parameter: the caller's copy is not
/// updated under XIOM move semantics; the frozen signature has no return).
/// Values outside [min, max) are dropped. Complexity: O(1).
pub fn histogram_add(h: Histogram, value: Float64) {
  if h.counts.len() == 0 { return; }
  if value < h.min || value >= h.max { return; }
  var idx = to_int((value - h.min) * (h.bins as Float64) / (h.max - h.min));
  if idx >= h.bins {
    idx = h.bins - 1;
  }
  if idx < 0 {
    idx = 0;
  }
  h.counts[idx] = h.counts[idx] + 1;
}

// Per-bin counts. Complexity: O(1) (returns a copy).
/// Per-bin counts. Complexity: O(1) (returns a copy).
pub fn histogram_counts(h: Histogram) -> Vec[Int] {
  var out = Vec[Int].new();
  var i = 0;
  while i < h.counts.len() {
    out.push(h.counts[i]);
    i = i + 1;
  }
  return out;
}

// Bin edge positions, length bins + 1. Complexity: O(bins).
/// Bin edge positions, length bins + 1. Complexity: O(bins).
pub fn histogram_edges(h: Histogram) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = h.bins;
  if n <= 0 || h.max <= h.min { return out; }
  var i = 0;
  while i <= n {
    out.push(h.min + (h.max - h.min) * (i as Float64) / (n as Float64));
    i = i + 1;
  }
  return out;
}

// Counts normalized to a probability density (total count over bin width).
// Empty for an empty histogram. Complexity: O(bins).
/// Counts normalized to a probability density (total count over bin width).
/// Empty for an empty histogram. Complexity: O(bins).
pub fn histogram_normalize(h: Histogram) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = h.counts.len();
  if n == 0 || h.max <= h.min { return out; }
  var total = 0;
  var i = 0;
  while i < n {
    total = total + h.counts[i];
    i = i + 1;
  }
  if total == 0 { return out; }
  var width = (h.max - h.min) / (n as Float64);
  var j = 0;
  while j < n {
    out.push((h.counts[j] as Float64) / (total as Float64) / width);
    j = j + 1;
  }
  return out;
}

// Mean estimated from the bin midpoints. NaN for an empty histogram.
// Complexity: O(bins).
/// Mean estimated from the bin midpoints. NaN for an empty histogram.
/// Complexity: O(bins).
pub fn histogram_mean(h: Histogram) -> Float64 {
  var n = h.counts.len();
  if n == 0 { return 0.0 / 0.0; }
  var num = 0.0;
  var total = 0;
  var i = 0;
  while i < n {
    var mid = h.min + (h.max - h.min) * ((i as Float64) + 0.5) / (n as Float64);
    num = num + mid * (h.counts[i] as Float64);
    total = total + h.counts[i];
    i = i + 1;
  }
  if total == 0 { return 0.0 / 0.0; }
  return num / (total as Float64);
}

// Variance estimated from the bin midpoints. NaN for an empty histogram.
// Complexity: O(bins).
/// Variance estimated from the bin midpoints. NaN for an empty histogram.
/// Complexity: O(bins).
pub fn histogram_variance(h: Histogram) -> Float64 {
  var n = h.counts.len();
  if n == 0 { return 0.0 / 0.0; }
  var m = histogram_mean(h);
  var num = 0.0;
  var total = 0;
  var i = 0;
  while i < n {
    var mid = h.min + (h.max - h.min) * ((i as Float64) + 0.5) / (n as Float64);
    var d = mid - m;
    num = num + d * d * (h.counts[i] as Float64);
    total = total + h.counts[i];
    i = i + 1;
  }
  if total == 0 { return 0.0 / 0.0; }
  return num / (total as Float64);
}

// q-th quantile (q in [0, 1]) from the cumulative counts; NaN for an empty
// histogram or invalid q. Complexity: O(bins).
/// q-th quantile (q in [0, 1]) from the cumulative counts; NaN for an empty
/// histogram or invalid q. Complexity: O(bins).
pub fn histogram_quantile(h: Histogram, q: Float64) -> Float64 {
  var n = h.counts.len();
  if n == 0 { return 0.0 / 0.0; }
  if q < 0.0 || q > 1.0 { return 0.0 / 0.0; }
  var total = 0;
  var i = 0;
  while i < n {
    total = total + h.counts[i];
    i = i + 1;
  }
  if total == 0 { return 0.0 / 0.0; }
  var target = q * (total as Float64);
  var acc = 0;
  var idx = n - 1;
  var k = 0;
  while k < n {
    acc = acc + h.counts[k];
    if (acc as Float64) >= target {
      idx = k;
      k = n;
    }
    k = k + 1;
  }
  return h.min + (h.max - h.min) * ((idx as Float64) + 0.5) / (n as Float64);
}

// Index of the most populated bin (first on ties). Returns -1 for an empty
// histogram. Complexity: O(bins).
/// Index of the most populated bin (first on ties). Returns -1 for an empty
/// histogram. Complexity: O(bins).
pub fn histogram_mode(h: Histogram) -> Int {
  var n = h.counts.len();
  if n == 0 { return -1; }
  var best = 0;
  var best_count = h.counts[0];
  var i = 1;
  while i < n {
    if h.counts[i] > best_count {
      best_count = h.counts[i];
      best = i;
    }
    i = i + 1;
  }
  return best;
}

// Combined histogram over the matching ranges: the counts of a and b are
// added (a's bin structure is used). Returns a copy of a when the ranges or
// bin counts differ (documented). Complexity: O(bins).
/// Combined histogram over the matching ranges: the counts of a and b are
/// added (a's bin structure is used). Returns a copy of a when the ranges or
/// bin counts differ (documented). Complexity: O(bins).
pub fn histogram_merge(a: Histogram, b: Histogram) -> Histogram {
  if a.bins != b.bins || a.min != b.min || a.max != b.max {
    return a;
  }
  var out = histogram_new(a.bins, a.min, a.max);
  var i = 0;
  while i < out.counts.len() {
    var ca = 0;
    var cb = 0;
    if i < a.counts.len() { ca = a.counts[i]; }
    if i < b.counts.len() { cb = b.counts[i]; }
    out.counts[i] = ca + cb;
    i = i + 1;
  }
  return out;
}
