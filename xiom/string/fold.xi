// XIOM - String: Fold
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.fold

// Depends on: none

// ============================================================================
// Unicode case folding, full and default variants. NOTE: current implementation
// lives in string.unicode stub - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string.casefold;

/// Full Unicode case folding of `s` for case-insensitive matching. ASCII,
/// Latin-1, Latin Extended-A, Greek and Cyrillic uppercase letters fold to
/// their lowercase forms; the sharp s (ss/SS) folds to "ss" and dotted capital I
/// (I) folds to "i" + combining dot. See `xiom.string.casefold.str_casefold`
/// for the documented coverage.
/// Params: s the string to fold.
/// Returns: the case-folded string.
/// Error case: none; malformed UTF-8 bytes pass through unchanged.
/// Complexity: O(|s|).
pub fn unicode_casefold(s: Str) -> Str {
  let r = casefold.str_casefold(s);
  r
}

/// Full (F) Unicode case fold of `s`, applying the multi-character mappings
/// (ss/SS -> "ss", I -> "i" + combining dot). Currently identical to
/// `unicode_casefold`; both expose the same full case-folding table.
/// Params: s the string to fold.
/// Returns: the fully case-folded string.
/// Error case: none; malformed UTF-8 bytes pass through unchanged.
/// Complexity: O(|s|).
pub fn unicode_fold_full(s: Str) -> Str {
  let r = casefold.str_casefold(s);
  r
}
