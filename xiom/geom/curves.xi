// XIOM - Geom: Curves
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: geom.xi - this sublib splits the parametric-curve domain.

module xiom.geom.curves

// Depends on: xiom.geom

// ============================================================================
// Parametric curves split from geom.xi: Bezier, Catmull-Rom, B-spline, Hermite,
// and arc-length queries. TODO(compiler): implement.
// ============================================================================

// fn bezier_quad(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], t: Float64) -> Vec[Float64] - point on a quadratic Bezier at parameter t.
// fn bezier_cubic(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], t: Float64) -> Vec[Float64] - point on a cubic Bezier at parameter t.
// fn bezier_derivative(points: &Vec[Vec[Float64]], t: Float64) -> Vec[Float64] - tangent vector of a Bezier curve at t.
// fn catmull_rom(p0: &Vec[Float64], p1: &Vec[Float64], p2: &Vec[Float64], p3: &Vec[Float64], t: Float64) -> Vec[Float64] - Catmull-Rom spline point over [p1, p2].
// fn b_spline(points: &Vec[Vec[Float64]], t: Float64) -> Vec[Float64] - uniform cubic B-spline point at t.
// fn hermite_curve(p0: &Vec[Float64], t0: &Vec[Float64], p1: &Vec[Float64], t1: &Vec[Float64], t: Float64) -> Vec[Float64] - Hermite interpolation with endpoint tangents.
// fn curve_length(samples: fn(Float64) -> Vec[Float64], a: Float64, b: Float64, n: Int) -> Float64 - arc length of a sampled curve over [a, b].
