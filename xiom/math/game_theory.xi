// XIOM - Math: Game Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.game_theory

// Depends on: xiom.math

// ============================================================================
// Strategic decision theory: solution concepts, cooperative games, auctions,
// and evolutionary dynamics. TODO(compiler): implement.
// ============================================================================

// NormalFormGame - game given by a payoff matrix per player over strategy profiles.
// ExtensiveFormGame - game given as a decision tree with chance and information sets.
// fn nash_equilibrium(payoffs: &Vec[Vec[Float64]]) -> Vec[(Float64, Float64)] - mixed Nash equilibria of a two-player bimatrix game.
// fn minimax(payoffs: &Vec[Vec[Float64]]) -> Float64 - minimax value of a zero-sum game.
// fn alpha_beta(game: fn(&Vec[Int]) -> Float64, depth: Int, alpha: Float64, beta: Float64) -> Float64 - minimax search with alpha-beta pruning.
// fn dominant_strategy(payoffs: &Vec[Vec[Float64]]) -> Option[Int] - index of a strictly dominant strategy, if any.
// fn pareto_optimal(payoffs: &Vec[Vec[Float64]]) -> Vec[Int] - indices of Pareto-optimal strategy profiles.
// fn cooperative_game(v: fn(&Vec[Int]) -> Float64, n: Int) -> (Float64, Float64) - grand-coalition value and a feasible imputation.
// fn shapley_value(v: fn(&Vec[Int]) -> Float64, n: Int) -> Vec[Float64] - Shapley value of each of the n players.
// fn game_core(v: fn(&Vec[Int]) -> Float64, n: Int) -> Vec[Vec[Float64]] - imputations in the core of a cooperative game.
// fn auction(bids: &Vec[Float64], reserve: Float64) -> (Float64, Int) - winning price and winner index of a first-price auction.
// fn mechanism_design(type_space: &Vec[Float64], values: fn(Int) -> Float64) -> Vec[Float64] - dominant-strategy incentive-compatible allocation.
// fn evolutionary_game(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64]) -> Vec[Float64] - next-generation population shares.
// fn replicator_dynamics(payoffs: &Vec[Vec[Float64]], population: &Vec[Float64], steps: Int) -> Vec[Vec[Float64]] - iterated replicator dynamics over steps.
// fn prisoner_dilemma(defect: Float64, cooperate: Float64) -> (Float64, Float64) - payoffs of the one-shot prisoner's dilemma.
