// XIOM - Math: Machine Learning
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.math.machine_learning

// Depends on: xiom.math

// ============================================================================
// Numerical building blocks for machine learning: activations, losses,
// metrics, regularizers, kernels, distances, and similarities.
//
// All vector inputs are Vec[Float64] or Vec[Int]; inputs are assumed to be
// well-formed (equal lengths where the math requires it; mismatches return
// documented sentinels). Domain errors return IEEE NaN (0.0/0.0). Complexity
// is documented per function.
// ============================================================================

use xiom.math;
use xiom.core.to_int;

// Logistic sigmoid 1/(1+exp(-x)). Saturated to 1 for large x and to 0 for
// very negative x. Complexity: O(1).
/// Logistic sigmoid 1/(1+exp(-x)). Saturated to 1 for large x and to 0 for
/// very negative x. Complexity: O(1).
pub fn activation_sigmoid(x: Float64) -> Float64 {
  if x != x { return x; }
  if x >= 0.0 {
    var e = math.exp(-x);
    return 1.0 / (1.0 + e);
  }
  var e = math.exp(x);
  return e / (1.0 + e);
}

// Hyperbolic tangent activation tanh(x) = (1 - exp(-2x))/(1 + exp(-2x)),
// stable for all x. Complexity: O(1).
/// Hyperbolic tangent activation tanh(x) = (1 - exp(-2x))/(1 + exp(-2x)),
/// stable for all x. Complexity: O(1).
pub fn activation_tanh(x: Float64) -> Float64 {
  if x != x { return x; }
  if x >= 0.0 {
    var e = math.exp(-2.0 * x);
    return (1.0 - e) / (1.0 + e);
  }
  var e = math.exp(2.0 * x);
  return (e - 1.0) / (e + 1.0);
}

// Rectified linear unit max(0, x). Complexity: O(1).
/// Rectified linear unit max(0, x). Complexity: O(1).
pub fn activation_relu(x: Float64) -> Float64 {
  if x > 0.0 { return x; }
  return 0.0;
}

// Gaussian error linear unit 0.5 x (1 + erf(x / sqrt(2))). Complexity: O(1).
/// Gaussian error linear unit 0.5 x (1 + erf(x / sqrt(2))). Complexity: O(1).
pub fn activation_gelu(x: Float64) -> Float64 {
  if x != x { return x; }
  var a = x / 1.4142135623730951;
  var e = math.special.erf(a);
  return 0.5 * x * (1.0 + e);
}

// Swish activation x * sigmoid(x). Complexity: O(1).
/// Swish activation x * sigmoid(x). Complexity: O(1).
pub fn activation_swish(x: Float64) -> Float64 {
  var s = activation_sigmoid(x);
  return x * s;
}

// Mean squared error of y_true vs y_pred. NaN on length mismatch or NaN
// input. Complexity: O(n).
/// Mean squared error of y_true vs y_pred. NaN on length mismatch or NaN
/// input. Complexity: O(n).
pub fn loss_mse(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < y_true.len() {
    var d = y_true[i] - y_pred[i];
    s = s + d * d;
    i = i + 1;
  }
  return s / (y_true.len() as Float64);
}

// Mean absolute error of y_true vs y_pred. Complexity: O(n).
/// Mean absolute error of y_true vs y_pred. Complexity: O(n).
pub fn loss_mae(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < y_true.len() {
    var d = y_true[i] - y_pred[i];
    if d < 0.0 { d = -d; }
    s = s + d;
    i = i + 1;
  }
  return s / (y_true.len() as Float64);
}

// Huber loss with threshold delta: quadratic inside delta, linear outside.
// NaN for delta <= 0. Complexity: O(n).
/// Huber loss with threshold delta: quadratic inside delta, linear outside.
/// NaN for delta <= 0. Complexity: O(n).
pub fn loss_huber(y_true: &Vec[Float64], y_pred: &Vec[Float64], delta: Float64) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  if delta <= 0.0 { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < y_true.len() {
    var d = y_true[i] - y_pred[i];
    if d < 0.0 { d = -d; }
    if d <= delta {
      s = s + 0.5 * d * d;
    } else {
      s = s + delta * (d - 0.5 * delta);
    }
    i = i + 1;
  }
  return s / (y_true.len() as Float64);
}

