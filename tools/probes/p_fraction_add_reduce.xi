// p_fraction_add_reduce.xi -- regression lock for fraction_add's cross-cancel.
// Found during wave 188: fraction_add(1/3, 1/6) returned 0/1 because both
// numerators were divided by gcd(denominators) instead of multiplying by the
// other denominator's cofactor. Expected: 1/2 (reduced).
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_fraction_add_reduce

use xiom.num;

fn same(a: &Fraction, num: Int, den: Int) -> Bool {
  return a.num == num && a.den == den;
}

fn main() -> Int {
  let third = Fraction{ num: 1; den: 3; };
  let sixth = Fraction{ num: 1; den: 6; };
  let half = fraction_add(&third, &sixth);
  if same(&half, 1, 2) == false { return 1; }
  let half2 = fraction_add(&sixth, &third);
  if same(&half2, 1, 2) == false { return 2; }
  let one = fraction_add(&half, &half);
  if same(&one, 1, 1) == false { return 3; }
  let whole = fraction_add(&third, &Fraction{ num: 2; den: 3; });
  if same(&whole, 1, 1) == false { return 4; }
  return 0;
}
