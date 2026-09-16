// XIOM - Stats: Probability
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.stats.probability

// Depends on: xiom.math

// ============================================================================
// Probability distributions: density/mass and cumulative functions plus the
// normal quantile.
//
// Implemented with the closed forms and the math.special gamma/beta/incomplete
// gamma/beta and erfinv/erf machinery. NaN is returned for out-of-domain
// inputs. Complexity is documented per function.
// ============================================================================

use xiom.math;

const _SQRT_2PI: Float64 = 2.5066282746310002;
const _SQRT2: Float64 = 1.4142135623730951;

// Uniform density on [a, b]. Complexity: O(1).
pub fn uniform_pdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if b <= a { return 0.0 / 0.0; }
  if x >= a && x <= b { return 1.0 / (b - a); }
  return 0.0;
}

// Uniform cumulative distribution on [a, b]. Complexity: O(1).
pub fn uniform_cdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if b <= a { return 0.0 / 0.0; }
  if x <= a { return 0.0; }
  if x >= b { return 1.0; }
  return (x - a) / (b - a);
}

// Normal density with mean mu and stddev sigma. Complexity: O(1).
pub fn normal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 { return 0.0 / 0.0; }
  var d = (x - mu) / sigma;
  return math.exp(-0.5 * d * d) / (sigma * _SQRT_2PI);
}

// Normal cumulative distribution. Complexity: O(1).
pub fn normal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 { return 0.0 / 0.0; }
  var z = (x - mu) / (sigma * _SQRT2);
  return 0.5 * (1.0 + math.special.erf(z));
}

// Normal quantile (inverse CDF) for probability p. Complexity: O(1).
pub fn normal_quantile(p: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if p <= 0.0 || p >= 1.0 { return 0.0 / 0.0; }
  var z = math.special.erfinv(2.0 * p - 1.0) * _SQRT2;
  return mu + sigma * z;
}

// Exponential density with rate lambda. Complexity: O(1).
pub fn exponential_pdf(x: Float64, lambda: Float64) -> Float64 {
  if lambda <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  return lambda * math.exp(-lambda * x);
}

// Exponential cumulative distribution. Complexity: O(1).
pub fn exponential_cdf(x: Float64, lambda: Float64) -> Float64 {
  if lambda <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  return 1.0 - math.exp(-lambda * x);
}

// Gamma density with shape k and scale theta. Complexity: O(1).
pub fn gamma_pdf(x: Float64, k: Float64, theta: Float64) -> Float64 {
  if k <= 0.0 || theta <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 {
    if k < 1.0 { return 1.0 / 0.0; }
    if k == 1.0 { return 1.0 / theta; }
    return 0.0;
  }
  var log_p = (k - 1.0) * math.ln(x) - x / theta
    - k * math.ln(theta) - math.special.gamma_ln(k);
  return math.exp(log_p);
}

// Gamma cumulative distribution: P(k, x/theta). Complexity: O(iterations).
pub fn gamma_cdf(x: Float64, k: Float64, theta: Float64) -> Float64 {
  if k <= 0.0 || theta <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  return math.special.incomplete_gamma(k, x / theta);
}

// Beta density with shape parameters a and b. Complexity: O(1).
pub fn beta_pdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 || x >= 1.0 { return 0.0; }
  var log_p = (a - 1.0) * math.ln(x) + (b - 1.0) * math.ln(1.0 - x)
    - math.special.beta_ln(a, b);
  return math.exp(log_p);
}

// Beta cumulative distribution: I_x(a, b). Complexity: O(iterations).
pub fn beta_cdf(x: Float64, a: Float64, b: Float64) -> Float64 {
  if a <= 0.0 || b <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  if x >= 1.0 { return 1.0; }
  return math.special.incomplete_beta(a, b, x);
}