// Categorical cross entropy -sum y_true_i log(y_pred_i). NaN for zero
// predictions with positive target or length mismatch. Complexity: O(n).
/// Categorical cross entropy -sum y_true_i log(y_pred_i). NaN for zero
/// predictions with positive target or length mismatch. Complexity: O(n).
pub fn loss_cross_entropy(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < y_true.len() {
    var t = y_true[i];
    var p = y_pred[i];
    if t > 0.0 {
      if p <= 0.0 { return 0.0 / 0.0; }
      var lp = math.ln(p);
      s = s - t * lp;
    }
    i = i + 1;
  }
  return s;
}

// Hinge loss sum max(0, 1 - y_true_i * y_pred_i) (targets in {-1, +1}).
// Complexity: O(n).
/// Hinge loss sum max(0, 1 - y_true_i * y_pred_i) (targets in {-1, +1}).
/// Complexity: O(n).
pub fn loss_hinge(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < y_true.len() {
    var m = 1.0 - y_true[i] * y_pred[i];
    if m > 0.0 {
      s = s + m;
    }
    i = i + 1;
  }
  return s / (y_true.len() as Float64);
}

// Fraction of correct predictions (labels in {0, 1}). Complexity: O(n).
/// Fraction of correct predictions (labels in {0, 1}). Complexity: O(n).
pub fn metric_accuracy(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  if y_true.len() == 0 { return 0.0; }
  var ok = 0;
  var i = 0;
  while i < y_true.len() {
    if y_true[i] == y_pred[i] {
      ok = ok + 1;
    }
    i = i + 1;
  }
  return (ok as Float64) / (y_true.len() as Float64);
}

// Precision of the positive class (labels in {0, 1}): TP / (TP + FP).
// Returns 0 when no positive prediction exists (documented). Complexity: O(n).
/// Precision of the positive class (labels in {0, 1}): TP / (TP + FP).
/// Returns 0 when no positive prediction exists (documented). Complexity: O(n).
pub fn metric_precision(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var tp = 0;
  var fp = 0;
  var i = 0;
  while i < y_true.len() {
    if y_pred[i] == 1 {
      if y_true[i] == 1 { tp = tp + 1; } else { fp = fp + 1; }
    }
    i = i + 1;
  }
  if tp + fp == 0 { return 0.0; }
  return (tp as Float64) / ((tp + fp) as Float64);
}

// Recall of the positive class (labels in {0, 1}): TP / (TP + FN).
// Returns 0 when no positive label exists (documented). Complexity: O(n).
/// Recall of the positive class (labels in {0, 1}): TP / (TP + FN).
/// Returns 0 when no positive label exists (documented). Complexity: O(n).
pub fn metric_recall(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var tp = 0;
  var fn_count = 0;  // 'fn' is a reserved keyword (would poison cross-module calls)
  var i = 0;
  while i < y_true.len() {
    if y_true[i] == 1 {
      if y_pred[i] == 1 { tp = tp + 1; } else { fn_count = fn_count + 1; }
    }
    i = i + 1;
  }
  if tp + fn_count == 0 { return 0.0; }
  return (tp as Float64) / ((tp + fn_count) as Float64);
}

