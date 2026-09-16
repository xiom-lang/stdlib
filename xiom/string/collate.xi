// XIOM - String: Collate
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.collate

// Depends on: xiom.string

// ============================================================================
// Locale-aware collation: comparison and collation key generation. NOTE: current
// implementation lives in TODO - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.misc;
use xiom.convert;

/// Compare `a` and `b` in byte-wise collation order.
/// Returns a negative Int when `a` sorts before `b`, zero when the strings are
/// byte-identical, and a positive Int when `a` sorts after `b`. Bytes are
/// compared unsigned, so bytes above 0x7F sort after ASCII on every platform.
/// Params: a, b the strings to compare.
/// Returns: negative / zero / positive per the byte-wise ordering of a vs b.
/// Error case: none.
/// Complexity: O(min(|a|, |b|)).
pub fn collate_compare(a: Str, b: Str) -> Int
  ensures: result >= -1 && result <= 1
{
  let alen = a.len();
  let blen = b.len();
  var n = alen;
  if blen < n {
    n = blen;
  };
  var i: Int = 0;
  while i < n {
    let ab = (string.byte_at(a, i) as Int) & 0xFF;
    let bb = (string.byte_at(b, i) as Int) & 0xFF;
    if ab < bb {
      return -1;
    };
    if ab > bb {
      return 1;
    };
    i = i + 1;
  };
  if alen < blen {
    return -1;
  };
  if alen > blen {
    return 1;
  };
  0
}

/// Compare `a` and `b` in natural collation order: embedded runs of ASCII
/// digits are compared numerically rather than byte-wise, so "file2" sorts
/// before "file10". Delegates to the proven natural-order comparator.
/// Params: a, b the strings to compare.
/// Returns: negative / zero / positive per the natural ordering of a vs b.
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn collate_compare_numeric(a: Str, b: Str) -> Int {
  let r = misc.natural_compare(a, b);
  r
}

/// Collation key of `s`: an ASCII-case-folded copy such that comparing two
/// keys with `collate_compare` reproduces the case-insensitive collation order
/// of the original strings. Bytes above 0x7F pass through unchanged.
/// Params: s the string to key.
/// Returns: a key string whose byte-wise order matches the collation order.
/// Error case: none.
/// Complexity: O(|s|).
pub fn collate_key(s: Str) -> Str
  ensures: result.len() == s.len()
{
  let len = s.len();
  if len == 0 {
    return "";
  };
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let b = (string.byte_at(s, i) as Int) & 0xFF;
    var ch = b;
    if b >= 65 && b <= 90 {
      ch = b + 32;
    };
    out.push(ch as UInt8);
    i = i + 1;
  };
  out.push(0);
  unsafe {
    Str.from_cstring(out.data)
  }
}
