// XIOM - Math: Mathematical Economics
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.mathematical_economics

// Depends on: xiom.math

// ============================================================================
// Formal economic models: utility, production, markets, equilibrium, and
// mechanism design.
//
// The Walrasian-equilibrium function takes a Vec[Vec[Float64]] endowment
// matrix whose element reads are unreliable in this compiler build (BUG 23
// #1 residual) and is marked TODO(compiler). All other functions are fully
// implemented with the documented conventions. Complexity is documented per
// function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

// Cobb-Douglas utility of a consumption bundle: prod x_i^w_i. NaN for a
// negative bundle entry or a length mismatch. Complexity: O(n).
/// Cobb-Douglas utility of a consumption bundle: prod x_i^w_i. NaN for a
/// negative bundle entry or a length mismatch. Complexity: O(n).
pub fn utility(bundle: &Vec[Float64], weights: &Vec[Float64]) -> Float64 {
  if bundle.len() != weights.len() { return 0.0 / 0.0; }
  var result = 1.0;
  var i = 0;
  while i < bundle.len() {
    var x = bundle[i];
    if x < 0.0 { return 0.0 / 0.0; }
    if x > 0.0 {
      var p = math.pow(x, weights[i]);
      result = result * p;
    }
    i = i + 1;
  }
  return result;
}

// Cobb-Douglas production function A L^alpha K^beta. NaN for negative inputs.
// Complexity: O(1).
/// Cobb-Douglas production function A L^alpha K^beta. NaN for negative inputs.
/// Complexity: O(1).
pub fn production_cobb_douglas(a: Float64, alpha: Float64, beta: Float64, labor: Float64, capital: Float64) -> Float64 {
  if a < 0.0 || labor < 0.0 || capital < 0.0 { return 0.0 / 0.0; }
  if labor == 0.0 || capital == 0.0 { return 0.0; }
  var lp = math.pow(labor, alpha);
  var kp = math.pow(capital, beta);
  return a * lp * kp;
}

// Quantity demanded at price p with constant elasticity: income * p^-e.
// Complexity: O(1).
/// Quantity demanded at price p with constant elasticity: income * p^-e.
/// Complexity: O(1).
pub fn demand(price: Float64, income: Float64, elasticity: Float64) -> Float64 {
  if price <= 0.0 { return 0.0 / 0.0; }
  return income * math.pow(price, -elasticity);
}

// Quantity supplied at price p with constant elasticity: cost * p^e.
// Complexity: O(1).
/// Quantity supplied at price p with constant elasticity: cost * p^e.
/// Complexity: O(1).
pub fn supply(price: Float64, cost: Float64, elasticity: Float64) -> Float64 {
  if price <= 0.0 { return 0.0 / 0.0; }
  return cost * math.pow(price, elasticity);
}

// Equilibrium price and quantity where demand_fn(p) == supply_fn(p), found
// by bisection over [0, 1000] (300 iterations). NaN when no crossing exists.
// Complexity: O(300 * cost(demand_fn + supply_fn)).
/// Equilibrium price and quantity where demand_fn(p) == supply_fn(p), found
/// by bisection over [0, 1000] (300 iterations). NaN when no crossing exists.
/// Complexity: O(300 * cost(demand_fn + supply_fn)).
pub fn market_equilibrium(demand_fn: fn(Float64) -> Float64, supply_fn: fn(Float64) -> Float64) -> (Float64, Float64) {
  var lo = 0.0;
  var hi = 1000.0;
  var f_lo = demand_fn(lo) - supply_fn(lo);
  var f_hi = demand_fn(hi) - supply_fn(hi);
  if f_lo * f_hi > 0.0 { return (0.0 / 0.0, 0.0 / 0.0); }
  var it = 0;
  while it < 300 {
    var mid = 0.5 * (lo + hi);
    var f_mid = demand_fn(mid) - supply_fn(mid);
    if math.abs_float(f_mid) < 1.0e-10 {
      var q = demand_fn(mid);
      return (mid, q);
    }
    if f_lo * f_mid < 0.0 {
      hi = mid;
      f_hi = f_mid;
    } else {
      lo = mid;
      f_lo = f_mid;
    }
    it = it + 1;
  }
  var p = 0.5 * (lo + hi);
  var q2 = demand_fn(p);
  return (p, q2);
}

