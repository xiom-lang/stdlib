// XIOM - String: NFKC
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.nfkc

// Depends on: xiom.string.normalize

// ============================================================================
// Compatibility normalization forms NFKC and NFKD. The normalization tables
// live in xiom.string.normalize (canonical implementation); this module
// re-exports the compatibility forms behind the xiom.string.nfkc API.
// ============================================================================

use xiom.string.normalize;

/// Normalize `s` to NFKC (compatibility composition). See
/// `xiom.string.normalize.unicode_normalize_nfkc` for the documented coverage.
/// Params: s the string to normalize.
/// Returns: the NFKC-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfkc(s: Str) -> Str {
  normalize.unicode_normalize_nfkc(s)
}

/// Normalize `s` to NFKD (compatibility decomposition). See
/// `xiom.string.normalize.unicode_normalize_nfkd` for the documented coverage.
/// Params: s the string to normalize.
/// Returns: the NFKD-normalized string.
/// Error case: none; malformed UTF-8 bytes pass through approximately.
/// Complexity: O(|s|).
pub fn unicode_normalize_nfkd(s: Str) -> Str {
  normalize.unicode_normalize_nfkd(s)
}
