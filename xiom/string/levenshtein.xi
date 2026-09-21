// XIOM - String: Levenshtein
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.levenshtein

// Depends on: xiom.misc, xiom.convert

// ============================================================================
// Levenshtein edit distance between two strings, raw and normalized. The raw
// distance delegates to xiom.misc.levenshtein_distance (the canonical
// implementation); the normalized variant is computed on top of it.
// ============================================================================

use xiom.misc;
use xiom.convert;

/// Levenshtein edit distance between `a` and `b`: the minimum number of
/// insertions, deletions and substitutions needed to turn `a` into `b`.
/// Delegates to `xiom.misc.levenshtein_distance`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the edit distance (>= 0).
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(min(|a|,|b|)) space.
pub fn levenshtein_distance(a: Str, b: Str) -> Int
  ensures: result >= 0
{
  misc.levenshtein_distance(a, b)
}

/// Levenshtein distance normalized to the 0.0..1.0 range, defined as
/// distance / max(|a|, |b|): 0.0 for identical strings, 1.0 when one of the
/// inputs is empty, and strictly between 0.0 and 1.0 otherwise.
/// Params: a, b - the strings to compare.
/// Returns: the normalized distance in 0.0..1.0 (inclusive).
/// Errors: none (the empty-vs-empty case is guarded to avoid a division by
/// zero).
/// Complexity: O(|a| * |b|) via the underlying distance.
pub fn levenshtein_normalized(a: Str, b: Str) -> Float64 {
  let d = misc.levenshtein_distance(a, b);
  let m = a.len();
  let n = b.len();
  if m == 0 && n == 0 {
    return 0.0;
  };
  var denom = m;
  if n > denom {
    denom = n;
  };
  let df = convert.int_to_float(d);
  let denf = convert.int_to_float(denom);
  df / denf
}