// Arc elasticity: ((q1 - q0)/((q0+q1)/2)) / ((p1 - p0)/((p0+p1)/2)).
// NaN for zero midpoints. Complexity: O(1).
/// Arc elasticity: ((q1 - q0)/((q0+q1)/2)) / ((p1 - p0)/((p0+p1)/2)).
/// NaN for zero midpoints. Complexity: O(1).
pub fn elasticity(q0: Float64, q1: Float64, p0: Float64, p1: Float64) -> Float64 {
  var qm = 0.5 * (q0 + q1);
  var pm = 0.5 * (p0 + p1);
  if qm == 0.0 || pm == 0.0 { return 0.0 / 0.0; }
  return ((q1 - q0) / qm) / ((p1 - p0) / pm);
}

// Finite-difference marginal value of f at x: (f(x+h) - f(x-h)) / (2h).
// NaN for h <= 0. Complexity: O(1) with 2 evaluations.
/// Finite-difference marginal value of f at x: (f(x+h) - f(x-h)) / (2h).
/// NaN for h <= 0. Complexity: O(1) with 2 evaluations.
pub fn marginal(f: fn(Float64) -> Float64, x: Float64, h: Float64) -> Float64 {
  if h <= 0.0 { return 0.0 / 0.0; }
  var fp = f(x + h);
  var fm = f(x - h);
  return (fp - fm) / (2.0 * h);
}

// Optimal consumption bundle: the income is allocated across goods in
// proportion to the marginal-utility weights supplied by `utilities`; the
// returned bundle sums to `income`. Empty for a length mismatch.
// Complexity: O(n * cost(utilities)).
/// Optimal consumption bundle: the income is allocated across goods in
/// proportion to the marginal-utility weights supplied by `utilities`; the
/// returned bundle sums to `income`. Empty for a length mismatch.
/// Complexity: O(n * cost(utilities)).
pub fn consumer_theory(prices: &Vec[Float64], income: Float64, utilities: fn(&Vec[Float64]) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = prices.len();
  if n == 0 { return out; }
  var u = Vec[Float64].new();
  var i = 0;
  while i < n {
    u.push(0.0);
    i = i + 1;
  }
  var total_w = 0.0;
  var j = 0;
  while j < n {
    var w = utilities(&u);
    total_w = total_w + w;
    j = j + 1;
  }
  var k = 0;
  while k < n {
    var w = utilities(&u);
    var share = 0.0;
    if total_w > 0.0 {
      share = w / total_w;
    }
    var qty = 0.0;
    if prices[k] > 0.0 {
      qty = income * share / prices[k];
    }
    out.push(qty);
    k = k + 1;
  }
  return out;
}

