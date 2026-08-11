// XIOM - Stats: Regress
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.stats.regress

// Depends on: xiom.math

// ============================================================================
// Regression models and correlation measures. TODO(compiler): implement.
// ============================================================================

// type RegressionResult - linear fit; struct { slope: Float64; intercept: Float64; r2: Float64 }.
// fn linear_regression(x: &Vec[Float64], y: &Vec[Float64]) -> RegressionResult - least-squares linear fit with R-squared.
// fn slope(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - regression slope.
// fn intercept(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - regression intercept.
// fn r_squared(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - coefficient of determination.
// fn pearson_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - Pearson correlation coefficient.
// fn spearman_correlation(x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - rank-based Spearman correlation.
// fn polynomial_regression(x: &Vec[Float64], y: &Vec[Float64], degree: Int) -> Vec[Float64] - least-squares polynomial coefficients (lowest degree first).
// fn exponential_fit(x: &Vec[Float64], y: &Vec[Float64]) -> (Float64, Float64) - tuple is (a, b) for y = a * exp(b * x).
// fn predict_line(slope: Float64, intercept: Float64, x: Float64) -> Float64 - predicted value slope * x + intercept.
// fn residuals(x: &Vec[Float64], y: &Vec[Float64], slope: Float64, intercept: Float64) -> Vec[Float64] - observed minus predicted values.