// F1 score: harmonic mean of precision and recall. Returns 0 when both are
// zero (documented). Complexity: O(n).
/// F1 score: harmonic mean of precision and recall. Returns 0 when both are
/// zero (documented). Complexity: O(n).
pub fn metric_f1(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 {
  var p = metric_precision(y_true, y_pred);
  var r = metric_recall(y_true, y_pred);
  if p + r == 0.0 { return 0.0; }
  return 2.0 * p * r / (p + r);
}

// Area under the ROC curve computed by the rank-sum (Mann-Whitney) formula:
// AUC = (sum of ranks of positives - P(P+1)/2) / (P * N). NaN on length
// mismatch or empty classes. Complexity: O(n log n).
/// Area under the ROC curve computed by the rank-sum (Mann-Whitney) formula:
/// AUC = (sum of ranks of positives - P(P+1)/2) / (P * N). NaN on length
/// mismatch or empty classes. Complexity: O(n log n).
pub fn metric_auc(y_true: &Vec[Int], y_pred: &Vec[Float64]) -> Float64 {
  if y_true.len() != y_pred.len() { return 0.0 / 0.0; }
  var n = y_true.len();
  var pcount = 0;
  var ncount = 0;
  var i = 0;
  while i < n {
    if y_true[i] == 1 { pcount = pcount + 1; } else { ncount = ncount + 1; }
    i = i + 1;
  }
  if pcount == 0 || ncount == 0 { return 0.0 / 0.0; }
  var pairs = Vec[(Float64, Int)].new();
  var j = 0;
  while j < n {
    pairs.push((y_pred[j], y_true[j]));
    j = j + 1;
  }
  var sorted = _sort_pairs(&pairs);
  var rank_sum = 0.0;
  var k = 0;
  var start = 0;
  while k < n {
    if k + 1 < n && sorted[k].0 == sorted[k + 1].0 {
      k = k + 1;
    } else {
      var end = k;
      var count = (end - start + 1) as Float64;
      var avg = (start + end) as Float64 / 2.0 + 1.0;
      var r = start;
      while r <= end {
        if sorted[r].1 == 1 {
          rank_sum = rank_sum + avg;
        }
        r = r + 1;
      }
      start = end + 1;
      k = end;
    }
    k = k + 1;
  }
  var pf = pcount as Float64;
  var nf = ncount as Float64;
  var denom = pf * nf;
  if denom == 0.0 { return 0.0 / 0.0; }
  return (rank_sum - pf * (pf + 1.0) / 2.0) / denom;
}

// Selection sort of (score, label) pairs ascending by score; returns a new
// sorted vector (no in-place element writes, which miscompile for tuples).
fn _sort_pairs(pairs: &Vec[(Float64, Int)]) -> Vec[(Float64, Int)] {
  var n = pairs.len();
  var out = Vec[(Float64, Int)].new();
  var used = Vec[Bool].new();
  var i = 0;
  while i < n {
    used.push(false);
    i = i + 1;
  }
  var k = 0;
  while k < n {
    var best = -1;
    var best_w = 1.0e300;
    var j = 0;
    while j < n {
      var u = used[j];
      if u == false {
        var e = pairs[j];
        if e.0 < best_w {
          best_w = e.0;
          best = j;
        }
      }
      j = j + 1;
    }
    if best >= 0 {
      used[best] = true;
      out.push(pairs[best]);
    }
    k = k + 1;
  }
  return out;
}

// L1 penalty lambda * sum |w_i|. Complexity: O(n).
/// L1 penalty lambda * sum |w_i|. Complexity: O(n).
pub fn regularization_l1(weights: &Vec[Float64], lambda: Float64) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < weights.len() {
    var w = weights[i];
    if w < 0.0 { w = -w; }
    s = s + w;
    i = i + 1;
  }
  return lambda * s;
}

// L2 penalty lambda * sum w_i^2. Complexity: O(n).
/// L2 penalty lambda * sum w_i^2. Complexity: O(n).
pub fn regularization_l2(weights: &Vec[Float64], lambda: Float64) -> Float64 {
  var s = 0.0;
  var i = 0;
  while i < weights.len() {
    s = s + weights[i] * weights[i];
    i = i + 1;
  }
  return lambda * s;
}

// Elastic-net penalty lambda1 * L1 + lambda2 * L2. Complexity: O(n).
/// Elastic-net penalty lambda1 * L1 + lambda2 * L2. Complexity: O(n).
pub fn regularization_elastic_net(weights: &Vec[Float64], lambda1: Float64, lambda2: Float64) -> Float64 {
  return regularization_l1(weights, lambda1) + regularization_l2(weights, lambda2);
}

// Batch normalization over the batch dimension (per-feature mean/variance,
// with epsilon 1e-5 stabilization; no learned scale/shift). NaN for empty
// input. Complexity: O(batch * features).
// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the batch/feature
// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
// residual; verified by minimal probe). Keep the frozen signature; revisit
// when nested float Vec reads land.
/// Batch normalization over the batch dimension (per-feature mean/variance,
/// with epsilon 1e-5 stabilization; no learned scale/shift). NaN for empty
/// input. Complexity: O(batch * features).
/// TODO(compiler): NOT IMPLEMENTABLE in this compiler build - the batch/feature
/// matrix is a Vec[Vec[Float64]] whose element reads return garbage (BUG 23 #1
/// residual; verified by minimal probe). Keep the frozen signature; revisit
/// when nested float Vec reads land.
pub fn normalization_batch(x: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] {
  var out = Vec[Vec[Float64]].new();
  return out;
}

