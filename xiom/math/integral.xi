// XIOM - Math: Integral
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.integral

// Depends on: xiom.math

// ============================================================================
// Numerical quadrature over [a, b]: Newton-Cotes, adaptive, and Gaussian rules.
// TODO(compiler): implement.
// ============================================================================

// fn integrate_riemann(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - Riemann sum with n subintervals.
// fn integrate_trapezoid(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite trapezoidal rule.
// fn integrate_midpoint(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite midpoint rule.
// fn integrate_simpson(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite Simpson's rule.
// fn integrate_adaptive(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - adaptive refinement to tolerance tol.
// fn integrate_gauss_legendre(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - n-point Gauss-Legendre quadrature.
// fn definite_integral(f: fn(Float64) -> Float64, a: Float64, b: Float64) -> Float64 - default high-accuracy definite integral.
