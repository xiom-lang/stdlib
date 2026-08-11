// XIOM - Math: Mathematical Physics
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.mathematical_physics

// Depends on: xiom.math

// ============================================================================
// Mathematical methods for physics: classical mechanics, quantum operators,
// geometry, Lie theory, and functional methods. TODO(compiler): implement.
// ============================================================================

// fn hamiltonian(q: &Vec[Float64], p: &Vec[Float64], h: fn(&Vec[Float64], &Vec[Float64]) -> Float64) -> Float64 - Hamiltonian evaluated at state (q, p).
// fn lagrangian(q: &Vec[Float64], qdot: &Vec[Float64], l: fn(&Vec[Float64], &Vec[Float64]) -> Float64) -> Float64 - Lagrangian evaluated at (q, qdot).
// fn quantum_operators(observable: &Vec[Vec[Float64]], state: &Vec[Float64]) -> Vec[Float64] - apply an observable operator to a state vector.
// fn pauli_matrices(index: Int) -> Vec[Vec[Float64]] - the index-th Pauli matrix (0..3).
// fn gamma_matrices(dim: Int) -> Vec[Vec[Float64]] - gamma matrices of the given spacetime dimension.
// fn tensor_calculus(tensor: &Vec[Float64], metric: &Vec[Vec[Float64]]) -> Vec[Float64] - raise or lower tensor indices with the metric.
// fn differential_geometry(chart: fn(&Vec[Float64]) -> Vec[Float64], point: &Vec[Float64]) -> Vec[Float64] - coordinate derivatives of a chart at point.
// fn riemannian(g: &Vec[Vec[Float64]], point: &Vec[Float64]) -> Vec[Float64] - Ricci scalar or curvature invariant at point.
// fn symplectic(w: &Vec[Vec[Float64]], x: &Vec[Float64], y: &Vec[Float64]) -> Float64 - symplectic form applied to two vectors.
// fn lie_algebra(basis: &Vec[Vec[Vec[Float64]]], a: Int, b: Int) -> Vec[Vec[Float64]] - structure-constant combination of two basis elements.
// fn lie_group(algebra: &Vec[Vec[Vec[Float64]]], params: &Vec[Float64]) -> Vec[Vec[Float64]] - group element from exponential of the algebra.
// fn representation(group: &Vec[Vec[Float64]], algebra: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - linear representation of a group element.
// fn greens_function(operator: fn(&Vec[Float64]) -> Vec[Float64], source: &Vec[Float64]) -> Vec[Float64] - inverse operator applied to a source.
// fn propagator(hamiltonian: &Vec[Vec[Float64]], t: Float64) -> Vec[Vec[Float64]] - time-evolution operator exp(-i*H*t).
// fn path_integral(action: fn(&Vec[Float64]) -> Float64, paths: &Vec[Vec[Float64]]) -> Vec[Float64] - amplitudes of a discretized path integral.
