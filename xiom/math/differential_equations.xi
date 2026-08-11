// XIOM - Math: Differential Equations
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.differential_equations

// Depends on: xiom.math

// ============================================================================
// Numerical solvers for ordinary and partial differential equations: Euler,
// Runge-Kutta, adaptive, BDF, and spatial discretizations. NOTE: this module
// is new - no current implementation exists. TODO(compiler): implement.
// ============================================================================

// fn solve_ode_euler(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] - explicit Euler steps from t0 to t1.
// fn solve_ode_rk4(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] - classical fourth-order Runge-Kutta.
// fn solve_ode_rk45(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, tol: Float64) -> Vec[Float64] - adaptive Dormand-Prince (RK45) to tolerance tol.
// fn solve_ode_adaptive(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, tol: Float64) -> Vec[Float64] - generic adaptive step-size integrator.
// fn solve_ode_bdf(f: fn(Float64, Float64) -> Float64, y0: Float64, t0: Float64, t1: Float64, n: Int) -> Vec[Float64] - backward differentiation formula for stiff systems.
// fn solve_pde_fd(f: fn(Float64, Float64) -> Float64, t0: Float64, t1: Float64, nx: Int, nt: Int) -> Vec[Vec[Float64]] - finite-difference PDE discretization.
// fn solve_pde_fem(f: fn(Float64, Float64) -> Float64, t0: Float64, t1: Float64, nx: Int, nt: Int) -> Vec[Vec[Float64]] - finite-element PDE discretization.
