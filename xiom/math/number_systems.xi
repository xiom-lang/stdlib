// XIOM - Math: Number Systems
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.number_systems

// Depends on: xiom.string; home: xiom.num.convert (base58/62/85) and xiom.num.base.

// ============================================================================
// Alternative representations of numbers: radices, numeral systems, and
// extended number algebras. TODO(compiler): implement.
// ============================================================================

// fn binary_to_int(s: Str) -> Result[Int, Str] - parse a binary string to Int; Err on invalid input.
// fn int_to_binary(n: Int) -> Str - decimal Int to binary string.
// fn octal_to_int(s: Str) -> Result[Int, Str] - parse an octal string to Int; Err on invalid input.
// fn int_to_octal(n: Int) -> Str - decimal Int to octal string.
// fn hex_to_int(s: Str) -> Result[Int, Str] - parse a hexadecimal string to Int; Err on invalid input.
// fn int_to_hex(n: Int) -> Str - decimal Int to hexadecimal string.
// fn base_n_to_int(s: Str, base: Int) -> Result[Int, Str] - parse a string in an arbitrary base to Int.
// fn int_to_base_n(n: Int, base: Int) -> Str - decimal Int to a string in an arbitrary base.
// fn roman_to_int(s: Str) -> Result[Int, Str] - parse a Roman numeral to Int; Err on invalid input.
// fn int_to_roman(n: Int) -> Str - Int to a Roman numeral string.
// fn chinese_numerals(n: Int) -> Str - Int to a Chinese numeral string.
// fn japanese_numerals(n: Int) -> Str - Int to a Japanese numeral string.
// fn egyptian_fractions(numer: Int, denom: Int) -> Vec[(Int, Int)] - greedy Egyptian fraction expansion of numer/denom.
// fn babylonian_numerals(n: Int) -> Str - Int to a Babylonian cuneiform numeral string.
// fn greek_numerals(n: Int) -> Str - Int to a Greek numeral string.
// fn continued_fraction(x: Float64, terms: Int) -> Vec[Int] - continued fraction coefficients of x.
// fn fraction_new(numer: Int, denom: Int) -> (Int, Int) - reduced fraction tuple.
// fn fraction_add(a: (Int, Int), b: (Int, Int)) -> (Int, Int) - sum of two reduced fractions.
// fn surd_simplify(a: Int, b: Int) -> (Int, Int) - simplify sqrt(a)/sqrt(b) to a coefficient and radicand.
// fn octonion_add(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - componentwise sum of two octonions.
// fn sedenion_add(a: &Vec[Float64], b: &Vec[Float64]) -> Vec[Float64] - componentwise sum of two sedenions.
