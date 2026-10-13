// XIOM - String: Strip
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.strip

// Depends on: xiom.string, xiom.char

// ============================================================================
// Strip a prefix or suffix and remove whitespace or control characters. The
// prefix/suffix variants delegate to the flat string library; the whitespace
// and control variants are implemented here.
// ============================================================================

use xiom.string;

// Returns the raw byte at byte index `i` of `s`, as a Char (the historical
// byte-level semantics: multi-byte leads are not decoded here).
// Precondition: 0 <= i < s.len().
// Wave 128: raw read over the cached pointer -- string.byte_at strnlens the
// whole string per call, so the per-position scans were quadratic.
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return (((*(base + i)) as Int) & 0xFF) as Char;
  }
}

// Raw byte at byte index `i` of `s` (see _char_at).
// Complexity: O(1).
fn _raw_byte(s: Str, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return *(base + i);
  }
}

/// If `s` starts with `prefix`, returns `Some(s without the prefix)`.
/// Returns `None` when `s` does not start with `prefix`.
/// Complexity: O(|prefix|).
pub fn str_strip_prefix(s: Str, prefix: Str) -> Option[Str] {
  return string.str_strip_prefix(s, prefix);
}

/// If `s` ends with `suffix`, returns `Some(s without the suffix)`.
/// Returns `None` when `s` does not end with `suffix`.
/// Complexity: O(|suffix|).
pub fn str_strip_suffix(s: Str, suffix: Str) -> Option[Str] {
  return string.str_strip_suffix(s, suffix);
}

/// Removes all whitespace characters from `s`.
/// Returns a new string no longer than `s`.
/// Complexity: O(|s|).
pub fn str_strip_whitespace(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if !xiom.char.is_whitespace(c) {
      var k: Int = 0;
      while k < bl && i + k < len {
        out.push(_raw_byte(s, i + k));
        k = k + 1;
      };
    };
    i = i + bl;
  };
  Str::from_utf8(out)
}

/// Removes all control characters from `s`.
/// Returns a new string no longer than `s`.
/// Complexity: O(|s|).
pub fn str_strip_control(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _char_at(s, i);
    let bl = xiom.char.len_utf8(c);
    if !xiom.char.is_control(c) {
      var k: Int = 0;
      while k < bl && i + k < len {
        out.push(_raw_byte(s, i + k));
        k = k + 1;
      };
    };
    i = i + bl;
  };
  Str::from_utf8(out)
}
