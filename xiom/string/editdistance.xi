// XIOM - String: Edit Distance
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.editdistance

// Depends on: xiom.text.similarity, xiom.string

// ============================================================================
// Generic edit distance with an optional early-exit bound. The unbounded
// variant delegates to xiom.text.similarity.levenshtein; the bounded variant
// runs a banded dynamic program whose result provably caps at `max`.
// ============================================================================

use xiom.text.similarity;
use xiom.string;

/// Minimum number of edits (insertions, deletions, substitutions) needed to
/// turn `a` into `b` (the Levenshtein distance). Delegates to
/// `xiom.text.similarity.levenshtein`.
/// Params: a, b - the strings to compare (raw byte sequences).
/// Returns: the edit distance (>= 0).
/// Errors: none.
/// Complexity: O(|a| * |b|) time, O(|b|) space.
pub fn edit_distance(a: Str, b: Str) -> Int {
  similarity.levenshtein(a, b)
}

/// Edit distance capped at `max`: the exact distance when it does not exceed
/// `max`, otherwise `max` itself. The dynamic program only evaluates cells
/// within `max` of the diagonal (|i - j| <= max), so the result is correct
/// whenever it lies at or below `max`. A negative `max` is treated as
/// unbounded and returns the exact distance.
/// Params: a, b - the strings to compare; max - the cap (>= 0).
/// Returns: min(edit_distance(a, b), max); the exact distance when max < 0.
/// Errors: none (every input combination is handled in the body).
/// Complexity: O(|a| * |b|) time worst case, O(|b|) space; the DP arithmetic
/// runs only within the band |i - j| <= max.
pub fn edit_distance_limited(a: Str, b: Str, max: Int) -> Int {
  if max < 0 {
    return similarity.levenshtein(a, b);
  };
  let m = a.len();
  let n = b.len();
  if m == 0 {
    if n > max { return max; };
    return n;
  };
  if n == 0 {
    if m > max { return max; };
    return m;
  };
  if m >= n && m - n > max { return max; };
  if n > m && n - m > max { return max; };
  if max >= m + n {
    return similarity.levenshtein(a, b);
  };
  var prev = Vec[Int].new();
  var j: Int = 0;
  while j <= n {
    if j <= max {
      prev.push(j);
    } else {
      prev.push(max + 1);
    };
    j = j + 1;
  };
  var i: Int = 1;
  while i <= m {
    var cur = Vec[Int].new();
    var j2: Int = 0;
    while j2 <= n {
      cur.push(max + 1);
      j2 = j2 + 1;
    };
    if i <= max {
      cur[0] = i;
    };
    j = 1;
    while j <= n {
      var gap = i - j;
      if gap < 0 { gap = -gap; };
      if gap <= max {
        var cost: Int = 1;
        if xiom.string.byte_at(a, i - 1) == xiom.string.byte_at(b, j - 1) {
          cost = 0;
        };
        var del = prev[j] + 1;
        var ins = cur[j - 1] + 1;
        var sub = prev[j - 1] + cost;
        var best = del;
        if ins < best { best = ins; };
        if sub < best { best = sub; };
        cur[j] = best;
      };
      j = j + 1;
    };
    prev = cur;
    i = i + 1;
  };
  var res = prev[n];
  if res > max { return max; };
  res
}
