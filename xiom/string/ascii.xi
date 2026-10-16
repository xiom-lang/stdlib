// XIOM - String: ASCII Byte Classifiers
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.ascii

// Depends on: none

// ============================================================================
// Byte-domain ASCII predicates (2026-10-01 intake row 35; requesters elastic,
// chef, translate, cfn; xml2 needs the byte-set helper). Inputs are bytes
// widened to Int -- pass `byte_at`/`byte as Int` directly; only the low 8
// bits are inspected, so unscaled widenings (sign-extended or not) classify
// the raw byte. Char-domain predicates live in xiom.char; these exist for
// scanners that stay byte-oriented. Complexity: O(1) each except the
// byte-set scan (O(|set|)).
// ============================================================================

/// True iff the low byte is an ASCII decimal digit (0x30-0x39).
pub fn ascii_is_digit(b: Int) -> Bool {
  let v = b & 0xFF;
  v >= 48 && v <= 57
}

/// True iff the low byte is an ASCII uppercase letter (A-Z).
pub fn ascii_is_upper(b: Int) -> Bool {
  let v = b & 0xFF;
  v >= 65 && v <= 90
}

/// True iff the low byte is an ASCII lowercase letter (a-z).
pub fn ascii_is_lower(b: Int) -> Bool {
  let v = b & 0xFF;
  v >= 97 && v <= 122
}

/// True iff the low byte is an ASCII letter (A-Z or a-z).
pub fn ascii_is_alpha(b: Int) -> Bool {
  let v = b & 0xFF;
  (v >= 65 && v <= 90) || (v >= 97 && v <= 122)
}

/// True iff the low byte is an ASCII letter or decimal digit.
pub fn ascii_is_alnum(b: Int) -> Bool {
  let v = b & 0xFF;
  (v >= 48 && v <= 57) || (v >= 65 && v <= 90) || (v >= 97 && v <= 122)
}

/// True iff the low byte is C whitespace (space, \t, \n, \v, \f, \r).
pub fn ascii_is_space(b: Int) -> Bool {
  let v = b & 0xFF;
  v == 32 || (v >= 9 && v <= 13)
}

/// True iff the low byte is an ASCII blank (space or \t).
pub fn ascii_is_blank(b: Int) -> Bool {
  let v = b & 0xFF;
  v == 32 || v == 9
}

/// True iff the low byte is a hex digit (0-9, a-f, A-F).
pub fn ascii_is_hex(b: Int) -> Bool {
  let v = b & 0xFF;
  (v >= 48 && v <= 57) || (v >= 97 && v <= 102) || (v >= 65 && v <= 70)
}

/// True iff the low byte is an ASCII control code (0x00-0x1F or 0x7F).
pub fn ascii_is_control(b: Int) -> Bool {
  let v = b & 0xFF;
  v <= 31 || v == 127
}

/// True iff the low byte is printable ASCII (0x20-0x7E).
pub fn ascii_is_printable(b: Int) -> Bool {
  let v = b & 0xFF;
  v >= 32 && v <= 126
}

/// True iff the low byte occurs in the byte set `set` (raw byte membership;
/// e.g. ascii_in_set(59, ";,") is true). Complexity: O(|set|).
pub fn ascii_in_set(b: Int, set: Str) -> Bool {
  let v = b & 0xFF;
  let len = set.len();
  let base = set.c_str();
  var i = 0;
  while i < len {
    let sbyte = (_ascii_raw(base, i) as Int) & 0xFF;
    if sbyte == v {
      return true;
    };
    i = i + 1;
  };
  false
}

/// ASCII uppercase mapping: a-z map to A-Z, every other byte unchanged.
pub fn ascii_upper_byte(b: Int) -> Int {
  let v = b & 0xFF;
  if v >= 97 && v <= 122 {
    return v - 32;
  };
  v
}

/// ASCII lowercase mapping: A-Z map to a-z, every other byte unchanged.
pub fn ascii_lower_byte(b: Int) -> Int {
  let v = b & 0xFF;
  if v >= 65 && v <= 90 {
    return v + 32;
  };
  v
}

// Raw byte at `i` over a cached pointer (T007 confinement; callers bound i).
fn _ascii_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}
