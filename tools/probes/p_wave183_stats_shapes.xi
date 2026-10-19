// p_wave183_stats_shapes.xi -- wave-183 statistics contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-183 xiom.stats.statistics degenerate-input contracts:
// empty-sample values (0 vs NaN vs None), quartiles shape, percentile
// invalid-p NaN, rank/correlation length-mismatch NaN, and the
// trim/weighted/z-score guards.
// Expected: rc 0.

module p_wave183_stats_shapes

use xiom.stats.statistics;
use xiom.math;
use xiom.io;

fn main() -> Int {
  var empty: Vec[Float64] = Vec[Float64].new();
  var one: Vec[Float64] = Vec[Float64].new();
  one.push(1.0);
  var two: Vec[Float64] = Vec[Float64].new();
  two.push(1.0); two.push(2.0);
  var three: Vec[Float64] = Vec[Float64].new();
  three.push(1.0); three.push(2.0); three.push(3.0);

  if statistics.mean(&empty) != 0.0 { return 1; }
  if !math.is_nan(statistics.median(&empty)) { return 2; }
  match statistics.mode(&empty) {
    Some(_) => { return 3; }
    None => {}
  }
  match statistics.mode(&one) {
    Some(v) => { if v != 1.0 { return 4; } }
    None => { return 4; }
  }
  if statistics.variance(&empty) != 0.0 { return 5; }
  if statistics.variance(&one) != 0.0 { return 6; }
  if statistics.variance_pop(&empty) != 0.0 { return 7; }
  if statistics.stddev(&empty) != 0.0 { return 8; }
  if statistics.stddev_pop(&empty) != 0.0 { return 9; }
  if statistics.range(&empty) != 0.0 { return 10; }
  if !math.is_nan(statistics.iqr(&empty)) { return 11; }
  if statistics.quartiles(&empty).len() != 0 { return 12; }
  if statistics.quartiles(&two).len() != 3 { return 13; }
  if !math.is_nan(statistics.percentile(&empty, 50.0)) { return 14; }
  if !math.is_nan(statistics.percentile(&two, -1.0)) { return 15; }
  if !math.is_nan(statistics.percentile(&two, 101.0)) { return 16; }
  if !math.is_nan(statistics.skewness(&two)) { return 17; }
  if !math.is_nan(statistics.kurtosis(&three)) { return 18; }
  if statistics.covariance(&empty, &empty) != 0.0 { return 19; }
  if !math.is_nan(statistics.covariance(&one, &two)) { return 20; }
  if !math.is_nan(statistics.correlation(&empty, &empty)) { return 21; }
  if !math.is_nan(statistics.correlation(&one, &two)) { return 22; }
  if !math.is_nan(statistics.spearman_correlation(&empty, &empty)) { return 23; }
  if !math.is_nan(statistics.spearman_correlation(&one, &two)) { return 24; }
  if !math.is_nan(statistics.kendall_correlation(&empty, &empty)) { return 25; }
  if !math.is_nan(statistics.kendall_correlation(&one, &two)) { return 26; }
  if statistics.rms(&empty) != 0.0 { return 27; }
  if !math.is_nan(statistics.geometric_mean(&empty)) { return 28; }
  if !math.is_nan(statistics.harmonic_mean(&empty)) { return 29; }
  if !math.is_nan(statistics.weighted_mean(&one, &two)) { return 30; }
  if !math.is_nan(statistics.trimmed_mean(&empty, 0.1)) { return 31; }
  if !math.is_nan(statistics.trimmed_mean(&two, -0.1)) { return 32; }
  if !math.is_nan(statistics.trimmed_mean(&two, 0.5)) { return 33; }
  if !math.is_nan(statistics.winsorized_mean(&empty, 0.1)) { return 34; }
  if !math.is_nan(statistics.winsorized_mean(&two, 0.5)) { return 35; }
  if !math.is_nan(statistics.mad(&empty)) { return 36; }
  if !math.is_nan(statistics.z_score(1.0, 0.0, 0.0)) { return 37; }

  io.println("p_wave183_stats_shapes: OK");
  return 0;
}
