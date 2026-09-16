// XIOM - String: Cosine
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.cosine

// Depends on: xiom.math, xiom.string, xiom.convert

// ============================================================================
// Cosine similarity of two strings over their length-n character n-gram
// vectors. Unlike xiom.text.similarity.cosine_similarity (unigram
// frequencies), this module supports an arbitrary n-gram size. N-gram
// identity is by djb2 hash code, matching the n-gram machinery of
// xiom.text.similarity.ngram_similarity.
// ============================================================================

use xiom.math.sqrt;
use xiom.string;
use xiom.convert;

// djb2 hash of the `n` consecutive bytes of `s` starting at `start`. The
// bytes are masked to 0xFF because `byte_at(...) as Int` sign-extends; Int
// wraparound is intentional - only code equality matters.
fn _ngram_code(s: Str, start: Int, n: Int) -> Int {
  var h: Int = 5381;
  var i = start;
  var end = start + n;
  while i < end {
    let raw = xiom.string.byte_at(s, i) as Int;
    let masked = raw & 0xFF;
    h = h * 33 + masked;
    i = i + 1;
  }
  h
}

// Every length-n n-gram of `s` as a hash code, duplicates included.
fn _ngram_codes(s: Str, n: Int) -> Vec[Int] {
  var out = Vec[Int].new();
  let len = s.len();
  var i: Int = 0;
  while i + n <= len {
    out.push(_ngram_code(s, i, n));
    i = i + 1;
  }
  out
}

// True when `code` is present in `vec`.
fn _contains(vec: &Vec[Int], code: Int) -> Bool {
  var i: Int = 0;
  while i < vec.len() {
    if vec[i] == code {
      return true;
    };
    i = i + 1;
  }
  false
}

// Number of occurrences of `code` in `vec`.
fn _count_of(vec: &Vec[Int], code: Int) -> Int {
  var c: Int = 0;
  var i: Int = 0;
  while i < vec.len() {
    if vec[i] == code {
      c = c + 1;
    };
    i = i + 1;
  }
  c
}

/// Cosine of the angle between the length-n n-gram frequency vectors of `a`
/// and `b`. Identical strings score 1.0; strings with no shared n-gram score
/// 0.0. N-gram identity is by djb2 hash code (see the module header).
/// Params: a, b - the strings to compare; n - the n-gram size (>= 1).
/// Returns: the cosine similarity in 0.0..1.0; 0.0 when n < 1, when either
/// input is shorter than `n`, or when either vector is empty.
/// Errors: none (empty/short inputs are handled in the body).
/// Complexity: O(|a| * |b|) worst case.
pub fn cosine_similarity(a: Str, b: Str, n: Int) -> Float64
  requires: true  // extern sqrt calls below (T002 confinement)
{
  if n <= 0 {
    return 0.0;
  };
  let la = a.len();
  let lb = b.len();
  if la < n || lb < n {
    return 0.0;
  };
  var ca_codes = _ngram_codes(a, n);
  var cb_codes = _ngram_codes(b, n);
  if ca_codes.len() == 0 || cb_codes.len() == 0 {
    return 0.0;
  };
  var ua = Vec[Int].new();
  var i: Int = 0;
  while i < ca_codes.len() {
    var code = ca_codes[i];
    if !_contains(&ua, code) {
      ua.push(code);
    };
    i = i + 1;
  }
  var dot: Int = 0;
  var na: Int = 0;
  var nb: Int = 0;
  i = 0;
  while i < ua.len() {
    var code = ua[i];
    var ca = _count_of(&ca_codes, code);
    var cb = _count_of(&cb_codes, code);
    dot = dot + ca * cb;
    na = na + ca * ca;
    nb = nb + cb * cb;
    i = i + 1;
  }
  var ub = Vec[Int].new();
  i = 0;
  while i < cb_codes.len() {
    var code = cb_codes[i];
    if !_contains(&ub, code) {
      ub.push(code);
    };
    i = i + 1;
  }
  i = 0;
  while i < ub.len() {
    var code = ub[i];
    if !_contains(&ua, code) {
      var cb2 = _count_of(&cb_codes, code);
      nb = nb + cb2 * cb2;
    };
    i = i + 1;
  }
  if na == 0 || nb == 0 {
    return 0.0;
  };
  let na_f = convert.int_to_float(na);
  let nb_f = convert.int_to_float(nb);
  let s_na = sqrt(na_f);
  let s_nb = sqrt(nb_f);
  let denom = s_na * s_nb;
  if denom == 0.0 {
    return 0.0;
  };
  let dot_f = convert.int_to_float(dot);
  dot_f / denom
}
