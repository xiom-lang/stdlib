// XIOM - Math: Information Theory
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.information_theory

// Depends on: xiom.math

// ============================================================================
// Shannon information theory: entropy, divergence measures, coding, and
// channel capacity. TODO(compiler): implement.
// ============================================================================

// fn entropy(probs: &Vec[Float64]) -> Float64 - Shannon entropy in bits of a discrete distribution.
// fn joint_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 - entropy of a joint distribution over pairs of outcomes.
// fn conditional_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 - entropy of one variable given the other.
// fn mutual_information(p_joint: &Vec[Vec[Float64]]) -> Float64 - information shared between two variables.
// fn kl_divergence(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 - Kullback-Leibler divergence of q from p.
// fn js_divergence(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 - symmetric Jensen-Shannon divergence of p and q.
// fn cross_entropy(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 - cross entropy H(p, q) of p under q.
// fn perplexity(probs: &Vec[Float64]) -> Float64 - exponential of the entropy, exp(H).
// fn self_information(p: Float64) -> Float64 - information content -log2(p) of a single event.
// fn entropy_rate(p_transition: &Vec[Vec[Float64]], stationary: &Vec[Float64]) -> Float64 - entropy per symbol of a Markov source.
// fn channel_capacity(p_transition: &Vec[Vec[Float64]]) -> Float64 - maximum mutual information over input distributions.
// fn data_compression_bound(dist: &Vec[Float64]) -> Float64 - entropy lower bound on the average code length.
// fn huffman_coding(probs: &Vec[Float64]) -> Vec[(Int, Str)] - prefix-free Huffman code mapping symbol index to codeword.
// fn arithmetic_coding(probs: &Vec[Float64], seq: &Vec[Int]) -> Float64 - single arithmetic code number for a symbol sequence.
