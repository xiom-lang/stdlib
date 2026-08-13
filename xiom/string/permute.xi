// XIOM - String: Permute
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.permute

// Depends on: none

// ============================================================================
// Enumerate the permutations of a string, optionally length-limited or by rank.
// NOTE: current implementation lives in string.combinatorics stub - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// ── Private helpers ─────────────────────────────────────────────────────────

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _pm_byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// Builds a string from `s` by concatenating the single-byte characters at the
// byte offsets given by `idx`, in order. Byte-based (ASCII-exact).
// Complexity: O(|idx|).
fn _pm_piece(s: Str, idx: &Vec[Int]) -> Str {
  var piece = "";
  var j: Int = 0;
  while j < idx.len() {
    let pos = idx[j];
    let one = string.str_slice(s, pos, pos + 1);
    piece = string.str_concat(piece, one);
    j = j + 1;
  };
  piece
}

// Advances the index vector to the next combination of indices in [0, n).
// Returns false when the current combination was the last one.
// Complexity: O(k).
fn _pm_next_comb(idx: &mut Vec[Int], n: Int, k: Int) -> Bool {
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

// Advances the index vector to the next permutation in lexicographic order.
// Returns false when the current permutation was the last one.
// Complexity: O(|idx|).
fn _pm_next_perm(idx: &mut Vec[Int]) -> Bool {
  let n = idx.len();
  if n < 2 {
    return false;
  };
  var i: Int = n - 2;
  loop {
    if i < 0 {
      break;
    };
    if idx[i] < idx[i + 1] {
      break;
    };
    i = i - 1;
  };
  if i < 0 {
    return false;
  };
  var j: Int = n - 1;
  while idx[j] < idx[i] {
    j = j - 1;
  };
  let t = idx[i];
  idx[i] = idx[j];
  idx[j] = t;
  var lo = i + 1;
  var hi = n - 1;
  while lo < hi {
    let t2 = idx[lo];
    idx[lo] = idx[hi];
    idx[hi] = t2;
    lo = lo + 1;
    hi = hi - 1;
  };
  true
}

// Independent copy of a Vec[Int].
// Complexity: O(|v|).
fn _pm_copy_idx(v: &Vec[Int]) -> Vec[Int] {
  var c = Vec[Int].new();
  var i: Int = 0;
  while i < v.len() {
    let e = v[i];
    c.push(e);
    i = i + 1;
  };
  c
}

// ── Public API ──────────────────────────────────────────────────────────────

/// All permutations of the characters of `s`, treating the characters as
/// distinct (n! results). An empty string yields a vector containing "".
/// The permutations are emitted in lexicographic byte order.
/// Params: s the source string.
/// Returns: a Vec[Str] with n! permutations.
/// Error case: inputs longer than 8 characters return an empty vector
///             (documented guard against an impractical result set).
/// Complexity: O(n! * n).
pub fn str_permutations(s: Str) -> Vec[Str] {
  var out = Vec[Str].new();
  let len = string.str_len(s);
  if len == 0 {
    out.push("");
    return out;
  };
  if len > 8 {
    return out;
  };
  var idx = Vec[Int].new();
  var i: Int = 0;
  while i < len {
    idx.push(i);
    i = i + 1;
  };
  loop {
    let piece = _pm_piece(s, &idx);
    out.push(piece);
    if !_pm_next_perm(&mut idx) {
      break;
    };
  };
  out
}

/// All n-length arrangements of the characters of `s` (P(|s|, n) results).
/// n == 0 yields [""]; n < 0 or n > |s| yields an empty vector.
/// Params: s the source string; n the arrangement length.
/// Returns: a Vec[Str] of n-length permutations.
/// Error case: n < 0 or n > |s| => empty vector; large inputs are guarded as
///             in str_permutations.
/// Complexity: O(P(n, k) * k).
pub fn str_permutations_n(s: Str, n: Int) -> Vec[Str] {
  var out = Vec[Str].new();
  let len = string.str_len(s);
  if n < 0 || n > len {
    return out;
  };
  if n == 0 {
    out.push("");
    return out;
  };
  if len > 8 {
    return out;
  };
  var sel = Vec[Int].new();
  var i: Int = 0;
  while i < n {
    sel.push(i);
    i = i + 1;
  };
  loop {
    var order = _pm_copy_idx(&sel);
    loop {
      let piece = _pm_piece(s, &order);
      out.push(piece);
      if !_pm_next_perm(&mut order) {
        break;
      };
    };
    if !_pm_next_comb(&mut sel, len, n) {
      break;
    };
  };
  out
}

/// The permutation of the (distinct) characters of `s` at `rank` in
/// lexicographic order, or "" when `rank` is out of range. For "abc": rank 0
/// is "abc", 1 is "acb", 2 is "bac", and so on up to rank 5 = "cba".
/// Params: s the source string; rank the 0-based permutation index.
/// Returns: the ranked permutation, "" when rank is out of range.
/// Error case: rank < 0 or rank >= |s|! => ""; inputs longer than 20
///             characters => "" (factorial range guard).
/// Complexity: O(|s|^2).
pub fn str_permutation_at(s: Str, rank: Int) -> Str {
  let len = string.str_len(s);
  if len == 0 {
    return "";
  };
  if rank < 0 {
    return "";
  };
  if len > 20 {
    return "";
  };
  var fac = Vec[Int].new();
  fac.push(1);
  var f: Int = 1;
  var i: Int = 1;
  while i <= len {
    if f > 9223372036854775807 / i {
      return "";
    };
    f = f * i;
    fac.push(f);
    i = i + 1;
  };
  if rank >= fac[len] {
    return "";
  };
  var remaining = Vec[Int].new();
  var k: Int = 0;
  while k < len {
    remaining.push(k);
    k = k + 1;
  };
  var result = "";
  var r = rank;
  var pos: Int = 0;
  while pos < len {
    let block = fac[len - 1 - pos];
    let idx = r / block;
    let pick_pos = remaining[idx];
    let one = string.str_slice(s, pick_pos, pick_pos + 1);
    result = string.str_concat(result, one);
    var rem2 = Vec[Int].new();
    var k2: Int = 0;
    while k2 < remaining.len() {
      if k2 != idx {
        let e = remaining[k2];
        rem2.push(e);
      };
      k2 = k2 + 1;
    };
    remaining = rem2;
    r = r % block;
    pos = pos + 1;
  };
  result
}