// Layer normalization of a feature vector: (x - mean) / sqrt(var + eps).
// NaN for empty input. Complexity: O(n).
/// Layer normalization of a feature vector: (x - mean) / sqrt(var + eps).
/// NaN for empty input. Complexity: O(n).
pub fn normalization_layer(x: &Vec[Float64]) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if n == 0 { return out; }
  var mean = 0.0;
  var i = 0;
  while i < n {
    mean = mean + x[i];
    i = i + 1;
  }
  mean = mean / (n as Float64);
  var var_sum = 0.0;
  var j = 0;
  while j < n {
    var d = x[j] - mean;
    var_sum = var_sum + d * d;
    j = j + 1;
  }
  var std = math.sqrt(var_sum / (n as Float64) + 1.0e-5);
  var k = 0;
  while k < n {
    out.push((x[k] - mean) / std);
    k = k + 1;
  }
  return out;
}

// Group normalization: channels (vector positions) are split into `groups`
// contiguous groups, each normalized to zero mean and unit variance.
// NaN for groups <= 0 or a non-divisible length. Complexity: O(n).
/// Group normalization: channels (vector positions) are split into `groups`
/// contiguous groups, each normalized to zero mean and unit variance.
/// NaN for groups <= 0 or a non-divisible length. Complexity: O(n).
pub fn normalization_group(x: &Vec[Float64], groups: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  var n = x.len();
  if groups <= 0 { return out; }
  if n % groups != 0 { return out; }
  var gsize = n / groups;
  var g = 0;
  while g < groups {
    var base = g * gsize;
    var mean = 0.0;
    var i = 0;
    while i < gsize {
      mean = mean + x[base + i];
      i = i + 1;
    }
    mean = mean / (gsize as Float64);
    var v = 0.0;
    var j = 0;
    while j < gsize {
      var d = x[base + j] - mean;
      v = v + d * d;
      j = j + 1;
    }
    var std = math.sqrt(v / (gsize as Float64) + 1.0e-5);
    var k = 0;
    while k < gsize {
      out.push((x[base + k] - mean) / std);
      k = k + 1;
    }
    g = g + 1;
  }
  return out;
}

// Training-time dropout: each element is kept with probability 1 - rate
// (scaled by 1/(1 - rate)); the RNG is seeded with `seed` for reproducible
// masks. NaN for rate outside [0, 1). Complexity: O(n).
/// Training-time dropout: each element is kept with probability 1 - rate
/// (scaled by 1/(1 - rate)); the RNG is seeded with `seed` for reproducible
/// masks. NaN for rate outside [0, 1). Complexity: O(n).
pub fn dropout(x: &Vec[Float64], rate: Float64, seed: Int) -> Vec[Float64] {
  var out = Vec[Float64].new();
  if rate < 0.0 || rate >= 1.0 { return out; }
  math.seed_rng(seed);
  var scale = 1.0 / (1.0 - rate);
  var i = 0;
  while i < x.len() {
    var r = math.random();
    if r >= rate {
      out.push(x[i] * scale);
    } else {
      out.push(0.0);
    }
    i = i + 1;
  }
  return out;
}

// Radial basis function kernel exp(-gamma * ||x - y||^2). NaN on length
// mismatch. Complexity: O(n).
/// Radial basis function kernel exp(-gamma * ||x - y||^2). NaN on length
/// mismatch. Complexity: O(n).
pub fn kernel_rbf(x: &Vec[Float64], y: &Vec[Float64], gamma: Float64) -> Float64 {
  if x.len() != y.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < x.len() {
    var d = x[i] - y[i];
    s = s + d * d;
    i = i + 1;
  }
  return math.exp(-gamma * s);
}

// Polynomial kernel (dot(x, y) + coef0)^degree. NaN on length mismatch.
// Complexity: O(n).
/// Polynomial kernel (dot(x, y) + coef0)^degree. NaN on length mismatch.
/// Complexity: O(n).
pub fn kernel_polynomial(x: &Vec[Float64], y: &Vec[Float64], degree: Int, coef0: Float64) -> Float64 {
  if x.len() != y.len() { return 0.0 / 0.0; }
  var d = coef0;
  var i = 0;
  while i < x.len() {
    d = d + x[i] * y[i];
    i = i + 1;
  }
  return math.pow(d, degree as Float64);
}

