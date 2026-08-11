// XIOM - Math: Chaos Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.chaos

// Depends on: xiom.math

// ============================================================================
// Chaotic dynamical systems, fractals, and sensitive-dependence diagnostics
// such as Lyapunov exponents. TODO(compiler): implement.
// ============================================================================

// fn logistic_map(r: Float64, x0: Float64, n: Int) -> Vec[Float64] - iterate x_{k+1} = r*x*(1-x) for n steps.
// fn lorenz_system(sigma: Float64, rho: Float64, beta: Float64, x0: &Vec[Float64], steps: Int, dt: Float64) -> Vec[Vec[Float64]] - integrate the Lorenz ODE system.
// fn rossler_system(a: Float64, b: Float64, c: Float64, x0: &Vec[Float64], steps: Int, dt: Float64) -> Vec[Vec[Float64]] - integrate the Rossler ODE system.
// fn henon_map(a: Float64, b: Float64, x0: Float64, y0: Float64, n: Int) -> Vec[(Float64, Float64)] - iterate the Henon map.
// fn bifurcation_diagram(r_min: Float64, r_max: Float64, steps: Int, transients: Int) -> Vec[(Float64, Float64)] - logistic-map bifurcation diagram points.
// fn lyapunov_exponent(orbit: &Vec[Float64]) -> Float64 - estimated largest Lyapunov exponent of a time series.
// fn strange_attractor(dynamics: fn(&Vec[Float64]) -> Vec[Float64], x0: &Vec[Float64], n: Int) -> Vec[Vec[Float64]] - trajectory of a chaotic attractor.
// fn fractal_dimension(points: &Vec[(Float64, Float64)]) -> Float64 - box-counting dimension of a point set.
// fn mandelbrot_set(c_re: Float64, c_im: Float64, max_iter: Int) -> Int - escape iterations of c; max_iter means inside the set.
// fn julia_set(c_re: Float64, c_im: Float64, z_re: Float64, z_im: Float64, max_iter: Int) -> Int - escape iterations for fixed parameter c.
// fn burning_ship(c_re: Float64, c_im: Float64, max_iter: Int) -> Int - burning-ship fractal escape count.
// fn newton_fractal(coeffs: &Vec[Float64], z: Float64, max_iter: Int) -> Int - index of the root a point converges to under Newton iteration.
// fn tent_map(mu: Float64, x0: Float64, n: Int) -> Vec[Float64] - iterate the tent map for n steps.
