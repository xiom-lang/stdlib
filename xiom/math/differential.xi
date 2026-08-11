// XIOM - Math: Differential
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.differential

// Depends on: xiom.math

// ============================================================================
// Numerical differentiation and vector calculus: finite differences, gradients,
// Jacobians. TODO(compiler): implement.
// ============================================================================

// fn derivative(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - first derivative of f at x with step h.
// fn derivative2(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - second derivative of f at x.
// fn derivative3(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - third derivative of f at x.
// fn finite_difference(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 - central finite-difference approximation.
// fn richardson(f: fn(Float64) -> Float64, x: Float64, h: Float64, tol: Float64) -> Float64 - Richardson extrapolated derivative to tolerance tol.
// fn gradient(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64]) -> Vec[Float64] - gradient vector of f at x.
// fn jacobian(fs: &Vec[fn(&Vec[Float64]) -> Float64], x: &Vec[Float64]) -> Vec[Vec[Float64]] - Jacobian matrix of functions fs at x.
// fn partial_derivative(f: fn(&Vec[Float64]) -> Float64, x: &Vec[Float64], i: Int, h: Float64) -> Float64 - partial derivative of f with respect to x[i].
