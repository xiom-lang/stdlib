// XIOM - Num: Precision Float
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.precision_float

// Depends on: none

// ============================================================================
// Arbitrary-precision floating-point operations as thin wrappers over the
// BigFloat implementation. NOTE: current implementation lives in
// num/bigfloat.xi REAL - move the thin wrappers here during the implementation
// phase. TODO(compiler): implement.
// ============================================================================

// fn bigfloat_from_float(x: Float64) -> BigFloat - construct from a native float.
// fn bigfloat_from_str(s: Str) -> Option[BigFloat] - parse decimal string; None on invalid input.
// fn bigfloat_to_str(b: BigFloat) -> Str - decimal string representation at current precision.
// fn bigfloat_with_precision(b: BigFloat, p: Int) -> BigFloat - re-round b to p significant digits.
// fn bigfloat_add(a: BigFloat, b: BigFloat) -> BigFloat - sum.
// fn bigfloat_sub(a: BigFloat, b: BigFloat) -> BigFloat - difference.
// fn bigfloat_mul(a: BigFloat, b: BigFloat) -> BigFloat - product.
// fn bigfloat_div(a: BigFloat, b: BigFloat) -> Option[BigFloat] - quotient; None when b is zero.
// fn bigfloat_neg(a: BigFloat) -> BigFloat - negation.
// fn bigfloat_abs(a: BigFloat) -> BigFloat - absolute value.
// fn bigfloat_sqrt(a: BigFloat) -> Option[BigFloat] - square root; None when a is negative.
// fn bigfloat_cbrt(a: BigFloat) -> BigFloat - cube root.
// fn bigfloat_exp(a: BigFloat) -> BigFloat - exponential function.
// fn bigfloat_ln(a: BigFloat) -> Option[BigFloat] - natural logarithm; None when a is not positive.
// fn bigfloat_log10(a: BigFloat) -> Option[BigFloat] - base-10 logarithm; None when a is not positive.
// fn bigfloat_log2(a: BigFloat) -> Option[BigFloat] - base-2 logarithm; None when a is not positive.
// fn bigfloat_pow(base: BigFloat, exp: BigFloat) -> BigFloat - exponentiation.
// fn bigfloat_sin(a: BigFloat) -> BigFloat - sine.
// fn bigfloat_cos(a: BigFloat) -> BigFloat - cosine.
// fn bigfloat_tan(a: BigFloat) -> BigFloat - tangent.
// fn bigfloat_asin(a: BigFloat) -> Option[BigFloat] - arcsine; None outside [-1, 1].
// fn bigfloat_acos(a: BigFloat) -> Option[BigFloat] - arccosine; None outside [-1, 1].
// fn bigfloat_atan(a: BigFloat) -> BigFloat - arctangent.
// fn bigfloat_atan2(y: BigFloat, x: BigFloat) -> BigFloat - four-quadrant arctangent.
// fn bigfloat_sinh(a: BigFloat) -> BigFloat - hyperbolic sine.
// fn bigfloat_cosh(a: BigFloat) -> BigFloat - hyperbolic cosine.
// fn bigfloat_tanh(a: BigFloat) -> BigFloat - hyperbolic tangent.
// fn bigfloat_pi(p: Int) -> BigFloat - pi to p significant digits.
// fn bigfloat_e(p: Int) -> BigFloat - Euler's number e to p significant digits.
// fn bigfloat_compare(a: BigFloat, b: BigFloat) -> Int - -1, 0, or 1 ordering a vs b.
