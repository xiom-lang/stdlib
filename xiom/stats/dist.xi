// XIOM - Stats: Dist
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.dist

// Depends on: xiom.math

// ============================================================================
// Probability distributions: density, cumulative, and quantile functions plus
// random samplers.
//
// Densities and cumulative functions are implemented with the closed forms
// and the math.special gamma/erf/erfinv machinery. NaN is returned for
// out-of-domain inputs. Complexity is documented per function.
// ============================================================================

use xiom.math;

const _SQRT_2PI: Float64 = 2.5066282746310002;

/// Uniform density on [a, b]. Complexity: O(1).
pub fn uniform_pdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if b <= a { return 0.0 / 0.0; }
  if x >= a && x <= b { return 1.0 / (b - a); }
  return 0.0;
}

/// Uniform cumulative distribution on [a, b]. Complexity: O(1).
pub fn uniform_cdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if b <= a { return 0.0 / 0.0; }
  if x <= a { return 0.0; }
  if x >= b { return 1.0; }
  return (x - a) / (b - a);
}

/// Normal density with mean mu and stddev sigma. NaN for sigma <= 0.
/// Complexity: O(1).
pub fn normal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 { return 0.0 / 0.0; }
  var d = (x - mu) / sigma;
  return math.exp(-0.5 * d * d) / (sigma * _SQRT_2PI);
}

/// Normal cumulative distribution. Complexity: O(1).
pub fn normal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 { return 0.0 / 0.0; }
  var z = (x - mu) / (sigma * 1.4142135623730951);
  return 0.5 * (1.0 + math.special.erf(z));
}

/// Normal percent point (inverse CDF) for probability p in (0, 1).
/// Complexity: O(1).
pub fn normal_ppf(p: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if p <= 0.0 || p >= 1.0 { return 0.0 / 0.0; }
  var z = math.special.erfinv(2.0 * p - 1.0) * 1.4142135623730951;
  return mu + sigma * z;
}

/// Exponential density with rate lambda. Complexity: O(1).
pub fn exponential_pdf(x: Float64, lambda: Float64) -> Float64 {
  if lambda <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  return lambda * math.exp(-lambda * x);
}

/// Exponential cumulative distribution. Complexity: O(1).
pub fn exponential_cdf(x: Float64, lambda: Float64) -> Float64 {
  if lambda <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  return 1.0 - math.exp(-lambda * x);
}

/// Poisson probability mass at k with mean lambda (k is passed as a Float64
/// and used via the gamma function, so non-integer k is defined as well).
/// Complexity: O(1).
pub fn poisson_pmf(k: Float64, lambda: Float64) -> Float64 {
  if lambda < 0.0 || k < 0.0 { return 0.0 / 0.0; }
  if lambda == 0.0 {
    if k == 0.0 { return 1.0; }
    return 0.0;
  }
  var log_p = -lambda + k * math.ln(lambda) - math.special.gamma_ln(k + 1.0);
  return math.exp(log_p);
}

/// Binomial probability of k successes in n trials (k and n passed as
/// Float64). NaN for invalid parameters. Complexity: O(1).
pub fn binomial_pmf(k: Float64, n: Float64, p: Float64) -> Float64 {
  if p < 0.0 || p > 1.0 || k < 0.0 || n < 0.0 || k > n { return 0.0 / 0.0; }
  var log_p = math.special.gamma_ln(n + 1.0) - math.special.gamma_ln(k + 1.0)
    - math.special.gamma_ln(n - k + 1.0) + k * math.ln(p) + (n - k) * math.ln(1.0 - p);
  return math.exp(log_p);
}

/// Geometric probability of first success at trial k. Complexity: O(1).
pub fn geometric_pmf(k: Float64, p: Float64) -> Float64 {
  if p <= 0.0 || p > 1.0 || k < 1.0 { return 0.0 / 0.0; }
  return math.pow(1.0 - p, k - 1.0) * p;
}

/// Chi-squared density with k degrees of freedom. Complexity: O(1).
pub fn chi_squared_pdf(x: Float64, k: Float64) -> Float64 {
  if x < 0.0 || k <= 0.0 { return 0.0 / 0.0; }
  if x == 0.0 {
    if k < 2.0 { return 1.0 / 0.0; }
    if k == 2.0 { return 0.5; }
    return 0.0;
  }
  var log_p = (k / 2.0 - 1.0) * math.ln(x) - x / 2.0
    - (k / 2.0) * math.ln(2.0) - math.special.gamma_ln(k / 2.0);
  return math.exp(log_p);
}

/// Student's t density with v degrees of freedom. Complexity: O(1).
pub fn student_t_pdf(x: Float64, v: Float64) -> Float64 {
  if v <= 0.0 { return 0.0 / 0.0; }
  var log_p = math.special.gamma_ln((v + 1.0) / 2.0) - math.special.gamma_ln(v / 2.0)
    - 0.5 * math.ln(v * 3.141592653589793)
    - (v + 1.0) / 2.0 * math.ln(1.0 + x * x / v);
  return math.exp(log_p);
}

/// Beta density with shape parameters a and b. Complexity: O(1).
pub fn beta_pdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 || x >= 1.0 { return 0.0; }
  var log_p = (a - 1.0) * math.ln(x) + (b - 1.0) * math.ln(1.0 - x)
    - math.special.beta_ln(a, b);
  return math.exp(log_p);
}

/// Draw a normal sample with mean mu and stddev sigma (Box-Muller over the
/// seeded xiom RNG). Complexity: O(1).
pub fn sample_normal(mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 { return 0.0 / 0.0; }
  var u1 = math.random();
  var u2 = math.random();
  if u1 <= 0.0 { u1 = 1.0e-12; }
  var z = math.sqrt(-2.0 * math.ln(u1)) * math.cos(6.283185307179586 * u2);
  return mu + sigma * z;
}

/// Draw a uniform sample from [a, b]. Complexity: O(1).
pub fn sample_uniform(a: Float64, b: Float64) -> Float64 {
  if b <= a { return 0.0 / 0.0; }
  return a + (b - a) * math.random();
}
