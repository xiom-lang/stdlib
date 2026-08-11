// XIOM - Math: Decompose
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.decompose

// Depends on: xiom.math

// ============================================================================
// IEEE-754 bit decomposition and float classification. NOTE: current
// implementation lives in math/primitives.xi + num.xi - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn frexp(x: Float64) -> (Float64, Int) - tuple (fraction, exponent) with x = fraction * 2^exponent. TODO(compiler): implement.
// fn ldexp(x: Float64, n: Int) -> Float64 - x * 2^n. TODO(compiler): implement.
// fn ilogb(x: Float64) -> Int - binary exponent of x as an integer. TODO(compiler): implement.
// fn logb(x: Float64) -> Float64 - binary exponent of x as a float. TODO(compiler): implement.
// fn scalbn(x: Float64, n: Int) -> Float64 - x * FLT_RADIX^n. TODO(compiler): implement.
// fn scalbln(x: Float64, n: Int64) -> Float64 - x * FLT_RADIX^n with long exponent. TODO(compiler): implement.
// fn significand(x: Float64) -> Float64 - normalized fraction of x in [0.5, 1). TODO(compiler): implement.
// fn exponent(x: Float64) -> Int - binary exponent of x. TODO(compiler): implement.
// fn frexp_pure(x: Float64) -> (Float64, Int) - frexp without libm. TODO(compiler): implement.
// fn ldexp_pure(x: Float64, n: Int) -> Float64 - ldexp without libm. TODO(compiler): implement.
// fn is_normal(x: Float64) -> Bool - true iff x is a normal (non-subnormal) number. TODO(compiler): implement.
// fn is_subnormal(x: Float64) -> Bool - true iff x is a subnormal number. TODO(compiler): implement.
// fn classify(x: Float64) -> FloatClass - NaN, Infinity, Normal, Subnormal, Zero. TODO(compiler): implement.
// fn nextafter(x: Float64, y: Float64) -> Float64 - next representable Float64 from x toward y. TODO(compiler): implement.
// fn nexttoward(x: Float64, y: Float64) -> Float64 - next representable Float64 from x toward y (long double variant). TODO(compiler): implement.