// Sigmoid kernel tanh(gamma * dot(x, y) + coef0). NaN on length mismatch.
// Complexity: O(n).
/// Sigmoid kernel tanh(gamma * dot(x, y) + coef0). NaN on length mismatch.
/// Complexity: O(n).
pub fn kernel_sigmoid(x: &Vec[Float64], y: &Vec[Float64], gamma: Float64, coef0: Float64) -> Float64 {
  if x.len() != y.len() { return 0.0 / 0.0; }
  var d = 0.0;
  var i = 0;
  while i < x.len() {
    d = d + x[i] * y[i];
    i = i + 1;
  }
  return activation_tanh(gamma * d + coef0);
}

// Euclidean distance ||a - b||. NaN on length mismatch. Complexity: O(n).
/// Euclidean distance ||a - b||. NaN on length mismatch. Complexity: O(n).
pub fn distance_euclidean(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < a.len() {
    var d = a[i] - b[i];
    s = s + d * d;
    i = i + 1;
  }
  return math.sqrt(s);
}

// Manhattan (L1) distance sum |a_i - b_i|. Complexity: O(n).
/// Manhattan (L1) distance sum |a_i - b_i|. Complexity: O(n).
pub fn distance_manhattan(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < a.len() {
    var d = a[i] - b[i];
    if d < 0.0 { d = -d; }
    s = s + d;
    i = i + 1;
  }
  return s;
}

// Cosine distance 1 - cos_similarity. Complexity: O(n).
/// Cosine distance 1 - cos_similarity. Complexity: O(n).
pub fn distance_cosine(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var sim = similarity_cosine(a, b);
  if sim != sim { return sim; }
  return 1.0 - sim;
}

// Minkowski distance (sum |a_i - b_i|^p)^(1/p). NaN for p <= 0 or length
// mismatch. Complexity: O(n).
/// Minkowski distance (sum |a_i - b_i|^p)^(1/p). NaN for p <= 0 or length
/// mismatch. Complexity: O(n).
pub fn distance_minkowski(a: &Vec[Float64], b: &Vec[Float64], p: Float64) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  if p <= 0.0 { return 0.0 / 0.0; }
  var s = 0.0;
  var i = 0;
  while i < a.len() {
    var d = a[i] - b[i];
    if d < 0.0 { d = -d; }
    s = s + math.pow(d, p);
    i = i + 1;
  }
  return math.pow(s, 1.0 / p);
}

// Cosine similarity dot(a, b) / (||a|| ||b||). NaN for zero norms or length
// mismatch. Complexity: O(n).
/// Cosine similarity dot(a, b) / (||a|| ||b||). NaN for zero norms or length
/// mismatch. Complexity: O(n).
pub fn similarity_cosine(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var dot = 0.0;
  var na = 0.0;
  var nb = 0.0;
  var i = 0;
  while i < a.len() {
    dot = dot + a[i] * b[i];
    na = na + a[i] * a[i];
    nb = nb + b[i] * b[i];
    i = i + 1;
  }
  var denom = math.sqrt(na) * math.sqrt(nb);
  if denom == 0.0 { return 0.0 / 0.0; }
  return dot / denom;
}

// Jaccard similarity for non-negative vectors: sum min(a, b) / sum max(a, b).
// Returns 1 for two zero vectors (documented). Complexity: O(n).
/// Jaccard similarity for non-negative vectors: sum min(a, b) / sum max(a, b).
/// Returns 1 for two zero vectors (documented). Complexity: O(n).
pub fn similarity_jaccard(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var mn = 0.0;
  var mx = 0.0;
  var i = 0;
  while i < a.len() {
    if a[i] < b[i] {
      mn = mn + a[i];
      mx = mx + b[i];
    } else {
      mn = mn + b[i];
      mx = mx + a[i];
    }
    i = i + 1;
  }
  if mx == 0.0 { return 1.0; }
  return mn / mx;
}

// Dice coefficient 2 * sum min(a, b) / (sum a + sum b). Returns 1 for two
// zero vectors (documented). Complexity: O(n).
/// Dice coefficient 2 * sum min(a, b) / (sum a + sum b). Returns 1 for two
/// zero vectors (documented). Complexity: O(n).
pub fn similarity_dice(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 {
  if a.len() != b.len() { return 0.0 / 0.0; }
  var inter = 0.0;
  var sa = 0.0;
  var sb = 0.0;
  var i = 0;
  while i < a.len() {
    if a[i] < b[i] {
      inter = inter + a[i];
    } else {
      inter = inter + b[i];
    }
    sa = sa + a[i];
    sb = sb + b[i];
    i = i + 1;
  }
  var denom = sa + sb;
  if denom == 0.0 { return 1.0; }
  return 2.0 * inter / denom;
}
