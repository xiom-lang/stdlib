// XIOM - String: Compare
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.compare

// Depends on: none

// ============================================================================
// Lexicographic and equality comparison of strings, including case-insensitive
// and natural (numeric-aware) ordering. NOTE: current implementation lives in
// cmp + string - move the functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Lexicographic byte-wise comparison of `a` and `b`.
/// Returns a negative Int when `a` sorts before `b`, 0 when equal, and a
/// positive Int when `a` sorts after `b`. Comparison is byte-by-byte over the
/// UTF-8 representation, so the ordering matches Unicode code-point order only
/// for ASCII inputs; multi-byte sequences compare by their raw bytes.
/// Params: a, b the strings to compare.
/// Returns: negative/zero/positive.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn str_compare(a: Str, b: Str) -> Int {
  let la = string.str_len(a);
  let lb = string.str_len(b);
  var i: Int = 0;
  while i < la && i < lb {
    let ba = string.byte_at(a, i) as Int;
    let bb = string.byte_at(b, i) as Int;
    if ba < bb {
      return -1;
    };
    if ba > bb {
      return 1;
    };
    i = i + 1;
  };
  if la < lb {
    return -1;
  };
  if la > lb {
    return 1;
  };
  0
}

/// Case-insensitive lexicographic comparison of `a` and `b`.
/// ASCII uppercase letters are folded to lowercase before each byte comparison;
/// all other bytes compare unchanged. The sign of the result follows
/// str_compare: negative when `a < b`, zero when equal, positive when `a > b`.
/// Params: a, b the strings to compare.
/// Returns: negative/zero/positive.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn str_compare_ignore_case(a: Str, b: Str) -> Int {
  let la = string.str_len(a);
  let lb = string.str_len(b);
  var i: Int = 0;
  while i < la && i < lb {
    var ba = string.byte_at(a, i) as Int;
    var bb = string.byte_at(b, i) as Int;
    if ba >= 65 && ba <= 90 {
      ba = ba + 32;
    };
    if bb >= 65 && bb <= 90 {
      bb = bb + 32;
    };
    if ba < bb {
      return -1;
    };
    if ba > bb {
      return 1;
    };
    i = i + 1;
  };
  if la < lb {
    return -1;
  };
  if la > lb {
    return 1;
  };
  0
}

/// Natural-order comparison of `a` and `b`: runs of ASCII digits are compared
/// by their numeric value, so "x2" sorts before "x10". Between digit runs the
/// comparison is byte-wise lexicographic, and equal-length numeric runs break
/// ties by leading-zero count (fewer zeros sorts first).
/// Params: a, b the strings to compare.
/// Returns: negative/zero/positive.
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn str_compare_natural(a: Str, b: Str) -> Int {
  let la = string.str_len(a);
  let lb = string.str_len(b);
  var i: Int = 0;
  var j: Int = 0;
  loop {
    if i >= la && j >= lb {
      return 0;
    };
    if i >= la {
      return -1;
    };
    if j >= lb {
      return 1;
    };
    let ba = string.byte_at(a, i) as Int;
    let bb = string.byte_at(b, j) as Int;
    let a_is_digit = ba >= 48 && ba <= 57;
    let b_is_digit = bb >= 48 && bb <= 57;
    if a_is_digit && b_is_digit {
      var i_end = i;
      while i_end < la {
        let c = string.byte_at(a, i_end) as Int;
        if !(c >= 48 && c <= 57) {
          break;
        };
        i_end = i_end + 1;
      };
      var j_end = j;
      while j_end < lb {
        let c = string.byte_at(b, j_end) as Int;
        if !(c >= 48 && c <= 57) {
          break;
        };
        j_end = j_end + 1;
      };
      var a_start = i;
      while a_start < i_end - 1 && (string.byte_at(a, a_start) as Int) == 48 {
        a_start = a_start + 1;
      };
      var b_start = j;
      while b_start < j_end - 1 && (string.byte_at(b, b_start) as Int) == 48 {
        b_start = b_start + 1;
      };
      let a_digits = i_end - a_start;
      let b_digits = j_end - b_start;
      if a_digits < b_digits {
        return -1;
      };
      if a_digits > b_digits {
        return 1;
      };
      var k: Int = 0;
      while k < a_digits {
        let ca = string.byte_at(a, a_start + k) as Int;
        let cb = string.byte_at(b, b_start + k) as Int;
        if ca < cb {
          return -1;
        };
        if ca > cb {
          return 1;
        };
        k = k + 1;
      };
      let a_lead = a_start - i;
      let b_lead = b_start - j;
      if a_lead < b_lead {
        return -1;
      };
      if a_lead > b_lead {
        return 1;
      };
      i = i_end;
      j = j_end;
    } else {
      if ba < bb {
        return -1;
      };
      if ba > bb {
        return 1;
      };
      i = i + 1;
      j = j + 1;
    };
  };
}

/// Returns true when `a` equals `b` ignoring ASCII letter case.
/// Params: a, b the strings to compare.
/// Returns: true when they compare equal under str_compare_ignore_case.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn str_eq_ignore_case(a: Str, b: Str) -> Bool {
  str_compare_ignore_case(a, b) == 0
}
