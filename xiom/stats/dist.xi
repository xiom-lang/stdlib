// XIOM - Stats: Dist
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.dist

// Depends on: xiom.math

// ============================================================================
// Probability distributions: density, cumulative, and quantile functions plus
// random samplers. TODO(compiler): implement.
// ============================================================================

// fn uniform_pdf(x: Float64, a: Float64, b: Float64) -> Float64 - uniform density on [a, b].
// fn uniform_cdf(x: Float64, a: Float64, b: Float64) -> Float64 - uniform cumulative distribution on [a, b].
// fn normal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - normal density with mean mu and stddev sigma.
// fn normal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - normal cumulative distribution.
// fn normal_ppf(p: Float64, mu: Float64, sigma: Float64) -> Float64 - normal percent point (inverse CDF) for probability p.
// fn exponential_pdf(x: Float64, lambda: Float64) -> Float64 - exponential density with rate lambda.
// fn exponential_cdf(x: Float64, lambda: Float64) -> Float64 - exponential cumulative distribution.
// fn poisson_pmf(k: Float64, lambda: Float64) -> Float64 - Poisson probability mass at k with mean lambda.
// fn binomial_pmf(k: Float64, n: Float64, p: Float64) -> Float64 - binomial probability of k successes in n trials.
// fn geometric_pmf(k: Float64, p: Float64) -> Float64 - geometric probability of first success at trial k.
// fn chi_squared_pdf(x: Float64, k: Float64) -> Float64 - chi-squared density with k degrees of freedom.
// fn student_t_pdf(x: Float64, v: Float64) -> Float64 - Student's t density with v degrees of freedom.
// fn beta_pdf(x: Float64, a: Float64, b: Float64) -> Float64 - beta density with shape parameters a and b.
// fn sample_normal(mu: Float64, sigma: Float64) -> Float64 - draw a normal sample with mean mu and stddev sigma.
// fn sample_uniform(a: Float64, b: Float64) -> Float64 - draw a uniform sample from [a, b].
