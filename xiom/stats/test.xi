// XIOM - Stats: Test
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.test

// Depends on: xiom.math

// ============================================================================
// Hypothesis testing and interval estimation. TODO(compiler): implement.
// ============================================================================

// fn t_test_one_sample(data: &Vec[Float64], mu: Float64) -> Float64 - one-sample t statistic against population mean mu.
// fn t_test_two_sample(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - independent two-sample t statistic (unequal variance).
// fn t_test_paired(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - paired t statistic on difference a - b.
// fn chi_squared_test(observed: &Vec[Int], expected: &Vec[Float64]) -> Float64 - chi-squared goodness-of-fit statistic.
// fn f_test(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - F statistic as the ratio of sample variances.
// fn anova_one_way(groups: &Vec[Vec[Float64]]) -> Float64 - one-way ANOVA F statistic across groups.
// fn p_value_from_t(t: Float64, df: Float64) -> Float64 - two-tailed p-value for a t statistic with df degrees of freedom.
// fn p_value_from_chi2(x: Float64, df: Float64) -> Float64 - right-tail p-value for a chi-squared statistic.
// fn z_score(x: Float64, mu: Float64, sigma: Float64) -> Float64 - standardized score (x - mu) / sigma.
// fn confidence_interval(data: &Vec[Float64], level: Float64) -> (Float64, Float64) - tuple is (lower, upper) of the level confidence interval.
// fn standard_error(data: &Vec[Float64]) -> Float64 - standard error of the mean.
