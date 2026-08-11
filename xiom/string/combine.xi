// XIOM - String: Combine
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.combine

// Depends on: none

// ============================================================================
// Enumerate the combinations of a string, optionally by rank. NOTE: current
// implementation lives in string.combinatorics stub - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Returns the binomial coefficient C(n, k); 0 when k is outside [0, n].
/// Uses the multiplicative formula, exact at every step.
/// Complexity: O(min(k, n-k)).
fn _binomial(n: Int, k: Int) -> Int {
  if k < 0 || k > n {
    return 0;
  };
  var kk = k;
  if kk > n - kk {
    kk = n - kk;
  };
  var result: Int = 1;
  var i: Int = 1;
  while i <= kk {
    result = result * (n - kk + i) / i;
    i = i + 1;
  };
  result
}

/// Advances the index vector to the next k-combination of indices in [0, n).
/// Returns false when the current combination was the last one.
/// Complexity: O(k).
fn _next_combination(idx: &mut Vec[Int], n: Int, k: Int) -> Bool {
  var i: Int = k - 1;
  while i >= 0 {
    if idx[i] < n - k + i {
      idx[i] = idx[i] + 1;
      var j: Int = i + 1;
      while j < k {
        idx[j] = idx[j - 1] + 1;
        j = j + 1;
      };
      return true;
    };
    i = i - 1;
  };
  false
}

/// Returns all n-length combinations of the characters of `s`, in source
/// order: within every combination the characters keep their relative order.
/// A combination size below 1 or above the string length yields an empty
/// vector.
/// Params: s the source string; n the number of characters per combination.
/// Returns: a Vec[Str] with C(|s|, n) elements.
/// Error case: n < 1 or n > s.len() => empty vector.
/// Complexity: O(C(|s|, n) * n).
pub fn str_combinations(s: Str, n: Int) -> Vec[Str] {
  var result = Vec[Str].new();
  let len = string.str_len(s);
  if n < 1 || n > len {
    return result;
  };
  var idx = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    idx.push(i);
    i = i + 1;
  };
  loop {
    var piece = "";
    var j: Int = 0;
    while j < n {
      let one = string.str_slice(s, idx[j], idx[j] + 1);
      piece = string.str_concat(piece, one);
      j = j + 1;
    };
    result.push(piece);
    if !_next_combination(&mut idx, len, n) {
      break;
    };
  };
  result
}

/// Returns the n-length combination of the characters of `s` at the given
/// `rank` (0-based, same enumeration order as str_combinations), or the empty
/// string when `rank` is out of range.
/// Params: s the source string; n the combination size; rank the 0-based
///         combination index.
/// Returns: the ranked combination string.
/// Error case: "" when n < 1, n > s.len(), rank < 0, or rank >= C(|s|, n).
/// Complexity: O(n^2) with O(1) binomial lookups.
pub fn str_combination_at(s: Str, n: Int, rank: Int) -> Str {
  let len = string.str_len(s);
  if n < 1 || n > len {
    return "";
  };
  if rank < 0 {
    return "";
  };
  let total = _binomial(len, n);
  if rank >= total {
    return "";
  };
  var r = rank;
  var prev: Int = -1;
  var result = "";
  var i: Int = 0;
  while i < n {
    var c = prev + 1;
    var found_c = false;
    while c < len {
      let count = _binomial(len - c - 1, n - i - 1);
      if r < count {
        found_c = true;
        break;
      };
      r = r - count;
      c = c + 1;
    };
    if !found_c {
      return "";
    };
    let one = string.str_slice(s, c, c + 1);
    result = string.str_concat(result, one);
    prev = c;
    i = i + 1;
  };
  result
}