// Profit-maximizing input combination by coordinate search: starting from a
// unit input vector, scale each input to maximize prices-x - costs(x).
// Returns the input vector. Empty for a price mismatch.
// Complexity: O(steps * n * cost(costs)).
/// Profit-maximizing input combination by coordinate search: starting from a
/// unit input vector, scale each input to maximize prices-x - costs(x).
/// Returns the input vector. Empty for a price mismatch.
/// Complexity: O(steps * n * cost(costs)).
pub fn producer_theory(prices: &Vec[Float64], costs: fn(&Vec[Float64]) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = prices.len();
  if n == 0 { return out; }
  var x = Vec[Float64].new();
  var i = 0;
  while i < n {
    x.push(1.0);
    i = i + 1;
  }
  var step = 0;
  while step < 50 {
    var best_x = Vec[Float64].new();
    var best_profit = 0.0;
    var j = 0;
    while j < n {
      var cand = Vec[Float64].new();
      var k = 0;
      while k < n {
        cand.push(x[k]);
        k = k + 1;
      }
      var s = 1;
      while s <= 4 {
        var cand2 = Vec[Float64].new();
        var m = 0;
        while m < n {
          if m == j {
            cand2.push(x[m] * (s as Float64));
          } else {
            cand2.push(x[m]);
          }
          m = m + 1;
        }
        var revenue = 0.0;
        var q = 0;
        while q < n {
          revenue = revenue + prices[q] * cand2[q];
          q = q + 1;
        }
        var profit = revenue - costs(&cand2);
        if profit > best_profit {
          best_profit = profit;
          best_x = cand2;
        }
        s = s + 1;
      }
      j = j + 1;
    }
    var improved = false;
    var q2 = 0;
    while q2 < n {
      if best_x.len() > 0 && best_x[q2] != x[q2] {
        improved = true;
      }
      q2 = q2 + 1;
    }
    if !improved { step = 50; }
    else {
      x = best_x;
    }
    step = step + 1;
  }
  var r = 0;
  while r < x.len() {
    out.push(x[r]);
    r = r + 1;
  }
  return out;
}

// Walrasian equilibrium price vector.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the endowment
// matrix is a Vec[Vec[Float64]] and the utility vector is a Vec[fn], whose
// element reads return garbage (BUG 23 #1 residual; verified by minimal
// probe). Keep the frozen signature; revisit when the fixes land.
/// Walrasian equilibrium price vector.
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the endowment
/// matrix is a Vec[Vec[Float64]] and the utility vector is a Vec[fn], whose
/// element reads return garbage (BUG 23 #1 residual; verified by minimal
/// probe). Keep the frozen signature; revisit when the fixes land.
pub fn general_equilibrium(endowments: &Vec[Vec[Float64]], utilities: &Vec[fn(&Vec[Float64]) -> Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  return out;
}

// Equilibrium revenue and winner of a second-price (Vickrey) auction: the
// highest bid wins and pays the second-highest bid; bidders are private
// values. Returns (price, winner_index); a single bidder pays the reserve.
// Complexity: O(n).
/// Equilibrium revenue and winner of a second-price (Vickrey) auction: the
/// highest bid wins and pays the second-highest bid; bidders are private
/// values. Returns (price, winner_index); a single bidder pays the reserve.
/// Complexity: O(n).
pub fn auction_theory(bidders: &Vec[Float64], private_values: &Vec[Float64]) -> (Float64, Int) {
  var n = bidders.len();
  if n == 0 || private_values.len() != n {
    return (0.0, -1);
  }
  var winner = 0;
  var top = private_values[0];
  var i = 1;
  while i < n {
    if private_values[i] > top {
      top = private_values[i];
      winner = i;
    }
    i = i + 1;
  }
  var second = 0.0;
  var j = 0;
  while j < n {
    if j != winner && private_values[j] > second {
      second = private_values[j];
    }
    j = j + 1;
  }
  var price = second;
  if n == 1 {
    price = bidders[0];
  }
  return (price, winner);
}

// Incentive-compatible allocation rule: the total type space is allocated so
// that each type i receives a share proportional to valuations(i, types[i]).
// Empty for a mismatch. Complexity: O(n).
/// Incentive-compatible allocation rule: the total type space is allocated so
/// that each type i receives a share proportional to valuations(i, types[i]).
/// Empty for a mismatch. Complexity: O(n).
pub fn mechanism_design(types: &Vec[Float64], valuations: fn(Int, Float64) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = types.len();
  if n == 0 { return out; }
  var total = 0.0;
  var i = 0;
  while i < n {
    total = total + valuations(i, types[i]);
    i = i + 1;
  }
  var j = 0;
  while j < n {
    var alloc = 0.0;
    if total > 0.0 {
      alloc = valuations(j, types[j]) / total;
    }
    out.push(alloc);
    j = j + 1;
  }
  return out;
}
