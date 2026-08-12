// XIOM - String: Damerau
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.damerau

// Depends on: xiom.misc, xiom.text.similarity

// ============================================================================
// Damerau-Levenshtein and optimal string alignment distances. Both entry
// points delegate to the existing canonical implementations: xiom.misc for
// damerau_levenshtein_distance, xiom.text.similarity for the OSA variant.
// ============================================================================

use xiom.misc;
use xiom.text.similarity;

/// Damerau-Levenshtein distance between `a` and `b`: the minimum number of
/// insertions, deletions, substitutions and adjacent-character transpositions
/// needed to turn `a` into `b`. Delegates to
/// `xiom.misc.damerau_levenshtein_distance`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the edit distance (>= 0).
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn damerau_levenshtein_distance(a: Str, b: Str) -> Int {
  misc.damerau_levenshtein_distance(a, b)
}

/// Optimal string alignment (OSA) distance between `a` and `b`: an edit
/// distance in which each adjacent-character transposition counts once and no
/// substring may be edited more than once. Delegates to
/// `xiom.text.similarity.damerau_levenshtein`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the OSA distance (>= 0).
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn osa_distance(a: Str, b: Str) -> Int {
  similarity.damerau_levenshtein(a, b)
}
