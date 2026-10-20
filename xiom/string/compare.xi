// XIOM - String: Compare
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.compare

// Depends on: none

// ============================================================================
// Lexicographic and equality comparison of strings, including case-insensitive
// and natural (numeric-aware) ordering. The canonical byte-wise comparison is
// `xiom.string.str_compare` (exposed on the parent module so `use xiom.string;`
// resolves it); this module delegates to it and implements the
// case-insensitive / natural variants.
// ============================================================================

use xiom.string;

// Wave 125: raw byte access over a cached (base, len) view (the wave-111
// pattern): xiom.byte_at re-scans with strnlen per call, so byte-stepped
// loops were quadratic in the string size. Callers bounds-check against the
// cached length.
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

/// Lexicographic byte-wise comparison of `a` and `b`.
/// Returns a negative Int when `a` sorts before `b`, 0 when equal, and a
/// positive Int when `a` sorts after `b`. Canonical implementation:
/// `xiom.string.str_compare`; this wrapper keeps the `xiom.string.compare`
/// path working for existing importers.
/// Params: a, b the strings to compare.
/// Returns: negative/zero/positive.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn str_compare(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  string.str_compare(a, b)
}

/// Case-insensitive lexicographic comparison of `a` and `b`.
/// ASCII uppercase letters are folded to lowercase before each byte comparison;
/// all other bytes compare unchanged. The sign of the result follows
/// str_compare: negative when `a < b`, zero when equal, positive when `a > b`.
/// Params: a, b the strings to compare.
/// Returns: negative/zero/positive.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn str_compare_ignore_case(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  let la = string.str_len(a);
  let lb = string.str_len(b);
  let pa = a.c_str();
  let pb = b.c_str();
  var i: Int = 0;
  while i < la && i < lb {
    var ba = _raw_byte(pa, i) as Int;
    var bb = _raw_byte(pb, i) as Int;
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
pub fn str_compare_natural(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  let la = string.str_len(a);
  let lb = string.str_len(b);
  let pa = a.c_str();
  let pb = b.c_str();
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
    let ba = _raw_byte(pa, i) as Int;
    let bb = _raw_byte(pb, j) as Int;
    let a_is_digit = ba >= 48 && ba <= 57;
    let b_is_digit = bb >= 48 && bb <= 57;
    if a_is_digit && b_is_digit {
      var i_end = i;
      while i_end < la {
        let c = _raw_byte(pa, i_end) as Int;
        if !(c >= 48 && c <= 57) {
          break;
        };
        i_end = i_end + 1;
      };
      var j_end = j;
      while j_end < lb {
        let c = _raw_byte(pb, j_end) as Int;
        if !(c >= 48 && c <= 57) {
          break;
        };
        j_end = j_end + 1;
      };
      var a_start = i;
      while a_start < i_end - 1 && (_raw_byte(pa, a_start) as Int) == 48 {
        a_start = a_start + 1;
      };
      var b_start = j;
      while b_start < j_end - 1 && (_raw_byte(pb, b_start) as Int) == 48 {
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
        let ca = _raw_byte(pa, a_start + k) as Int;
        let cb = _raw_byte(pb, b_start + k) as Int;
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
pub fn str_eq_ignore_case(a: Str, b: Str) -> Bool
  ensures: result => a.len() == b.len()  // equal ordering requires equal lengths
{
  str_compare_ignore_case(a, b) == 0
}
