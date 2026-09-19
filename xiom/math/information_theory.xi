// XIOM - Math: Information Theory
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.information_theory

// Depends on: xiom.math

// ============================================================================
// Shannon information theory: entropy, divergence measures, coding, and
// channel capacity. All entropies are measured in bits (log base 2) unless
// stated otherwise. Inputs are assumed to be valid probability vectors/
// matrices; invalid entries (negative probabilities) yield NaN (0.0/0.0).
// Complexity is documented per function.
// ============================================================================

use xiom.math;
use xiom.string;

const _LN2: Float64 = 0.6931471805599453;

// -p log2(p), with the limit 0 for p == 0.
fn _bit_term(p: Float64) -> Float64 {
  if p <= 0.0 { return 0.0; }
  return -p * math.log2(p);
}

// p log2(p/q), with the limit 0 when p == 0; NaN when q == 0 and p > 0.
fn _kl_term(p: Float64, q: Float64) -> Float64 {
  if p <= 0.0 { return 0.0; }
  if q <= 0.0 { return 0.0 / 0.0; }
  return p * math.log2(p / q);
}

/// Shannon entropy H(p) = -sum p_i log2 p_i (bits). NaN for a negative
/// probability. Complexity: O(n).
pub fn entropy(probs: &Vec[Float64]) -> Float64 {
  var sum = 0.0;
  var i = 0;
  while i < probs.len() {
    var p = probs[i];
    if p < 0.0 { return 0.0 / 0.0; }
    sum = sum + _bit_term(p);
    i = i + 1;
  }
  return sum;
}

/// Entropy of a joint distribution over pairs: H(X, Y) = -sum p_ij log2 p_ij.
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the joint
/// distribution is a Vec[Vec[Float64]] whose element reads return garbage
/// (BUG 23 #1 residual; verified by minimal probe). Keep the frozen signature;
/// revisit when nested float Vec reads land.
pub fn joint_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0;
}

/// Conditional entropy H(X|Y) = -sum_ij p_ij log2(p_ij / p_j) (bits).
/// TODO(compiler): NOT IMPLEMENTABLE - see joint_entropy (matrix element reads
/// return garbage in this compiler build).
pub fn conditional_entropy(p_joint: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0;
}

/// Mutual information I(X; Y) = sum_ij p_ij log2(p_ij / (p_i p_j)) (bits).
/// TODO(compiler): NOT IMPLEMENTABLE - see joint_entropy (matrix element reads
/// return garbage in this compiler build).
pub fn mutual_information(p_joint: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0;
}

