// XIOM - Math: Numerical
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.numerical

// Depends on: xiom.math

// ============================================================================
// Root finding, linear solvers, interpolation, quadrature, and optimization
// primitives for numerical computing. TODO(compiler): implement.
// ============================================================================

// fn bisection(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - root of f in [a, b] via bisection.
// fn newton(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 - root of f via Newton's method from x0.
// fn secant(f: fn(Float64) -> Float64, x0: Float64, x1: Float64, tol: Float64) -> Float64 - root of f via the secant method.
// fn falsi(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - root of f in [a, b] via regula falsi.
// fn brent(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - root of f in [a, b] via Brent's method.
// fn fixed_point(g: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 - fixed point of g by iteration x = g(x).
// fn steffensen(f: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 - root of f via Steffensen's accelerated iteration.
// fn newton_multi(fs: &Vec[fn(&Vec[Float64]) -> Float64], jac: fn(&Vec[Float64]) -> Vec[Vec[Float64]], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - root of nonlinear system via Newton's method.
// fn gauss_seidel(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - solve Ax = b by Gauss-Seidel iteration.
// fn jacobi_iterative(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - solve Ax = b by Jacobi iteration.
// fn conjugate_gradient(a: &Vec[Vec[Float64]], b: &Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - solve SPD Ax = b by conjugate gradient.
// fn gradient_descent(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], lr: Float64, tol: Float64) -> Vec[Float64] - minimize f by gradient descent.
// fn newton_raphson_multi(fs: &Vec[fn(&Vec[Float64]) -> Float64], jac: fn(&Vec[Float64]) -> Vec[Vec[Float64]], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - multi-variable Newton-Raphson root of a system.
// fn bisection_root(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - bracketing root finder via bisection.
// fn newton_root(f: fn(Float64) -> Float64, fprime: fn(Float64) -> Float64, x0: Float64, tol: Float64) -> Float64 - derivative-based Newton root finder.
// fn broyden(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - solve nonlinear system by Broyden's quasi-Newton method.
// fn anderson(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], m: Int, tol: Float64) -> Vec[Float64] - Anderson-accelerated fixed-point iteration for a system.
// fn interp_linear(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 - piecewise linear interpolation at x.
// fn interp_polynomial(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 - polynomial interpolation through points (xs, ys).
// fn interp_spline(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 - default spline interpolation at x.
// fn interp_cubic(xs: &Vec[Float64], ys: &Vec[Float64], x: Float64) -> Float64 - natural cubic spline interpolation at x.
// fn interp_hermite(xs: &Vec[Float64], ys: &Vec[Float64], dys: &Vec[Float64], x: Float64) -> Float64 - Hermite interpolation using derivatives dys.
// fn spline_linear(xs: &Vec[Float64], ys: &Vec[Float64]) -> Vec[Float64] - build linear spline coefficients.
// fn spline_cubic(xs: &Vec[Float64], ys: &Vec[Float64]) -> Vec[Float64] - build cubic spline coefficients.
// fn spline_b_spline(xs: &Vec[Float64], ys: &Vec[Float64], degree: Int) -> Vec[Float64] - build B-spline control points of degree.
// fn spline_nurbs(xs: &Vec[Float64], ys: &Vec[Float64], weights: &Vec[Float64], degree: Int) -> Vec[Float64] - build NURBS curve from control points.
// fn quadrature_trapezoid(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite trapezoidal rule over [a, b].
// fn quadrature_simpson(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - composite Simpson's rule over [a, b].
// fn quadrature_gauss(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - n-point Gauss quadrature over [a, b].
// fn quadrature_adaptive(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - adaptive quadrature to tolerance tol.
// fn quadrature_monte_carlo(f: fn(Float64) -> Float64, a: Float64, b: Float64, n: Int) -> Float64 - Monte Carlo quadrature with n samples.
// fn optimize_golden(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - minimize univariate f by golden section search in [a, b].
// fn optimize_ternary(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - minimize univariate f by ternary search in [a, b].
// fn optimize_bfgs(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize f by the BFGS quasi-Newton method.
// fn optimize_lbfgs(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], m: Int, tol: Float64) -> Vec[Float64] - minimize f by limited-memory BFGS.
// fn optimize_simplex(f: fn(&Vec[Float64]) -> Float64, x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize f by Nelder-Mead simplex.
// fn optimize_powell(f: fn(&Vec[Float64]) -> Float64, x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize f by Powell's conjugate direction method.
// fn optimize_cg(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize f by nonlinear conjugate gradient.
// fn optimize_gradient(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], lr: Float64, tol: Float64) -> Vec[Float64] - minimize f by gradient descent with learning rate lr.
// fn optimize_newton(f: fn(&Vec[Float64]) -> Float64, grad: fn(&Vec[Float64]) -> Vec[Float64], hess: fn(&Vec[Float64]) -> Vec[Vec[Float64]], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize f by Newton's method with Hessian.
// fn optimize_least_squares(residuals: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - minimize sum of squared residuals.
// fn solver_single(f: fn(Float64) -> Float64, a: Float64, b: Float64, tol: Float64) -> Float64 - general single-equation root solver over [a, b].
// fn solver_system(fs: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64], tol: Float64) -> Vec[Float64] - general nonlinear system solver from x0.