// Chi-squared density with k degrees of freedom. Complexity: O(1).
pub fn chi2_pdf(x: Float64, k: Float64) -> Float64 {
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

// Chi-squared cumulative distribution: P(k/2, x/2). Complexity: O(iterations).
pub fn chi2_cdf(x: Float64, k: Float64) -> Float64 {
  if k <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  return math.special.incomplete_gamma(k / 2.0, x / 2.0);
}

// Student's t density with v degrees of freedom. Complexity: O(1).
pub fn t_pdf(x: Float64, v: Float64) -> Float64 {
  if v <= 0.0 { return 0.0 / 0.0; }
  var log_p = math.special.gamma_ln((v + 1.0) / 2.0) - math.special.gamma_ln(v / 2.0)
    - 0.5 * math.ln(v * 3.141592653589793)
    - (v + 1.0) / 2.0 * math.ln(1.0 + x * x / v);
  return math.exp(log_p);
}

// Student's t cumulative distribution via the regularized incomplete beta.
// Complexity: O(iterations).
pub fn t_cdf(x: Float64, v: Float64) -> Float64 {
  if v <= 0.0 { return 0.0 / 0.0; }
  var t2 = x * x;
  var z = v / (v + t2);
  var ib = math.special.incomplete_beta(v / 2.0, 0.5, z);
  if x >= 0.0 {
    return 1.0 - 0.5 * ib;
  }
  return 0.5 * ib;
}

// F density with d1, d2 degrees of freedom. Complexity: O(1).
pub fn f_pdf(x: Float64, d1: Float64, d2: Float64) -> Float64 {
  if x <= 0.0 || d1 <= 0.0 || d2 <= 0.0 { return 0.0 / 0.0; }
  var log_p = 0.5 * d1 * math.ln(d1) + 0.5 * d2 * math.ln(d2)
    + (d1 / 2.0 - 1.0) * math.ln(x)
    - 0.5 * (d1 + d2) * math.ln(d2 + d1 * x)
    - math.special.beta_ln(d1 / 2.0, d2 / 2.0);
  return math.exp(log_p);
}

// F cumulative distribution: I_{d1 x / (d1 x + d2)}(d1/2, d2/2).
// Complexity: O(iterations).
pub fn f_cdf(x: Float64, d1: Float64, d2: Float64) -> Float64 {
  if d1 <= 0.0 || d2 <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  var z = d1 * x / (d1 * x + d2);
  return math.special.incomplete_beta(d1 / 2.0, d2 / 2.0, z);
}

// Weibull density with shape and scale. Complexity: O(1).
pub fn weibull_pdf(x: Float64, shape: Float64, scale: Float64) -> Float64 {
  if shape <= 0.0 || scale <= 0.0 || x < 0.0 { return 0.0 / 0.0; }
  if x == 0.0 {
    if shape < 1.0 { return 1.0 / 0.0; }
    if shape == 1.0 { return 1.0 / scale; }
    return 0.0;
  }
  var t = x / scale;
  var p = math.pow(t, shape - 1.0);
  return (shape / scale) * p * math.exp(-math.pow(t, shape));
}

// Weibull cumulative distribution. Complexity: O(1).
pub fn weibull_cdf(x: Float64, shape: Float64, scale: Float64) -> Float64 {
  if shape <= 0.0 || scale <= 0.0 { return 0.0 / 0.0; }
  if x <= 0.0 { return 0.0; }
  return 1.0 - math.exp(-math.pow(x / scale, shape));
}

// Log-normal density of exp(mu + sigma Z). Complexity: O(1).
pub fn lognormal_pdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 || x <= 0.0 { return 0.0 / 0.0; }
  var lx = math.ln(x);
  var d = (lx - mu) / sigma;
  return math.exp(-0.5 * d * d) / (x * sigma * _SQRT_2PI);
}

// Log-normal cumulative distribution. Complexity: O(1).
pub fn lognormal_cdf(x: Float64, mu: Float64, sigma: Float64) -> Float64 {
  if sigma <= 0.0 || x <= 0.0 { return 0.0 / 0.0; }
  var z = (math.ln(x) - mu) / (sigma * _SQRT2);
  return 0.5 * (1.0 + math.special.erf(z));
}

// Pareto density with shape alpha and scale xm. Complexity: O(1).
pub fn pareto_pdf(x: Float64, alpha: Float64, xm: Float64) -> Float64 {
  if alpha <= 0.0 || xm <= 0.0 || x < xm { return 0.0 / 0.0; }
  return alpha * math.pow(xm, alpha) / math.pow(x, alpha + 1.0);
}

// Pareto cumulative distribution. Complexity: O(1).
pub fn pareto_cdf(x: Float64, alpha: Float64, xm: Float64) -> Float64 {
  if alpha <= 0.0 || xm <= 0.0 { return 0.0 / 0.0; }
  if x < xm { return 0.0; }
  return 1.0 - math.pow(xm / x, alpha);
}

// Poisson probability of k events with mean lambda (integer k).
// Complexity: O(1).
pub fn poisson_pmf(k: Int, lambda: Float64) -> Float64 {
  if lambda < 0.0 || k < 0 { return 0.0 / 0.0; }
  if lambda == 0.0 {
    if k == 0 { return 1.0; }
    return 0.0;
  }
  var log_p = -lambda + (k as Float64) * math.ln(lambda) - math.special.gamma_ln((k + 1) as Float64);
  return math.exp(log_p);
}

