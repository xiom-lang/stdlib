// XIOM - String: Jaccard
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.jaccard

// Depends on: xiom.text.similarity

// ============================================================================
// Jaccard similarity of two strings over their length-n n-gram sets. The
// canonical implementation lives in xiom.text.similarity; this module
// re-exposes it under the xiom.string.jaccard API.
// ============================================================================

use xiom.text.similarity;

/// Jaccard index of the length-n n-gram sets of `a` and `b`:
/// |A & B| / |A | B|, where each set holds the distinct character n-grams of
/// one input. Delegates to `xiom.text.similarity.jaccard_similarity`.
/// Params: a, b - the strings to compare; n - the n-gram size (>= 1).
/// Returns: the Jaccard similarity in 0.0..1.0; 1.0 when both inputs produce
/// identical n-gram sets; 0.0 when n < 1, when an input is shorter than `n`,
/// or when both inputs have no n-grams.
/// Errors: none (empty/short inputs are handled in the body).
/// Complexity: O(|a| * |b|) worst case.
pub fn jaccard_similarity(a: Str, b: Str, n: Int) -> Float64 {
  similarity.jaccard_similarity(a, b, n)
}
