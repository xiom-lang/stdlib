// XIOM - Search: Boyer-Moore
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.search.boyer

// Depends on: none

// ============================================================================
// Boyer-Moore and Rabin-Karp substring search with skip tables/hashes.
// ============================================================================

/// Bad-character shift table indexed by byte value: table[b] is the index of
/// the last occurrence of byte b in pattern, or -1 if b never occurs. O(m).
pub fn boyer_moore_bad_char(pattern: Str) -> Vec[Int] {
  var table = Vec[Int].new();
  var b = 0;
  while b < 256 {
    table.push(-1);
    b = b + 1;
  }
  var i = 0;
  while i < pattern.len() {
    table[pattern.char_at(i) as Int] = i;
    i = i + 1;
  }
  table
}

/// Good-suffix shift table: gs[i] is the safe shift when a mismatch occurs at
/// pattern position i. O(m). Computed from the standard suffix array.
pub fn boyer_moore_good_suffix(pattern: Str) -> Vec[Int] {
  var m = pattern.len();
  var gs = Vec[Int].new();
  var suff = Vec[Int].new();
  var i = 0;
  while i < m {
    gs.push(m);
    suff.push(0);
    i = i + 1;
  }
  if m == 0 { return gs; }
  suff[m - 1] = m;
  i = m - 2;
  while i >= 0 {
    var j = i;
    while j >= 0 && pattern.char_at(j) == pattern.char_at(m - 1 - (i - j)) {
      j = j - 1;
    }
    suff[i] = i - j;
    i = i - 1;
  }
  var j = 0;
  i = m - 1;
  while i >= 0 {
    if suff[i] == i + 1 {
      while j < m - 1 - i {
        if gs[j] == m { gs[j] = m - 1 - i; }
        j = j + 1;
      }
    }
    i = i - 1;
  }
  i = 0;
  while i <= m - 2 {
    gs[m - 1 - suff[i]] = m - 1 - i;
    i = i + 1;
  }
  gs
}

/// Start index of the first pattern occurrence in text using the full
/// Boyer-Moore algorithm (bad-character + good-suffix tables).
/// O(n/m) best, O(n*m) worst. Returns None when pattern is empty or longer
/// than text.
pub fn boyer_moore_search(text: Str, pattern: Str) -> Option[Int] {
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return None; }
  var bad = boyer_moore_bad_char(pattern);
  var gs = boyer_moore_good_suffix(pattern);
  var i = 0;
  while i <= n - m {
    var j = m - 1;
    while j >= 0 && text.char_at(i + j) == pattern.char_at(j) {
      j = j - 1;
    }
    if j < 0 {
      return Some(i);
    }
    var bad_shift = j - bad[text.char_at(i + j) as Int];
    var gs_shift = gs[j];
    var shift = bad_shift;
    if gs_shift > shift { shift = gs_shift; }
    if shift < 1 { shift = 1; }
    i = i + shift;
  }
  None
}

/// Start indices of every occurrence of pattern in text (full Boyer-Moore).
/// O(n/m) average. Empty pattern yields an empty result.
pub fn boyer_moore_search_all(text: Str, pattern: Str) -> Vec[Int] {
  var out = Vec[Int].new();
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return out; }
  var bad = boyer_moore_bad_char(pattern);
  var gs = boyer_moore_good_suffix(pattern);
  var i = 0;
  while i <= n - m {
    var j = m - 1;
    while j >= 0 && text.char_at(i + j) == pattern.char_at(j) {
      j = j - 1;
    }
    if j < 0 {
      out.push(i);
      var shift = gs[0];
      if shift < 1 { shift = 1; }
      i = i + shift;
    } else {
      var bad_shift = j - bad[text.char_at(i + j) as Int];
      var gs_shift = gs[j];
      var shift = bad_shift;
      if gs_shift > shift { shift = gs_shift; }
      if shift < 1 { shift = 1; }
      i = i + shift;
    }
  }
  out
}

/// Horspool variant of Boyer-Moore: bad-character table only, keyed on the
/// last text character of the window. O(n*m) worst, good average.
pub fn boyer_moore_horspool(text: Str, pattern: Str) -> Option[Int] {
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return None; }
  var bad = boyer_moore_bad_char(pattern);
  var i = 0;
  while i <= n - m {
    var j = m - 1;
    while j >= 0 && text.char_at(i + j) == pattern.char_at(j) {
      j = j - 1;
    }
    if j < 0 {
      return Some(i);
    }
    var last = text.char_at(i + m - 1) as Int;
    var shift = m - 1 - bad[last];
    if shift < 1 { shift = 1; }
    i = i + shift;
  }
  None
}

/// Rolling-hash base and modulus for Rabin-Karp (fixed constants).
const RK_BASE: Int = 31;
const RK_MOD: Int = 2147483647;

/// Rolling hash value of the string s. O(len). Uses the fixed base 31 and
/// the Mersenne prime 2^31-1 as modulus; values are always in [0, mod).
pub fn rabin_karp_hash(s: Str) -> Int {
  var h = 0;
  var i = 0;
  while i < s.len() {
    h = (h * RK_BASE + (s.char_at(i) as Int)) % RK_MOD;
    i = i + 1;
  }
  h
}

/// Rolling-hash substring search. O(n + m) expected, O(n*m) worst on hash
/// collisions. Compares character-by-character when hashes match, so results
/// are exact. Returns None when pattern is empty or longer than text.
pub fn rabin_karp_search(text: Str, pattern: Str) -> Option[Int] {
  var m = pattern.len();
  var n = text.len();
  if m == 0 || m > n { return None; }
  var p_hash = rabin_karp_hash(pattern);
  var pow = 1;
  var k = 1;
  while k < m {
    pow = (pow * RK_BASE) % RK_MOD;
    k = k + 1;
  }
  var t_hash = 0;
  var i = 0;
  while i < m {
    t_hash = (t_hash * RK_BASE + (text.char_at(i) as Int)) % RK_MOD;
    i = i + 1;
  }
  i = 0;
  while i <= n - m {
    if t_hash == p_hash {
      var matched = true;
      var j = 0;
      while j < m {
        if text.char_at(i + j) != pattern.char_at(j) {
          matched = false;
        }
        j = j + 1;
      }
      if matched {
        return Some(i);
      }
    }
    if i < n - m {
      var head = (text.char_at(i) as Int) * pow % RK_MOD;
      t_hash = t_hash - head;
      if t_hash < 0 {
        t_hash = t_hash + RK_MOD;
      }
      t_hash = (t_hash * RK_BASE + (text.char_at(i + m) as Int)) % RK_MOD;
    }
    i = i + 1;
  }
  None
}
