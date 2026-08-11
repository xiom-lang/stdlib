// XIOM - Math: Precision
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.precision

// Depends on: none

// ============================================================================
// Generic type-level precision queries over numeric widths. NOTE: current
// implementation lives in num.xi (min_value/max_value/epsilon) - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

// fn min_value[T]() -> T - smallest finite value representable by T. TODO(compiler): implement.
// fn max_value[T]() -> T - largest finite value representable by T. TODO(compiler): implement.
// fn epsilon[T]() -> T - machine epsilon of T; smallest x such that 1 + x != 1. TODO(compiler): implement.
// fn digits[T]() -> Int - number of significant decimal digits (floats) or decimal digits (integers). TODO(compiler): implement.
// fn mantissa_digits[T]() -> Int - number of bits in the significand of T. TODO(compiler): implement.
// fn exponent_bias[T]() -> Int - exponent bias of T (floats). TODO(compiler): implement.
// fn min_exponent[T]() -> Int - minimum binary exponent of T. TODO(compiler): implement.
// fn max_exponent[T]() -> Int - maximum binary exponent of T. TODO(compiler): implement.
// fn is_signed[T]() -> Bool - true iff T can represent negative values. TODO(compiler): implement.
// fn bit_width[T]() -> Int - number of bits in a value of T. TODO(compiler): implement.
// fn byte_width[T]() -> Int - number of bytes in a value of T. TODO(compiler): implement.
