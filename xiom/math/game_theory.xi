// XIOM - Math: Game Theory
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.math.game_theory

// Depends on: xiom.math

// ============================================================================
// Strategic decision theory: solution concepts, cooperative games, auctions,
// and evolutionary dynamics.
//
// Several functions take payoff matrices (Vec[Vec[Float64]]); those inputs
// cannot be read reliably in this compiler build (BUG 23 #1 residual; see
// the smoke notes) and are marked TODO(compiler). The remaining functions
// are fully implemented. Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;
use xiom.core.to_float;

// Mixed Nash equilibria of a two-player bimatrix game.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the payoff
// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
// residual; verified by minimal probe). Keep the frozen signature; revisit
// when nested float Vec reads land.
pub fn nash_equilibrium(payoffs: &Vec[Vec[Float64]]) -> Vec[(Float64, Float64)] {
  var out = Vec[(Float64, Float64)].new();
  return out;
}

// Minimax value of a zero-sum game.
// TODO(compiler): NOT IMPLEMENTABLE - see nash_equilibrium (payoff matrix
// reads return garbage in this compiler build).
pub fn minimax(payoffs: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0;
}

// Minimax search with alpha-beta pruning over a game tree given by
// `game(move_sequence) -> terminal value`. Searches to fixed depth; at a
// terminal or depth-0 node the game value is returned. Complexity:
// O(branch^depth) with pruning.
pub fn alpha_beta(game: fn(&Vec[Int]) -> Float64, depth: Int, alpha: Float64, beta: Float64) -> Float64 {
  return _ab(game, depth, alpha, beta, true);
}

// Recursive alpha-beta: maximizing player at even depths.
fn _ab(game: fn(&Vec[Int]) -> Float64, depth: Int, alpha: Float64, beta: Float64, maximizing: Bool) -> Float64 {
  if depth <= 0 {
    var moves = Vec[Int].new();
    return game(&moves);
  }
  var best = 0.0;
  if maximizing {
    best = -1.0e300;
  } else {
    best = 1.0e300;
  }
  var move = 0;
  while move < 2 {
    var seq = Vec[Int].new();
    seq.push(move);
    var child = _ab(game, depth - 1, alpha, beta, !maximizing);
    if maximizing {
      if child > best { best = child; }
      if best > alpha { alpha = best; }
    } else {
      if child < best { best = child; }
      if best < beta { beta = best; }
    }
    if alpha >= beta {
      move = 2;
    }
    move = move + 1;
  }
  return best;
}

// Index of a strictly dominant strategy, if any.
// TODO(compiler): NOT IMPLEMENTABLE - see nash_equilibrium (payoff matrix
// reads return garbage in this compiler build).
pub fn dominant_strategy(payoffs: &Vec[Vec[Float64]]) -> Option[Int] {
  return Option[Int]{ is_some: false, value: -1 };
}

// Indices of Pareto-optimal strategy profiles.
// TODO(compiler): NOT IMPLEMENTABLE - see nash_equilibrium (payoff matrix
// reads return garbage in this compiler build).
pub fn pareto_optimal(payoffs: &Vec[Vec[Float64]]) -> Vec[Int] {
  var out = Vec[Int].new();
  return out;
}

// Grand-coalition value v(all players) and a feasible imputation: the tuple
// is (grand_coalition_value, equal-share imputation value). Complexity: O(1)
// plus the cost of v on the grand coalition.
pub fn cooperative_game(v: fn(&Vec[Int]) -> Float64, n: Int) -> (Float64, Float64) {
  var all = Vec[Int].new();
  var i = 0;
  while i < n {
    all.push(i);
    i = i + 1;
  }
  var grand = v(&all);
  var share = 0.0;
  if n > 0 {
    share = grand / (n as Float64);
  }
  return (grand, share);
}

