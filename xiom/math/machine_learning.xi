// XIOM - Math: Machine Learning
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.math.machine_learning

// Depends on: xiom.math

// ============================================================================
// Numerical building blocks for machine learning: activations, losses,
// metrics, regularizers, kernels, distances, and similarities.
// TODO(compiler): implement.
// ============================================================================

// fn activation_sigmoid(x: Float64) -> Float64 - logistic sigmoid 1/(1+exp(-x)).
// fn activation_tanh(x: Float64) -> Float64 - hyperbolic tangent activation.
// fn activation_relu(x: Float64) -> Float64 - rectified linear unit max(0, x).
// fn activation_gelu(x: Float64) -> Float64 - Gaussian error linear unit.
// fn activation_swish(x: Float64) -> Float64 - swish x*sigmoid(x).
// fn loss_mse(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 - mean squared error.
// fn loss_mae(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 - mean absolute error.
// fn loss_huber(y_true: &Vec[Float64], y_pred: &Vec[Float64], delta: Float64) -> Float64 - Huber loss with threshold delta.
// fn loss_cross_entropy(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 - categorical cross entropy.
// fn loss_hinge(y_true: &Vec[Float64], y_pred: &Vec[Float64]) -> Float64 - hinge loss for support vector machines.
// fn metric_accuracy(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 - fraction of correct predictions.
// fn metric_precision(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 - precision of the positive class.
// fn metric_recall(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 - recall of the positive class.
// fn metric_f1(y_true: &Vec[Int], y_pred: &Vec[Int]) -> Float64 - harmonic mean of precision and recall.
// fn metric_auc(y_true: &Vec[Int], y_pred: &Vec[Float64]) -> Float64 - area under the ROC curve.
// fn regularization_l1(weights: &Vec[Float64], lambda: Float64) -> Float64 - L1 penalty on weights.
// fn regularization_l2(weights: &Vec[Float64], lambda: Float64) -> Float64 - L2 penalty on weights.
// fn regularization_elastic_net(weights: &Vec[Float64], lambda1: Float64, lambda2: Float64) -> Float64 - combined L1/L2 penalty.
// fn normalization_batch(x: &Vec[Vec[Float64]]) -> Vec[Vec[Float64]] - batch normalization over the batch dimension.
// fn normalization_layer(x: &Vec[Float64]) -> Vec[Float64] - layer normalization of a feature vector.
// fn normalization_group(x: &Vec[Float64], groups: Int) -> Vec[Float64] - group normalization over groups of channels.
// fn dropout(x: &Vec[Float64], rate: Float64, seed: Int) -> Vec[Float64] - training-time dropout mask application.
// fn kernel_rbf(x: &Vec[Float64], y: &Vec[Float64], gamma: Float64) -> Float64 - radial basis function kernel.
// fn kernel_polynomial(x: &Vec[Float64], y: &Vec[Float64], degree: Int, coef0: Float64) -> Float64 - polynomial kernel.
// fn kernel_sigmoid(x: &Vec[Float64], y: &Vec[Float64], gamma: Float64, coef0: Float64) -> Float64 - sigmoid kernel.
// fn distance_euclidean(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - Euclidean distance.
// fn distance_manhattan(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - L1 (Manhattan) distance.
// fn distance_cosine(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - cosine distance, 1 minus cosine similarity.
// fn distance_minkowski(a: &Vec[Float64], b: &Vec[Float64], p: Float64) -> Float64 - Minkowski distance of order p.
// fn similarity_cosine(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - cosine similarity.
// fn similarity_jaccard(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - Jaccard similarity of two vectors.
// fn similarity_dice(a: &Vec[Float64], b: &Vec[Float64]) -> Float64 - Dice coefficient of two vectors.
