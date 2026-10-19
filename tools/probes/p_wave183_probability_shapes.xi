// p_wave183_probability_shapes.xi -- wave-183 probability contract shapes
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the wave-183 xiom.stats.probability domain clauses: NaN for
// out-of-domain parameters, zero density at the closed-form boundaries,
// and the exact predict_line formula.
// Expected: rc 0.

module p_wave183_probability_shapes

use xiom.stats.probability;
use xiom.stats.regress;
use xiom.math;
use xiom.io;

fn main() -> Int {
  if !math.is_nan(probability.normal_pdf(0.0, 0.0, -1.0)) { return 1; }
  if !math.is_nan(probability.normal_cdf(0.0, 0.0, 0.0)) { return 2; }
  if !math.is_nan(probability.normal_quantile(0.0, 0.0, 1.0)) { return 3; }
  if !math.is_nan(probability.normal_quantile(1.0, 0.0, 1.0)) { return 4; }
  if !math.is_nan(probability.exponential_pdf(-1.0, 1.0)) { return 5; }
  if !math.is_nan(probability.exponential_pdf(1.0, -1.0)) { return 6; }
  if !math.is_nan(probability.gamma_pdf(-1.0, 1.0, 1.0)) { return 7; }
  if !math.is_nan(probability.gamma_pdf(1.0, 0.0, 1.0)) { return 8; }
  if !math.is_nan(probability.gamma_pdf(1.0, 1.0, 0.0)) { return 9; }
  if !math.is_nan(probability.beta_pdf(0.5, 0.0, 1.0)) { return 10; }
  if probability.beta_pdf(0.0, 1.0, 1.0) != 0.0 { return 11; }
  if probability.beta_pdf(1.0, 1.0, 1.0) != 0.0 { return 12; }
  if !math.is_nan(probability.chi2_pdf(-1.0, 2.0)) { return 13; }
  if probability.chi2_pdf(0.0, 4.0) != 0.0 { return 14; }
  if probability.chi2_pdf(0.0, 2.0) != 0.5 { return 15; }
  if !math.is_nan(probability.t_pdf(0.0, 0.0)) { return 16; }
  if !math.is_nan(probability.t_cdf(0.0, 0.0)) { return 17; }
  if !math.is_nan(probability.f_pdf(0.0, 1.0, 1.0)) { return 18; }
  if !math.is_nan(probability.f_pdf(1.0, 0.0, 1.0)) { return 19; }
  if !math.is_nan(probability.f_pdf(1.0, 1.0, 0.0)) { return 20; }
  if !math.is_nan(probability.weibull_pdf(-1.0, 1.0, 1.0)) { return 21; }
  if probability.weibull_pdf(0.0, 2.0, 1.0) != 0.0 { return 22; }
  if !math.is_nan(probability.lognormal_pdf(0.0, 0.0, 1.0)) { return 23; }
  if !math.is_nan(probability.lognormal_cdf(0.0, 0.0, 1.0)) { return 24; }
  if !math.is_nan(probability.lognormal_pdf(1.0, 0.0, 0.0)) { return 25; }
  if !math.is_nan(probability.pareto_pdf(0.0, 1.0, 1.0)) { return 26; }
  if probability.pareto_cdf(0.0, 1.0, 1.0) != 0.0 { return 27; }
  if !math.is_nan(probability.pareto_cdf(1.0, 0.0, 1.0)) { return 28; }
  if !math.is_nan(probability.binomial_pmf(-1, 5, 0.5)) { return 29; }
  if !math.is_nan(probability.binomial_pmf(1, 5, 1.5)) { return 30; }
  if !math.is_nan(probability.binomial_pmf(6, 5, 0.5)) { return 31; }
  if !math.is_nan(probability.negative_binomial_pmf(-1, 1, 0.5)) { return 32; }
  if !math.is_nan(probability.negative_binomial_pmf(1, 1, 0.0)) { return 33; }
  if !math.is_nan(probability.negative_binomial_pmf(1, 0, 0.5)) { return 34; }
  if !math.is_nan(probability.negative_binomial_cdf(1, 1, 1.5)) { return 35; }
  if !math.is_nan(probability.hypergeometric_pmf(10, 5, 5, 10)) { return 36; }
  if regress.predict_line(2.0, 3.0, 4.0) != 11.0 { return 37; }

  io.println("p_wave183_probability_shapes: OK");
  return 0;
}
