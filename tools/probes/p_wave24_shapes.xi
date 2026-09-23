// p_wave24_shapes.xi -- contract shape validation for wave 24 (math).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 24 applies to xiom.math.{modular,arithmetic,logic,set_theory}:
// 1. uniform modular range with the no-modulus guard:
//    `result >= 0 && (m <= 1 || result < m)`
// 2. square-root range with the small-prime guard:
//    `p <= 2 || (result >= 0 && result <= (p - 1) / 2)`
// 3. tuple-field non-negativity: `result.0 >= 0 && result.1 >= 0`
// 4. two-parameter Vec length arithmetic:
//    `result.len() <= a.len() + b.len()` and `result.len() == a.len() * b.len()`
// 5. cardinality bounds: `result >= 0 && result <= s.len()`
// 6. exact Boolean mirrors: `result == (a == b)`, `result == (!a || b)`,
//    `result == (n % 2 != 0)`
// 7. guarded power-of-two predicates and results:
//    `result == false || n >= 1`, `result == 0 || result >= n`,
//    `n <= 0 || (result >= 1 && result <= n)`
// 8. sign-matching remainders:
//    `b == 0 || result == 0 || (result < 0) == (b < 0)`
// 9. power-set guard: `s.len() > 20 || result.len() >= 1`
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave24_shapes

use xiom.math.modular;
use xiom.math.arithmetic;
use xiom.math.logic;
use xiom.math.set_theory;

// Shape 1: uniform modular range.
fn s_mod_add(a: Int, b: Int, m: Int) -> Int
  ensures: result >= 0 && (m <= 1 || result < m)
{
  return modular.mod_add(a, b, m);
}

fn s_mod_inverse(a: Int, m: Int) -> Int
  ensures: result >= 0 && (m <= 1 || result < m)
{
  return modular.mod_inverse(a, m);
}

fn s_pow_mod(base: Int, exp: Int, m: Int) -> Int
  ensures: result >= 0 && (m <= 1 || result < m)
{
  return arithmetic.pow_mod(base, exp, m);
}

// Shape 2: square-root range.
fn s_mod_sqrt(a: Int, p: Int) -> Int
  ensures: p <= 2 || (result >= 0 && result <= (p - 1) / 2)
{
  return modular.mod_sqrt(a, p);
}

// Shape 3: tuple-field non-negativity.
fn s_gcd_extended(a: Int, b: Int) -> (Int, Int, Int)
  ensures: result.0 >= 0
{
  return arithmetic.gcd_extended(a, b);
}

fn s_cornacchia(d: Int, b: Int, m: Int) -> (Int, Int)
  ensures: result.0 >= 0 && result.1 >= 0
{
  return modular.cornacchia(d, b, m);
}

// Shape 4: two-parameter Vec length arithmetic.
fn s_set_union(a: &Vec[Int], b: &Vec[Int]) -> Vec[Int]
  ensures: result.len() <= a.len() + b.len()
{
  return set_theory.set_union(a, b);
}

fn s_cartesian(a: &Vec[Int], b: &Vec[Int]) -> Vec[(Int, Int)]
  ensures: result.len() == a.len() * b.len()
{
  return set_theory.set_cartesian_product(a, b);
}

// Shape 5: cardinality bounds.
fn s_cardinality(s: &Vec[Int]) -> Int
  ensures: result >= 0 && result <= s.len()
{
  return set_theory.set_cardinality(s);
}

// Shape 6: exact Boolean mirrors.
fn s_iff(a: Bool, b: Bool) -> Bool
  ensures: result == (a == b)
{
  return logic.iff(a, b);
}

fn s_implies(a: Bool, b: Bool) -> Bool
  ensures: result == (!a || b)
{
  return logic.implies(a, b);
}

fn s_is_odd(n: Int) -> Bool
  ensures: result == (n % 2 != 0)
{
  return arithmetic.is_odd(n);
}

// Shape 7: guarded power-of-two shapes.
fn s_is_power_of_two(n: Int) -> Bool
  ensures: result == false || n >= 1
{
  return arithmetic.is_power_of_two(n);
}

fn s_next_power_of_two(n: Int) -> Int
  ensures: result == 0 || result >= n
{
  return arithmetic.next_power_of_two(n);
}

fn s_prev_power_of_two(n: Int) -> Int
  ensures: n <= 0 || (result >= 1 && result <= n)
{
  return arithmetic.prev_power_of_two(n);
}

// Shape 8: sign-matching remainders.
fn s_mod_floor(a: Int, b: Int) -> Int
  ensures: b == 0 || result == 0 || (result < 0) == (b < 0)
{
  return arithmetic.mod_floor(a, b);
}

fn s_mod_trunc(a: Int, b: Int) -> Int
  ensures: b == 0 || result == 0 || (result < 0) == (a < 0)
{
  return arithmetic.mod_trunc(a, b);
}

// Shape 9: power-set guard.
fn s_power_set(s: &Vec[Int]) -> Vec[Vec[Int]]
  ensures: s.len() > 20 || result.len() >= 1
{
  return set_theory.set_power_set(s);
}

fn main() -> Int {
  if s_mod_add(5, 7, 11) >= 11 { return 1; }
  if s_mod_add(5, 7, 0) != 0 { return 2; }
  if s_mod_inverse(3, 11) >= 11 { return 3; }
  if s_pow_mod(2, 10, 1000) >= 1000 { return 4; }
  if s_mod_sqrt(2, 7) > 3 { return 5; }
  let g = s_gcd_extended(12, 18);
  if g.0 != 6 { return 6; }
  let co = s_cornacchia(1, 2, 5);
  if co.0 < 0 || co.1 < 0 { return 7; }

  var a: Vec[Int] = Vec[Int].new();
  a.push(1); a.push(2);
  var b: Vec[Int] = Vec[Int].new();
  b.push(2); b.push(3);
  let u = s_set_union(&a, &b);
  if u.len() > a.len() + b.len() { return 8; }
  let cp = s_cartesian(&a, &b);
  if cp.len() != a.len() * b.len() { return 9; }
  let c = s_cardinality(&a);
  if c < 0 || c > a.len() { return 10; }

  if s_iff(true, false) { return 11; }
  if !s_implies(false, false) { return 12; }
  if !s_is_odd(-3) { return 13; }
  if s_is_power_of_two(0) { return 14; }
  if s_next_power_of_two(5) < 5 { return 15; }
  if s_prev_power_of_two(5) < 1 || s_prev_power_of_two(5) > 5 { return 16; }
  if s_mod_floor(-7, 2) <= 0 { return 17; }
  if s_mod_trunc(-7, 2) >= 0 { return 18; }
  let ps = s_power_set(&a);
  if ps.len() < 1 { return 19; }
  return 0;
}