/// Kullback-Leibler divergence D(p || q) = sum p_i log2(p_i / q_i) (bits).
/// NaN for a zero q_i with positive p_i. Complexity: O(n).
pub fn kl_divergence(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 {
  if p.len() != q.len() { return 0.0 / 0.0; }
  var sum = 0.0;
  var i = 0;
  while i < p.len() {
    sum = sum + _kl_term(p[i], q[i]);
    i = i + 1;
  }
  return sum;
}

/// Jensen-Shannon divergence JSD(p || q) = 0.5 D(p || m) + 0.5 D(q || m) with
/// m = (p + q)/2 (bits; values in [0, 1]). NaN on length mismatch. Complexity: O(n).
pub fn js_divergence(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 {
  if p.len() != q.len() { return 0.0 / 0.0; }
  var m = Vec[Float64].new();
  var i = 0;
  while i < p.len() {
    m.push(0.5 * (p[i] + q[i]));
    i = i + 1;
  }
  var sum = 0.0;
  var j = 0;
  while j < p.len() {
    sum = sum + 0.5 * _kl_term(p[j], m[j]) + 0.5 * _kl_term(q[j], m[j]);
    j = j + 1;
  }
  return sum;
}

/// Cross entropy H(p, q) = -sum p_i log2 q_i (bits). NaN for a zero q_i with
/// positive p_i. Complexity: O(n).
pub fn cross_entropy(p: &Vec[Float64], q: &Vec[Float64]) -> Float64 {
  if p.len() != q.len() { return 0.0 / 0.0; }
  var sum = 0.0;
  var i = 0;
  while i < p.len() {
    var pi = p[i];
    if pi < 0.0 { return 0.0 / 0.0; }
    if pi > 0.0 {
      if q[i] <= 0.0 { return 0.0 / 0.0; }
      sum = sum - pi * math.log2(q[i]);
    }
    i = i + 1;
  }
  return sum;
}

/// Perplexity = 2^H (exponential of the entropy in bits). NaN for negative
/// probabilities. Complexity: O(n).
pub fn perplexity(probs: &Vec[Float64]) -> Float64 {
  var h = entropy(probs);
  if h != h { return h; }
  return math.pow(2.0, h);
}

/// Self information -log2(p) of a single event (bits). p <= 0 returns +inf.
/// Complexity: O(1).
pub fn self_information(p: Float64) -> Float64 {
  if p <= 0.0 { return 1.0 / 0.0; }
  return -math.log2(p);
}

/// Entropy rate of a stationary Markov source: sum_j s_j H(row j of the
/// transition matrix).
/// TODO(compiler): NOT IMPLEMENTABLE - the transition matrix is a
/// Vec[Vec[Float64]] whose element reads return garbage in this compiler build.
pub fn entropy_rate(p_transition: &Vec[Vec[Float64]], stationary: &Vec[Float64]) -> Float64 {
  return 0.0;
}

/// Channel capacity by the Blahut-Arimoto algorithm.
/// TODO(compiler): NOT IMPLEMENTABLE - the channel matrix is a
/// Vec[Vec[Float64]] whose element reads return garbage in this compiler build
/// (verified by minimal probe); the resulting q values become NaN and violate
/// math.ln's positivity requirement. Keep the frozen signature; revisit when
/// nested float Vec reads land.
pub fn channel_capacity(p_transition: &Vec[Vec[Float64]]) -> Float64 {
  return 0.0;
}

/// Lower bound on the average code length for a distribution: its entropy
/// (bits). NaN for negative probabilities. Complexity: O(n).
pub fn data_compression_bound(dist: &Vec[Float64]) -> Float64 {
  return entropy(dist);
}

/// Prefix-free Huffman code for a probability distribution. The result holds
/// (symbol index, codeword) pairs with codewords of "0"/"1"; NaN inputs or an
/// empty distribution yield an empty result. Complexity: O(n^2).
pub fn huffman_coding(probs: &Vec[Float64]) -> Vec[(Int, Str)] {
  var out = Vec[(Int, Str)].new();
  var n = probs.len();
  if n == 0 { return out; }
  var i = 0;
  while i < n {
    if probs[i] != probs[i] || probs[i] < 0.0 { return out; }
    i = i + 1;
  }
  var weights = Vec[Float64].new();
  var parent = Vec[Int].new();
  var bit = Vec[Int].new();
  var k = 0;
  while k < n {
    weights.push(probs[k]);
    parent.push(-1);
    bit.push(0);
    k = k + 1;
  }
  var nodes = n;
  var step = 1;
  while step < n {
    var i1 = -1;
    var i2 = -1;
    var w1 = 2.0;
    var w2 = 2.0;
    var idx = 0;
    while idx < nodes {
      if parent[idx] == -1 {
        if weights[idx] < w1 {
          w2 = w1;
          i2 = i1;
          w1 = weights[idx];
          i1 = idx;
        } elif weights[idx] < w2 {
          w2 = weights[idx];
          i2 = idx;
        }
      }
      idx = idx + 1;
    }
    if i1 < 0 || i2 < 0 { step = n; }
    else {
      weights.push(w1 + w2);
      parent.push(-1);
      bit.push(0);
      parent[i1] = nodes;
      parent[i2] = nodes;
      bit[i1] = 0;
      bit[i2] = 1;
      nodes = nodes + 1;
    }
    step = step + 1;
  }
  var s = 0;
  while s < n {
    var code = "";
    var node = s;
    while parent[node] != -1 {
      var cb = bit[node];
      var ch = "";
      if cb == 0 { ch = "0"; } else { ch = "1"; }
      code = ch + code;
      node = parent[node];
    }
    out.push((s, code));
    s = s + 1;
  }
  return out;
}

/// Arithmetic coding of the symbol sequence seq under the distribution probs:
/// returns the midpoint of the final code interval in [0, 1). Invalid symbols
/// (outside the distribution) contribute nothing (documented). Complexity: O(len(seq) * n).
pub fn arithmetic_coding(probs: &Vec[Float64], seq: &Vec[Int]) -> Float64 {
  var n = probs.len();
  var cum = Vec[Float64].new();
  var acc = 0.0;
  var i = 0;
  while i <= n {
    cum.push(acc);
    if i < n {
      acc = acc + probs[i];
    }
    i = i + 1;
  }
  var lo = 0.0;
  var hi = 1.0;
  var k = 0;
  while k < seq.len() {
    var sym = seq[k];
    if sym >= 0 && sym < n {
      var range = hi - lo;
      var clo = cum[sym];
      var chi = cum[sym + 1];
      hi = lo + range * chi;
      lo = lo + range * clo;
    }
    k = k + 1;
  }
  return 0.5 * (lo + hi);
}
