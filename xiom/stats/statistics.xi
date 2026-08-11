// XIOM - Stats: Statistics
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.statistics

// Depends on: xiom.math

// ============================================================================
// Descriptive statistics: central tendency, dispersion, shape, and dependence
// measures over Vec[Float64] samples. NOTE: current implementation lives in
// stats.xi REAL + stats/moments.xi stub - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// fn mean(data: &Vec[Float64]) -> Float64 - arithmetic mean.
// fn median(data: &Vec[Float64]) -> Float64 - middle value; average of the two middles when even.
// fn mode(data: &Vec[Float64]) -> Option[Float64] - most frequently occurring value.
// fn variance(data: &Vec[Float64]) -> Float64 - sample variance (n-1).
// fn variance_pop(data: &Vec[Float64]) -> Float64 - population variance (n).
// fn stddev(data: &Vec[Float64]) -> Float64 - sample standard deviation.
// fn stddev_pop(data: &Vec[Float64]) -> Float64 - population standard deviation.
// fn range(data: &Vec[Float64]) -> Float64 - max minus min.
// fn iqr(data: &Vec[Float64]) -> Float64 - interquartile range (Q3 - Q1).
// fn quartiles(data: &Vec[Float64]) -> Vec[Float64] - [Q1, Q2, Q3] of the sample.
// fn percentile(data: &Vec[Float64], p: Float64) -> Float64 - p-th percentile by linear interpolation.
// fn skewness(data: &Vec[Float64]) -> Float64 - standardized third central moment.
// fn kurtosis(data: &Vec[Float64]) -> Float64 - excess kurtosis (fourth central moment, zero for normal).
// fn covariance(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - sample covariance.
// fn correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - Pearson correlation coefficient.
// fn spearman_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - rank-based Spearman rho.
// fn kendall_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - Kendall tau rank correlation.
// fn rms(data: &Vec[Float64]) -> Float64 - root mean square of the sample.
// fn geometric_mean(data: &Vec[Float64]) -> Float64 - geometric mean; requires positive values.
// fn harmonic_mean(data: &Vec[Float64]) -> Float64 - harmonic mean; requires positive values.
// fn weighted_mean(data: &Vec[Float64], weights: &Vec[Float64]) -> Float64 - mean weighted by weights.
// fn trimmed_mean(data: &Vec[Float64], trim: Float64) -> Float64 - mean after removing trim from each tail.
// fn winsorized_mean(data: &Vec[Float64], trim: Float64) -> Float64 - mean with trim fraction winsorized to tail values.
// fn mad(data: &Vec[Float64]) -> Float64 - median absolute deviation from the median.
// fn z_score(x: Float64, mean: Float64, stddev: Float64) -> Float64 - (x - mean) / stddev.
