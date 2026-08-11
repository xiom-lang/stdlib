// XIOM - Math: Primitives
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.primitives

// Depends on: none

// ============================================================================
// Scalar float primitives: comparisons, clamping, interpolation, decomposition.
// TODO(compiler): implement.
// ============================================================================

// fn min(a: Float64, b: Float64) -> Float64 - smaller of a and b.
// fn max(a: Float64, b: Float64) -> Float64 - larger of a and b.
// fn clamp(x: Float64, lo: Float64, hi: Float64) -> Float64 - x clamped into [lo, hi].
// fn abs(x: Float64) -> Float64 - absolute value of x.
// fn signum(x: Float64) -> Int - -1, 0, or 1 matching the sign of x.
// fn lerp(a: Float64, b: Float64, t: Float64) -> Float64 - a + (b - a) * t.
// fn step(edge: Float64, x: Float64) -> Float64 - 0.0 if x < edge else 1.0.
// fn smoothstep(e0: Float64, e1: Float64, x: Float64) -> Float64 - Hermite interpolation between 0 and 1 over [e0, e1].
// fn fract(x: Float64) -> Float64 - fractional part of x with the sign of x.
// fn modf(x: Float64) -> (Int, Float64) - split; tuple is (integral_part, fractional_part).
// fn copysign(x: Float64, y: Float64) -> Float64 - magnitude of x with the sign of y.
// fn nextafter(x: Float64, y: Float64) -> Float64 - next representable Float64 from x toward y.
// fn fma(a: Float64, b: Float64, c: Float64) -> Float64 - fused multiply-add a * b + c with one rounding.
// fn frexp(x: Float64) -> (Float64, Int) - split; tuple is (mantissa, exponent) with x = mantissa * 2^exponent.
// fn ldexp(x: Float64, exp: Int) -> Float64 - x * 2^exp.
// fn hypot(a: Float64, b: Float64) -> Float64 - sqrt(a*a + b*b) without intermediate overflow.
// fn cbrt(x: Float64) -> Float64 - cube root of x.
// fn is_nan(x: Float64) -> Bool - true iff x is NaN.
// fn is_inf(x: Float64) -> Bool - true iff x is positive or negative infinity.
// fn is_finite(x: Float64) -> Bool - true iff x is neither NaN nor infinite.
