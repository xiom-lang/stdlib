// XIOM - Math: Optimization
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.optimization

// Depends on: xiom.math

// ============================================================================
// Mathematical programming (LP, QP, NLP) and metaheuristic optimization.
// TODO(compiler): implement.
// ============================================================================

// fn linear_programming(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64], bounds: &Vec[Vec[Float64]]) -> Vec[Float64] - minimize c'x subject to Ax <= b and bounds.
// fn integer_programming(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Int] - solve linear program with integer variables.
// fn mixed_integer_programming(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64], int_vars: &Vec[Bool]) -> Vec[Float64] - solve MILP with continuous and integer variables.
// fn quadratic_programming(q: &Vec[Vec[Float64]], c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - minimize 1/2 x'Qx + c'x subject to Ax <= b.
// fn nonlinear_programming(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] - minimize f subject to constraints cons from x0.
// fn lp_simplex(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - solve linear program by the simplex method.
// fn lp_interior_point(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - solve linear program by the interior-point method.
// fn branch_and_bound(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - solve ILP by branch and bound.
// fn cutting_plane(c: &Vec[Float64], a: &Vec[Vec[Float64]], b: &Vec[Float64]) -> Vec[Float64] - solve ILP by the cutting-plane method.
// fn sequential_quadratic(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] - minimize constrained f by sequential quadratic programming.
// fn penalty_method(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] - minimize constrained f via penalty functions.
// fn barrier_method(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] - minimize inequality-constrained f via barrier functions.
// fn augmented_lagrangian(f: fn(&Vec[Float64]) -> Float64, cons: &Vec[fn(&Vec[Float64]) -> Float64], x0: &Vec[Float64]) -> Vec[Float64] - minimize constrained f via the augmented Lagrangian method.
// fn genetic_algorithm(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], pop_size: Int, generations: Int) -> Vec[Float64] - minimize f by a genetic algorithm.
// fn simulated_annealing(f: fn(&Vec[Float64]) -> Float64, x0: &Vec[Float64], t0: Float64, schedule: fn(Float64, Float64) -> Float64) -> Vec[Float64] - minimize f by simulated annealing from x0.
// fn particle_swarm(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], particles: Int, iters: Int) -> Vec[Float64] - minimize f by particle swarm optimization.
// fn ant_colony(cost: fn(&Vec[Int]) -> Float64, n_nodes: Int, iters: Int) -> Vec[Int] - optimize combinatorial problem by ant colony optimization.
// fn differential_evolution(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], pop_size: Int, iters: Int) -> Vec[Float64] - minimize f by differential evolution.
// fn bayesian_optimization(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], iters: Int) -> Vec[Float64] - minimize f by Bayesian optimization with surrogate model.
// fn grid_search(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], n: Int) -> Vec[Float64] - minimize f by exhaustive grid search with n points per axis.
// fn random_search(f: fn(&Vec[Float64]) -> Float64, bounds: &Vec[Vec[Float64]], iters: Int) -> Vec[Float64] - minimize f by uniform random sampling.
