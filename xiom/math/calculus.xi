// XIOM - Math: Calculus
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.calculus

// Depends on: xiom.math

// ============================================================================
// Numerical differentiation and integration: finite differences, quadrature,
// limits, and vector calculus operators. NOTE: current implementation lives in
// math/differential.xi + math/integral.xi stubs - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn derivative(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - first derivative of f at x with step h.
// fn derivative_2nd(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - second derivative of f at x.
// fn derivative_3rd(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - third derivative of f at x.
// fn integrate(f: fn(Float64) -> Float64, a: Float64, b: Float64) -> Float64 - default high-accuracy definite integral over [a, b].
// fn integrate_trapezoid(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite trapezoidal rule with n subintervals.
// fn integrate_simpson(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite Simpson's rule with n subintervals.
// fn integrate_romberg(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - Romberg integration to tolerance tol.
// fn integrate_gauss(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - n-point Gauss quadrature over [a, b].
// fn limit(f: fn(Float64) -> Float64, x: Float64) -> Float64 - two-sided limit of f as the argument approaches x.
// fn limit_left(f: fn(Float64) -> Float64, x: Float64) -> Float64 - one-sided limit from below.
// fn limit_right(f: fn(Float64) -> Float64, x: Float64) -> Float64 - one-sided limit from above.
// fn is_continuous(f: fn(Float64) -> Float64, x: Float64, tol: Float64) -> Bool - whether f is continuous at x within tol.
// fn gradient(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Float64] - gradient vector of f at x.
// fn partial_derivative(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64], i: Int, h: Float64) -> Float64 - partial derivative with respect to x[i].
// fn jacobian(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Vec[Float64]] - Jacobian matrix of functions fs at x.
// fn hessian(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Vec[Float64]] - Hessian matrix of second partials at x.
// fn laplacian(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Float64 - Laplacian of f at x.
// fn curl(f: fn(&Vec[Float64]) -> Vec[Float64], x: &Vec[Float64]) -> Vec[Float64] - curl of a 3D vector field f at x.
// fn divergence(f: fn(&Vec[Float64]) -> Vec[Float64], x: &Vec[Float64]) -> Float64 - divergence of a vector field f at x.
