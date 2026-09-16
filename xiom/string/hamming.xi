// XIOM - String: Hamming
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.hamming

// Depends on: xiom.misc

// ============================================================================
// Hamming distance between two equal-length strings. The canonical
// implementation lives in xiom.misc (misc.hamming_distance); this module
// re-exposes it under the xiom.string.hamming API.
// ============================================================================

use xiom.misc;

/// Hamming distance between `a` and `b`: the number of byte positions where
/// the two strings differ. Delegates to `xiom.misc.hamming_distance`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the number of differing positions; -1 when a.len() != b.len().
/// Error case: a length mismatch is reported via the -1 return (no trap).
/// Complexity: O(|a|).
pub fn hamming_distance(a: Str, b: Str) -> Int
  ensures: a.len() == b.len() => result >= 0
{
  misc.hamming_distance(a, b)
}
