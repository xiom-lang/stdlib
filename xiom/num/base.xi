// XIOM - Num: Base
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.num.base

// Depends on: xiom.string

// ============================================================================
// Radix conversion for integers and floats, plus digit decomposition. TODO(compiler): implement.
// ============================================================================

// fn to_base(n: Int, base: Int) -> Str - integer n as a string in the given base (2-36).
// fn from_base(s: Str, base: Int) -> Result[Int, Str] - parse base-(2-36) string into an Int; Err on invalid input.
// fn to_base_float(f: Float64, base: Int, prec: Int) -> Str - float f as a base-(2-36) string with prec fraction digits.
// fn from_base_float(s: Str, base: Int) -> Result[Float64, Str] - parse base-(2-36) float string; Err on invalid input.
// fn digits_of(n: Int, base: Int) -> Vec[Int] - digits of n in the given base, least significant first.
// fn from_digits(digits: &Vec[Int], base: Int) -> Int - integer reconstructed from digits in the given base.
