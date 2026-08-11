// XIOM - Num: Float
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.float

// Depends on: none

// ============================================================================
// IEEE-754 float inspection: bit patterns, components, classification, and
// next-value operations. TODO(compiler): implement.
// ============================================================================

// fn float_bits(f: Float64) -> Int - raw 64-bit pattern of f.
// fn bits_to_float(bits: Int) -> Float64 - Float64 reconstructed from a raw bit pattern.
// fn float_mantissa(f: Float64) -> Int - significand of f as an integer.
// fn float_exponent(f: Float64) -> Int - unbiased exponent of f.
// fn float_is_subnormal(f: Float64) -> Bool - true iff f is a subnormal value.
// fn float_is_nan(f: Float64) -> Bool - true iff f is NaN.
// fn float_is_infinite(f: Float64) -> Bool - true iff f is infinite.
// fn float_next_up(f: Float64) -> Float64 - smallest Float64 strictly greater than f.
// fn float_next_down(f: Float64) -> Float64 - largest Float64 strictly less than f.
// fn float_ulp(f: Float64) -> Float64 - unit in the last place of f.
// fn float_classify(f: Float64) -> Str - classification string: "nan", "inf", "-inf", "subnormal", "zero", or "normal".
