// XIOM - String: Jaro
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.jaro

// Depends on: xiom.misc

// ============================================================================
// Jaro and Jaro-Winkler string similarity scores. Both delegate to the
// canonical implementations in xiom.misc.
// ============================================================================

use xiom.misc;

/// Jaro similarity of `a` and `b` in the 0.0..1.0 range (1.0 = identical,
/// 0.0 = no matching characters). Delegates to `xiom.misc.jaro_similarity`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the Jaro score; 1.0 when both inputs are empty, 0.0 when either
/// input is empty or no characters match.
/// Errors: none (empty inputs are handled in the body).
/// Complexity: O(|a| * |b|) worst case.
pub fn jaro_similarity(a: Str, b: Str) -> Float64 {
  misc.jaro_similarity(a, b)
}

/// Jaro-Winkler similarity of `a` and `b`: the Jaro score boosted by a
/// common-prefix bonus (up to 4 prefix characters, scale 0.1). Delegates to
/// `xiom.misc.jaro_winkler_similarity`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the Jaro-Winkler score in 0.0..1.0.
/// Errors: none.
/// Complexity: O(|a| * |b|) worst case.
pub fn jaro_winkler_similarity(a: Str, b: Str) -> Float64 {
  misc.jaro_winkler_similarity(a, b)
}
