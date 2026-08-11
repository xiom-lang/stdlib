// XIOM - Stats: Probability
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.probability

// Depends on: xiom.math

// ============================================================================
// Probability distributions: density/mass and cumulative functions plus the
// normal quantile. NOTE: current implementation lives in stats/dist.xi stub -
// move the functions here during the implementation phase. TODO(compiler):
// implement. (BUG 12 is now FIXED - float containers Vec[Float64] are
// implementable.)
// ============================================================================

// fn uniform_pdf(x: Float64, a: Float64, b: Float64) -> Float64 - uniform density on [a, b].
// fn uniform_cdf(x: Float64, a: Float64, b: Float64) -> Float64 - uniform cumulative distribution on [a, b].
// fn normal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - normal density with mean mu and stddev sigma.
// fn normal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - normal cumulative distribution.
// fn normal_quantile(p: Float64, mu: Float64, sigma: Float64) -> Float64 - normal quantile (inverse CDF) for probability p.
// fn exponential_pdf(x: Float64, lambda: Float64) -> Float64 - exponential density with rate lambda.
// fn exponential_cdf(x: Float64, lambda: Float64) -> Float64 - exponential cumulative distribution.
// fn gamma_pdf(x: Float64, k: Float64, theta: Float64) -> Float64 - gamma density with shape k and scale theta.
// fn gamma_cdf(x: Float64, k: Float64, theta: Float64) -> Float64 - gamma cumulative distribution.
// fn beta_pdf(x: Float64, a: Float64, b: Float64) -> Float64 - beta density with shape parameters a and b.
// fn beta_cdf(x: Float64, a: Float64, b: Float64) -> Float64 - beta cumulative distribution.
// fn chi2_pdf(x: Float64, k: Float64) -> Float64 - chi-squared density with k degrees of freedom.
// fn chi2_cdf(x: Float64, k: Float64) -> Float64 - chi-squared cumulative distribution.
// fn t_pdf(x: Float64, v: Float64) -> Float64 - Student's t density with v degrees of freedom.
// fn t_cdf(x: Float64, v: Float64) -> Float64 - Student's t cumulative distribution.
// fn f_pdf(x: Float64, d1: Float64, d2: Float64) -> Float64 - F density with d1, d2 degrees of freedom.
// fn f_cdf(x: Float64, d1: Float64, d2: Float64) -> Float64 - F cumulative distribution.
// fn weibull_pdf(x: Float64, shape: Float64, scale: Float64) -> Float64 - Weibull density with shape and scale.
// fn weibull_cdf(x: Float64, shape: Float64, scale: Float64) -> Float64 - Weibull cumulative distribution.
// fn lognormal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - log-normal density of exp(mu + sigma Z).
// fn lognormal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 - log-normal cumulative distribution.
// fn pareto_pdf(x: Float64, alpha: Float64, xm: Float64) -> Float64 - Pareto density with shape alpha and scale xm.
// fn pareto_cdf(x: Float64, alpha: Float64, xm: Float64) -> Float64 - Pareto cumulative distribution.
// fn poisson_pmf(k: Int, lambda: Float64) -> Float64 - Poisson probability of k events with mean lambda.
// fn poisson_cdf(k: Int, lambda: Float64) -> Float64 - Poisson cumulative distribution.
// fn binomial_pmf(k: Int, n: Int, p: Float64) -> Float64 - binomial probability of k successes in n trials.
// fn binomial_cdf(k: Int, n: Int, p: Float64) -> Float64 - binomial cumulative distribution.
// fn geometric_pmf(k: Int, p: Float64) -> Float64 - geometric probability of first success at trial k.
// fn geometric_cdf(k: Int, p: Float64) -> Float64 - geometric cumulative distribution.
// fn negative_binomial_pmf(k: Int, r: Int, p: Float64) -> Float64 - negative binomial probability of k failures before r successes.
// fn negative_binomial_cdf(k: Int, r: Int, p: Float64) -> Float64 - negative binomial cumulative distribution.
// fn hypergeometric_pmf(k: Int, n: Int, K: Int, N: Int) -> Float64 - probability of k successes drawing n from a population of N with K successes.
// fn hypergeometric_cdf(k: Int, n: Int, K: Int, N: Int) -> Float64 - hypergeometric cumulative distribution.
