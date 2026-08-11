// XIOM - Num: Fraction
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.fraction

// Depends on: none

// ============================================================================
// Exact rational numbers: construction, arithmetic, reduction, comparison.
// TODO(compiler): implement.
// ============================================================================

// type Fraction - rational number; struct { num: Int; den: Int } with den > 0 and always reduced.
// fn fraction_new(num: Int, den: Int) -> Fraction - construct and reduce a fraction; den must not be zero.
// fn fraction_from_float(f: Float64) -> Fraction - best rational approximation of f.
// fn fraction_add(a: Fraction, b: Fraction) -> Fraction - sum.
// fn fraction_sub(a: Fraction, b: Fraction) -> Fraction - difference.
// fn fraction_mul(a: Fraction, b: Fraction) -> Fraction - product.
// fn fraction_div(a: Fraction, b: Fraction) -> Option[Fraction] - quotient; None when b is zero.
// fn fraction_reduce(f: Fraction) -> Fraction - reduce to lowest terms with positive denominator.
// fn fraction_to_float(f: Fraction) -> Float64 - numerator / denominator as Float64.
// fn fraction_to_str(f: Fraction) -> Str - decimal string representation.
// fn fraction_is_zero(f: Fraction) -> Bool - true iff the numerator is zero.
// fn fraction_compare(a: Fraction, b: Fraction) -> Int - -1, 0, or 1 ordering a vs b.
