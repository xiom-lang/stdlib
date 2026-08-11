// XIOM - Math: Approximation Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.approximation

// Depends on: xiom.math

// ============================================================================
// Function approximation and interpolation: polynomials, rationals, splines,
// and optimal minimax methods. TODO(compiler): implement.
// ============================================================================

// fn interpolation(x: &Vec[Float64], y: &Vec[Float64], point: Float64) -> Float64 - interpolated value at point.
// fn extrapolation(x: &Vec[Float64], y: &Vec[Float64], point: Float64) -> Float64 - extrapolated value outside the sample range.
// fn polynomial_approx(x: &Vec[Float64], y: &Vec[Float64], degree: Int) -> Vec[Float64] - least-squares polynomial coefficients.
// fn rational_approx(x: &Vec[Float64], y: &Vec[Float64], m: Int, n: Int) -> Vec[Float64] - rational approximation coefficients.
// fn trigonometric_approx(x: &Vec[Float64], y: &Vec[Float64], harmonics: Int) -> Vec[Float64] - Fourier series coefficients.
// fn exponential_approx(x: &Vec[Float64], y: &Vec[Float64]) -> Vec[Float64] - fitted exponential model coefficients.
// fn chebyshev_approx(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] - Chebyshev series coefficients.
// fn least_squares(a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - normal-equation least-squares solution.
// fn minimax(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] - minimax polynomial coefficients.
// fn pade_approx(f: fn(Float64) -> Float64, m: Int, n: Int, x0: Float64) -> Vec[Float64] - Pade rational approximation coefficients.
// fn remez(f: fn(Float64) -> Float64, a: Float64, b: Float64, degree: Int) -> Vec[Float64] - Remez exchange algorithm minimax polynomial.
// fn spline_approx(x: &Vec[Float64], y: &Vec[Float64]) -> Vec[Vec[Float64]] - cubic spline segment coefficients.
// fn best_approx(f: fn(Float64) -> Float64, basis: &Vec[fn(Float64) -> Float64], a: Float64, b: Float64) -> Vec[Float64] - best coefficients in the given basis.
