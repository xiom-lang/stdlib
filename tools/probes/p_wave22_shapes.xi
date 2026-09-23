// p_wave22_shapes.xi -- contract shape validation for wave 22 (stats).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 22 applies to xiom.stats and xiom.stats.probability:
// 1. empty-input guard with an Int identity: `data.len() == 0 => result == 0`
// 2. empty-input guard with a float identity: `data.len() == 0 => result == 0.0`
// 3. short-input guard: `data.len() < 2 => result == 0.0`
// 4. non-negative float bound: `result >= 0.0`, and the NaN-tolerant
//    disjunction `result >= 0.0 || result != result`
// 5. length-mismatch guards across two Vec parameters:
//    `b.len() != a.len() => result == 0.0` and the combined
//    `a.len() == b.len() && a.len() < 2 => result == 0.0`
// 6. exact vector length from an Int parameter:
//    `bins > 0 && hi > lo => result.len() == bins`
// 7. probability-domain guarded float interval on the result:
//    `p > 0.0 && p <= 1.0 && k >= 1 => result >= 0.0 && result <= 1.0`
// 8. parameter-identity domain guards on float arguments:
//    `lambda > 0.0 && x == 0.0 => result == 0.0`
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave22_shapes

use xiom.stats;
use xiom.stats.probability;

// Shape 1: empty guard with an Int result.
fn s_q1(data: &Vec[Int]) -> Int
  ensures: data.len() == 0 => result == 0
{
  return stats.stats_q1(data);
}

// Shapes 2+4: empty guard and non-negative bound on a float result.
fn s_variance(data: &Vec[Int]) -> Float64
  ensures: data.len() == 0 => result == 0.0
  ensures: result >= 0.0
{
  return stats.stats_variance(data);
}

fn s_stddev(data: &Vec[Int]) -> Float64
  ensures: result >= 0.0
{
  return stats.stats_stddev_f(data);
}

// Shape 3: short-input guard plus NaN-tolerant non-negative bound.
fn s_sample_variance(data: &Vec[Int]) -> Float64
  ensures: data.len() < 2 => result == 0.0
  ensures: result >= 0.0 || result != result
{
  return stats.stats_sample_variance(data);
}

// Shape 5: length-mismatch guards across two Vec parameters.
fn s_slope(x: &Vec[Int], y: &Vec[Int]) -> Float64
  ensures: x.len() < 2 => result == 0.0
  ensures: y.len() != x.len() => result == 0.0
{
  return stats.stats_slope(x, y);
}

fn s_covariance(a: &Vec[Int], b: &Vec[Int]) -> Float64
  ensures: a.len() == 0 => result == 0.0
  ensures: a.len() == b.len() && a.len() < 2 => result == 0.0
{
  return stats.stats_covariance(a, b);
}

// Shape 6: exact vector length from an Int parameter.
fn s_histogram(data: &Vec[Int], bins: Int, lo: Int, hi: Int) -> Vec[Int]
  ensures: bins <= 0 => result.len() == 0
  ensures: hi <= lo => result.len() == 0
  ensures: bins > 0 && hi > lo => result.len() == bins
{
  return stats.stats_histogram(data, bins, lo, hi);
}

// Shape 7: probability-domain guarded float interval.
fn s_geometric_pmf(k: Int, p: Float64) -> Float64
  ensures: p > 0.0 && p <= 1.0 && k >= 1 => result >= 0.0 && result <= 1.0
{
  return probability.geometric_pmf(k, p);
}

// Shape 8: parameter-identity domain guards.
fn s_uniform_pdf(x: Float64, a: Float64, b: Float64) -> Float64
  ensures: b > a && x < a => result == 0.0
  ensures: b > a && x > b => result == 0.0
{
  return probability.uniform_pdf(x, a, b);
}

fn s_poisson_pmf(k: Int, lambda: Float64) -> Float64
  ensures: lambda == 0.0 && k == 0 => result == 1.0
  ensures: lambda == 0.0 && k > 0 => result == 0.0
{
  return probability.poisson_pmf(k, lambda);
}

fn main() -> Int {
  var v: Vec[Int] = Vec[Int].new();
  v.push(2); v.push(4); v.push(4); v.push(4); v.push(5); v.push(5); v.push(7); v.push(9);
  var empty: Vec[Int] = Vec[Int].new();

  if s_q1(&empty) != 0 { return 1; }
  if s_variance(&empty) != 0.0 { return 2; }
  if s_variance(&v) < 0.0 { return 3; }
  if s_stddev(&v) < 0.0 { return 4; }
  if s_sample_variance(&empty) != 0.0 { return 5; }
  if s_sample_variance(&v) < 0.0 { return 6; }

  var x: Vec[Int] = Vec[Int].new();
  x.push(1); x.push(2); x.push(3);
  var y: Vec[Int] = Vec[Int].new();
  y.push(2); y.push(4); y.push(6);
  var yshort: Vec[Int] = Vec[Int].new();
  yshort.push(2); yshort.push(4);
  if s_slope(&x, &y) < 1.9 { return 7; }
  if s_slope(&x, &yshort) != 0.0 { return 8; }
  if s_covariance(&x, &y) < 0.0 { return 9; }
  if s_covariance(&empty, &empty) != 0.0 { return 10; }

  let h = s_histogram(&v, 4, 0, 10);
  if h.len() != 4 { return 11; }
  if s_histogram(&v, 0, 0, 10).len() != 0 { return 12; }
  if s_histogram(&v, 4, 10, 0).len() != 0 { return 13; }

  let g = s_geometric_pmf(3, 0.5);
  if g < 0.0 || g > 1.0 { return 14; }
  if s_uniform_pdf(-1.0, 0.0, 1.0) != 0.0 { return 15; }
  if s_uniform_pdf(2.0, 0.0, 1.0) != 0.0 { return 16; }
  if s_poisson_pmf(0, 0.0) != 1.0 { return 17; }
  if s_poisson_pmf(2, 0.0) != 0.0 { return 18; }
  return 0;
}
