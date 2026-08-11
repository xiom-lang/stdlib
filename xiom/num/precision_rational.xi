// XIOM - Num: Precision Rational
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.precision_rational

// Depends on: xiom.math

// ============================================================================
// Arbitrary-precision rational numbers (BigRat): construction, arithmetic,
// reduction, and comparison. NOTE: current implementation lives in
// num/fraction.xi stub - move the BigRat functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

// type BigRat - rational number with arbitrary-precision numerator and denominator.
// fn bigrat_new(num: BigInt, den: BigInt) -> Option[BigRat] - construct and reduce; None when den is zero.
// fn bigrat_from_int(v: Int) -> BigRat - construct from a native integer.
// fn bigrat_from_str(s: Str) -> Option[BigRat] - parse "num/den" or decimal string; None on invalid input.
// fn bigrat_to_str(r: BigRat) -> Str - string representation.
// fn bigrat_numerator(r: BigRat) -> BigInt - numerator.
// fn bigrat_denominator(r: BigRat) -> BigInt - denominator.
// fn bigrat_add(a: BigRat, b: BigRat) -> BigRat - sum.
// fn bigrat_sub(a: BigRat, b: BigRat) -> BigRat - difference.
// fn bigrat_mul(a: BigRat, b: BigRat) -> BigRat - product.
// fn bigrat_div(a: BigRat, b: BigRat) -> Option[BigRat] - quotient; None when b is zero.
// fn bigrat_neg(a: BigRat) -> BigRat - negation.
// fn bigrat_abs(a: BigRat) -> BigRat - absolute value.
// fn bigrat_recip(a: BigRat) -> Option[BigRat] - reciprocal; None when a is zero.
// fn bigrat_reduce(r: BigRat) -> BigRat - reduce to lowest terms with positive denominator.
// fn bigrat_is_reduced(r: BigRat) -> Bool - whether r is in lowest terms.
// fn bigrat_is_integer(r: BigRat) -> Bool - whether the denominator divides the numerator.
// fn bigrat_is_zero(r: BigRat) -> Bool - whether r equals zero.
// fn bigrat_compare(a: BigRat, b: BigRat) -> Int - -1, 0, or 1 ordering a vs b.
// fn bigrat_eq(a: BigRat, b: BigRat) -> Bool - whether a equals b.
// fn bigrat_to_float(r: BigRat) -> Float64 - numerator / denominator as Float64.
// fn bigrat_to_integer(r: BigRat) -> Option[BigInt] - integer value; None when not integral.
