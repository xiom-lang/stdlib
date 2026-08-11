// XIOM - Math: Series
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.series

// Depends on: xiom.math

// ============================================================================
// Sequences and series: sums, power series, continued fractions, recurrence
// relations, convergence analysis. TODO(compiler): implement.
// ============================================================================

// fn series_sum(terms: fn(Int) -> Float64, n: Int) -> Float64 - sum of terms(0) .. terms(n-1).
// fn power_series(coefficients: &Vec[Float64], x: Float64) -> Float64 - sum c[i] * x^i.
// fn geometric_series(a: Float64, r: Float64, n: Int) -> Float64 - sum of the first n terms a, a*r, a*r^2, ...
// fn arithmetic_series(a: Float64, d: Float64, n: Int) -> Float64 - sum of the first n terms a, a+d, a+2d, ...
// fn harmonic(n: Int) -> Float64 - n-th harmonic number, sum of 1/k for k = 1..n.
// fn maclaurin_series(f: fn(Float64) -> Float64, order: Int, x: Float64) -> Float64 - Maclaurin approximation of f to the given order.
// fn continued_fraction(coeffs: &Vec[Float64]) -> Float64 - value of a continued fraction built from coeffs.
// fn fib(n: Int) -> Int - n-th Fibonacci number F(n), 0-indexed; 0 for n < 0.
// fn fib_fast(n: Int) -> Int - n-th Fibonacci number via fast doubling.
// fn convergence_rate(seq: &Vec[Float64]) -> Float64 - estimated order of convergence of a sequence.
