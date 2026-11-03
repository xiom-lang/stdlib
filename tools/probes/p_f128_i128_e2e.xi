// p_f128_i128_e2e.xi -- permanent e2e for REL-20261031-1600.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Float -> Int128/UInt128 casts used to fall through `coerce_value` and
// `store i128 %double`, so clang rejected the IR (invalid IR on v0.65.4).
// The v0.65.5 pin carries the `__fixdfti`/`__fixunsdfti`/`__fixsfti`/
// `__fixunssfti` helpers. This probe locks both the direct (Float64) and
// Float128-typed paths, signed positive/negative, plus UInt128 and Float32.
//
// Expected: compile rc 0, run rc 0.

module p_f128_i128_e2e

fn f64_to_i128(n: Float64) -> Int128 {
  return n as Int128;
}

fn f128_to_i128(n: Float64) -> Int128 {
  var a: Float128 = n as Float128;
  return a as Int128;
}

fn f32_to_i128(n: Float32) -> Int128 {
  return n as Int128;
}

fn f64_to_u128(n: Float64) -> UInt128 {
  return n as UInt128;
}

fn f128_to_u128(n: Float64) -> UInt128 {
  var a: Float128 = n as Float128;
  return a as UInt128;
}

fn f32_to_u128(n: Float32) -> UInt128 {
  return n as UInt128;
}

fn main() -> Int {
  // Float64 -> Int128, both signs.
  if f64_to_i128(10.0) != 10 { return 1; }
  if f64_to_i128(-10.0) != -10 { return 2; }

  // Float128 -> Int128, both signs.
  if f128_to_i128(10.0) != 10 { return 3; }
  if f128_to_i128(-10.0) != -10 { return 4; }

  // Float32 -> Int128, both signs.
  let f: Float32 = 7.0 as Float32;
  if f32_to_i128(f) != 7 { return 5; }
  let nf: Float32 = (0.0 as Float32) - f;
  if f32_to_i128(nf) != -7 { return 6; }

  // Unsigned destinations.
  if f64_to_u128(10.0) != (10 as UInt128) { return 7; }
  if f128_to_u128(10.0) != (10 as UInt128) { return 8; }
  let g: Float32 = 9.0 as Float32;
  if f32_to_u128(g) != (9 as UInt128) { return 9; }

  return 0;
}
