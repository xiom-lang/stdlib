// XIOM - Stats: Moments
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.moments

// Depends on: xiom.math

// ============================================================================
// Descriptive statistics: central tendency, dispersion, shape, and moments.
// TODO(compiler): implement.
// ============================================================================

// fn mean(data: &Vec[Float64]) -> Float64 - arithmetic mean.
// fn variance(data: &Vec[Float64]) -> Float64 - sample variance (n-1).
// fn stddev(data: &Vec[Float64]) -> Float64 - sample standard deviation.
// fn skewness(data: &Vec[Float64]) -> Float64 - standardized third central moment.
// fn kurtosis(data: &Vec[Float64]) -> Float64 - excess kurtosis (fourth central moment, zero for normal).
// fn central_moment(data: &Vec[Float64], k: Int) -> Float64 - k-th central moment about the mean.
// fn raw_moment(data: &Vec[Float64], k: Int) -> Float64 - k-th raw moment about zero.
// fn covariance(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - sample covariance.
// fn weighted_mean(data: &Vec[Float64], weights: &Vec[Float64]) -> Float64 - mean weighted by weights.
// fn geometric_mean(data: &Vec[Float64]) -> Float64 - geometric mean; requires positive values.
// fn harmonic_mean(data: &Vec[Float64]) -> Float64 - harmonic mean; requires positive values.
// fn median(data: &Vec[Float64]) -> Float64 - middle value; average of the two middles when even.
// fn quantile(data: &Vec[Float64], q: Float64) -> Float64 - q-th quantile by linear interpolation between sorted values.