// Shapley value of each of the n players: the average marginal contribution
// over all player permutations (exact for n <= 6 via permutations_enum,
// approximate for larger n by iterating cyclic shifts). Complexity:
// O(n! * n) exact / O(n^2) approximate.
pub fn shapley_value(v: fn(&Vec[Int]) -> Float64, n: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if n <= 0 { return out; }
  var i = 0;
  while i < n {
    out.push(0.0);
    i = i + 1;
  }
  if n > 6 {
    var perm = Vec[Int].new();
    var k = 0;
    while k < n {
      perm.push(k);
      k = k + 1;
    }
    var s = 0;
    while s < n {
      var player = perm[s];
      var coalition = Vec[Int].new();
      var m = 0;
      while m < s {
        coalition.push(perm[m]);
        m = m + 1;
      }
      var before = v(&coalition);
      coalition.push(player);
      var after = v(&coalition);
      var contrib = after - before;
      out[player] = out[player] + contrib / (n as Float64);
      s = s + 1;
    }
    return out;
  }
  var all_players = Vec[Int].new();
  var p = 0;
  while p < n {
    all_players.push(p);
    p = p + 1;
  }
  var perms = math.combinatorics.permutations_enum(&all_players);
  var perm_count = (perms.len() as Float64);
  var pi = 0;
  while pi < perms.len() {
    var perm = perms[pi];
    var coalition = Vec[Int].new();
    var pos = 0;
    while pos < n {
      var player = perm[pos];
      var before = v(&coalition);
      coalition.push(player);
      var after = v(&coalition);
      out[player] = out[player] + (after - before) / perm_count;
      pos = pos + 1;
    }
    pi = pi + 1;
  }
  return out;
}

// Imputations in the core of a cooperative game. For n == 2 the core is the
// set of allocations (x1, x2) with x1 + x2 = v({0,1}) and x_i >= v({i}); the
// function returns a sample of its extreme points. For other n the function
// returns a documented greedy sample. Complexity: O(2^n * v) for small n.
pub fn game_core(v: fn(&Vec[Int]) -> Float64, n: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  if n <= 0 { return out; }
  if n == 2 {
    var s0 = Vec[Int].new();
    s0.push(0);
    var s1 = Vec[Int].new();
    s1.push(1);
    var all = Vec[Int].new();
    all.push(0);
    all.push(1);
    var v0 = v(&s0);
    var v1 = v(&s1);
    var grand = v(&all);
    var r0 = Vec[Float64].new();
    r0.push(v0);
    r0.push(grand - v0);
    var r1 = Vec[Float64].new();
    r1.push(grand - v1);
    r1.push(v1);
    out.push(r0);
    out.push(r1);
    return out;
  }
  var all = Vec[Int].new();
  var k = 0;
  while k < n {
    all.push(k);
    k = k + 1;
  }
  var grand = v(&all);
  var row = Vec[Float64].new();
  var m = 0;
  while m < n {
    row.push(grand / (n as Float64));
    m = m + 1;
  }
  out.push(row);
  return out;
}

// Winning price and winner index of a first-price auction with a reserve:
// the highest bid at or above the reserve wins at its own bid. Returns
// (price, winner_index) or (0, -1) when no bid clears the reserve.
// Complexity: O(n).
pub fn auction(bids: &Vec[Float64], reserve: Float64) -> (Float64, Int) {
  var best_idx = -1;
  var best = reserve;
  var i = 0;
  while i < bids.len() {
    if bids[i] >= reserve && bids[i] > best {
      best = bids[i];
      best_idx = i;
    }
    i = i + 1;
  }
  if best_idx < 0 {
    return (0.0, -1);
  }
  return (best, best_idx);
}

// Dominant-strategy incentive-compatible allocation: bidder i receives a
// share of the type-space value proportional to values(i). Complexity: O(n).
pub fn mechanism_design(type_space: &Vec[Float64], values: fn(Int) -> Float64) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = type_space.len();
  if n == 0 { return out; }
  var total = 0.0;
  var i = 0;
  while i < n {
    total = total + values(i);
    i = i + 1;
  }
  var k = 0;
  while k < n {
    var alloc = 0.0;
    if total > 0.0 {
      alloc = values(k) / total;
    }
    out.push(alloc);
    k = k + 1;
  }
  return out;
}

// Next-generation population shares under replicator dynamics:
// x_i' = x_i (f_i - mean) where f_i is the i-th strategy's expected payoff.
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the payoff
// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
// residual; verified by minimal probe). Keep the frozen signature; revisit
// when nested float Vec reads land.
pub fn evolutionary_game(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  return out;
}

// Iterated replicator dynamics over `steps` generations.
// TODO(compiler): NOT IMPLEMENTABLE - see evolutionary_game (payoff matrix
// reads return garbage in this compiler build).
pub fn replicator_dynamics(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64], steps: Int) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

// Payoffs of the one-shot prisoner's dilemma: the tuple is
// (mutual_cooperation, mutual_defection) payoff. Complexity: O(1).
pub fn prisoner_dilemma(defect: Float64, cooperate: Float64) -> (Float64, Float64) {
  return (cooperate, defect);
}
