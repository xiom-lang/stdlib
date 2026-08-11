// XIOM - Stats: Histogram
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.histogram

// Depends on: xiom.math

// ============================================================================
// Fixed-bin histogram accumulation and derived statistics. TODO(compiler): implement.
// ============================================================================

// type Histogram - fixed-bin histogram; struct { bins: Int; min: Float64; max: Float64; counts: Vec[Int] }.
// fn histogram_new(bins: Int, min: Float64, max: Float64) -> Histogram - histogram over [min, max] with bins bins.
// fn histogram_add(h: Histogram, value: Float64) - record a value into h.
// fn histogram_counts(h: Histogram) -> Vec[Int] - per-bin counts.
// fn histogram_edges(h: Histogram) -> Vec[Float64] - bin edge positions, length bins + 1.
// fn histogram_normalize(h: Histogram) -> Vec[Float64] - counts normalized to a probability density.
// fn histogram_mean(h: Histogram) -> Float64 - mean estimated from bin midpoints.
// fn histogram_variance(h: Histogram) -> Float64 - variance estimated from bin midpoints.
// fn histogram_quantile(h: Histogram, q: Float64) -> Float64 - q-th quantile from cumulative counts.
// fn histogram_mode(h: Histogram) -> Int - index of the most populated bin.
// fn histogram_merge(a: Histogram, b: Histogram) -> Histogram - combined histogram over matching ranges.