// Poisson cumulative distribution. Complexity: O(k).
pub fn poisson_cdf(k: Int, lambda: Float64) -> Float64 {
  if k < 0 || lambda < 0.0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var i = 0;
  while i <= k {
    sum = sum + poisson_pmf(i, lambda);
    i = i + 1;
  }
  return sum;
}

// Binomial probability of k successes in n trials. Complexity: O(1).
pub fn binomial_pmf(k: Int, n: Int, p: Float64) -> Float64 {
  if p < 0.0 || p > 1.0 || k < 0 || n < 0 || k > n { return 0.0 / 0.0; }
  var log_p = math.special.gamma_ln((n + 1) as Float64) - math.special.gamma_ln((k + 1) as Float64)
    - math.special.gamma_ln((n - k + 1) as Float64)
    + (k as Float64) * math.ln(p) + ((n - k) as Float64) * math.ln(1.0 - p);
  return math.exp(log_p);
}

// Binomial cumulative distribution. Complexity: O(n).
pub fn binomial_cdf(k: Int, n: Int, p: Float64) -> Float64 {
  if k < 0 || n < 0 { return 0.0 / 0.0; }
  if k >= n { return 1.0; }
  var sum = 0.0;
  var i = 0;
  while i <= k {
    sum = sum + binomial_pmf(i, n, p);
    i = i + 1;
  }
  return sum;
}

// Geometric probability of first success at trial k. Complexity: O(1).
pub fn geometric_pmf(k: Int, p: Float64) -> Float64 {
  if p <= 0.0 || p > 1.0 || k < 1 { return 0.0 / 0.0; }
  return math.pow(1.0 - p, (k - 1) as Float64) * p;
}

// Geometric cumulative distribution. Complexity: O(k).
pub fn geometric_cdf(k: Int, p: Float64) -> Float64 {
  if p <= 0.0 || p > 1.0 || k < 1 { return 0.0 / 0.0; }
  return 1.0 - math.pow(1.0 - p, k as Float64);
}

// Negative binomial probability of k failures before r successes.
// Complexity: O(1).
pub fn negative_binomial_pmf(k: Int, r: Int, p: Float64) -> Float64 {
  if p <= 0.0 || p > 1.0 || k < 0 || r <= 0 { return 0.0 / 0.0; }
  var log_p = math.special.gamma_ln((k + r) as Float64) - math.special.gamma_ln((k + 1) as Float64)
    - math.special.gamma_ln(r as Float64)
    + (r as Float64) * math.ln(p) + (k as Float64) * math.ln(1.0 - p);
  return math.exp(log_p);
}

// Negative binomial cumulative distribution. Complexity: O(k).
pub fn negative_binomial_cdf(k: Int, r: Int, p: Float64) -> Float64 {
  if k < 0 || r <= 0 { return 0.0 / 0.0; }
  var sum = 0.0;
  var i = 0;
  while i <= k {
    sum = sum + negative_binomial_pmf(i, r, p);
    i = i + 1;
  }
  return sum;
}

// Hypergeometric probability of k successes drawing n from a population of N
// with K successes. Complexity: O(1).
pub fn hypergeometric_pmf(k: Int, n: Int, K: Int, N: Int) -> Float64 {
  if n < 0 || K < 0 || N <= 0 || k < 0 || k > n || k > K || n - k > N - K {
    return 0.0 / 0.0;
  }
  var log_p = math.special.gamma_ln((K + 1) as Float64) - math.special.gamma_ln((k + 1) as Float64)
    - math.special.gamma_ln((K - k + 1) as Float64)
    + math.special.gamma_ln((N - K + 1) as Float64) - math.special.gamma_ln((n - k + 1) as Float64)
    - math.special.gamma_ln((N - K - n + k + 1) as Float64)
    - math.special.gamma_ln((N + 1) as Float64) + math.special.gamma_ln((n + 1) as Float64)
    + math.special.gamma_ln((N - n + 1) as Float64);
  return math.exp(log_p);
}

// Hypergeometric cumulative distribution. Complexity: O(n).
pub fn hypergeometric_cdf(k: Int, n: Int, K: Int, N: Int) -> Float64 {
  if k < 0 || n < 0 || K < 0 || N <= 0 { return 0.0 / 0.0; }
  if k >= K { return 1.0; }
  var sum = 0.0;
  var i = 0;
  while i <= k {
    sum = sum + hypergeometric_pmf(i, n, K, N);
    i = i + 1;
  }
  return sum;
}
