// XIOM - String: Glob
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.glob

// Depends on: none

// ============================================================================
// Glob pattern matching with wildcards, case-sensitive and case-insensitive.
// NOTE: current implementation lives in misc.glob_match - move the functions
// here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// ASCII-lowercase copy of `s`: 'A'..'Z' fold to lowercase, all other bytes
// pass through unchanged.
// Complexity: O(|s|).
fn _ascii_lower(s: Str) -> Str {
  let len = string.str_len(s);
  if len == 0 {
    return "";
  };
  var out = Vec[UInt8].new();
  var i: Int = 0;
  while i < len {
    let b = _byte(s, i);
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

/// Match `s` against the glob `pattern`. Supported wildcards:
///   '?' matches exactly one byte;
///   '*' matches zero or more bytes (greedy, backtracking match).
/// Every other byte must match literally.
/// Params: pattern the glob pattern; s the string to test.
/// Returns: true when `s` matches `pattern`.
/// Error case: none.
/// Complexity: O(|pattern| * |s|) worst case, linear on typical patterns.
pub fn glob_match(pattern: Str, s: Str) -> Bool {
  let plen = string.str_len(pattern);
  let tlen = string.str_len(s);
  var pi: Int = 0;
  var ti: Int = 0;
  var star_idx: Int = -1;
  var match_idx: Int = 0;
  while ti < tlen {
    if pi < plen && _byte(pattern, pi) == 42 {
      star_idx = pi;
      match_idx = ti;
      pi = pi + 1;
    } elif pi < plen && (_byte(pattern, pi) == 63 || _byte(pattern, pi) == _byte(s, ti)) {
      pi = pi + 1;
      ti = ti + 1;
    } elif star_idx >= 0 {
      pi = star_idx + 1;
      match_idx = match_idx + 1;
      ti = match_idx;
    } else {
      return false;
    };
  };
  while pi < plen && _byte(pattern, pi) == 42 {
    pi = pi + 1;
  };
  pi == plen
}

/// Match `s` against the glob `pattern`, ignoring ASCII letter case. The
/// pattern and the input are ASCII-lowercased before the same wildcard
/// matching as `glob_match` runs. Bytes above 0x7F match byte-exactly.
/// Params: pattern the glob pattern; s the string to test.
/// Returns: true when `s` matches `pattern` case-insensitively.
/// Error case: none.
/// Complexity: O(|pattern| * |s|) worst case after O(|pattern| + |s|)
///             lowercasing.
pub fn glob_match_case_insensitive(pattern: Str, s: Str) -> Bool {
  let pl = _ascii_lower(pattern);
  let sl = _ascii_lower(s);
  let r = glob_match(pl, sl);
  r
}
