// XIOM - String: LCP
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.lcp

// Depends on: xiom.text.similarity, xiom.string

// ============================================================================
// Longest common prefix of two strings or of a vector of strings. The
// two-string variant delegates to xiom.text.similarity.longest_common_prefix;
// the vector variant is implemented here (no canonical implementation exists).
// ============================================================================

use xiom.text.similarity;
use xiom.string;

// Raw byte at `i` (byte-level compare; wave 128: cached raw pointer --
// xiom.string.byte_at strnlens the whole string per call, so the pairwise
// scan re-read the prefixes quadratically).
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// Length of the longest common prefix of `a` and `b` (in bytes). Delegates
/// to `xiom.text.similarity.longest_common_prefix`.
/// Params: a, b - the strings to compare.
/// Returns: the shared prefix length in 0..min(|a|, |b|).
/// Errors: none.
/// Complexity: O(min(|a|, |b|)).
pub fn longest_common_prefix(a: Str, b: Str) -> Int
  ensures: result >= 0
{
  similarity.longest_common_prefix(a, b)
}

/// Length of the longest common prefix shared by every string in `strings`
/// (in bytes). The empty vector has a common prefix of length 0; a
/// single-element vector shares its entire length.
/// Params: strings - the strings to compare.
/// Returns: the shared prefix length (>= 0).
/// Errors: none (the empty vector is handled in the body).
/// Complexity: O(total bytes of all strings).
pub fn lcp_of_many(strings: &Vec[Str]) -> Int
  ensures: result >= 0
{
  let count = strings.len();
  if count == 0 {
    return 0;
  };
  var first = strings[0];
  let bfirst = first.c_str();
  var result = first.len();
  var i: Int = 1;
  while i < count {
    var s = strings[i];
    let bs = s.c_str();
    var l = s.len();
    if l < result {
      result = l;
    };
    var j: Int = 0;
    while j < result {
      if _raw_byte(bfirst, j) != _raw_byte(bs, j) {
        result = j;
        break;
      };
      j = j + 1;
    };
    if result == 0 {
      return 0;
    };
    i = i + 1;
  };
  result
}
