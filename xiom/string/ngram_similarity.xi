// XIOM - String: Ngram Similarity
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.ngram_similarity

// Depends on: xiom.text.similarity

// ============================================================================
// N-gram-based similarity between two strings. The canonical implementation
// lives in xiom.text.similarity; this module re-exposes it under the
// xiom.string.ngram_similarity API.
// ============================================================================

use xiom.text.similarity;

/// Similarity of `a` and `b` from their shared length-n n-grams, computed as
/// the Jaccard index over the distinct n-gram hash-code sets (see
/// xiom.text.similarity). Delegates to
/// `xiom.text.similarity.ngram_similarity`.
/// Params: a, b - the strings to compare; n - the n-gram size (>= 1).
/// Returns: the similarity in 0.0..1.0; 1.0 for identical strings; 0.0 when
/// n < 1, when an input is shorter than `n`, or when either side has no
/// n-grams.
/// Errors: none (empty/short inputs are handled in the body).
/// Complexity: O(|a| * |b|) worst case.
pub fn ngram_similarity(a: Str, b: Str, n: Int) -> Float64 {
  similarity.ngram_similarity(a, b, n)
}
