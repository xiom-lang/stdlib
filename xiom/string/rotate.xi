// XIOM - String: Rotate
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.string.rotate

// Depends on: none

// ============================================================================
// Rotate a string by a number of positions, left or right. NOTE: current
// implementation lives in string.combinatorics stub - move the functions here
// during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Normalized rotation amount: in [0, |s|), so a rotation by |s| is a no-op and
// negative amounts rotate the other way. Empty input keeps 0.
// Complexity: O(1).
fn _norm(n: Int, len: Int) -> Int {
  if len == 0 {
    return 0;
  };
  var k = n % len;
  if k < 0 {
    k = k + len;
  };
  k
}

/// Rotate `s` right by `n` byte positions: a positive `n` moves characters
/// toward the end of the string ("abcde" rotated right by 2 is "deabc").
/// A negative `n` rotates left. Rotating by a multiple of |s| returns `s`.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate(s: Str, n: Int) -> Str {
  let len = string.str_len(s);
  let k = _norm(n, len);
  if len == 0 || k == 0 {
    return s;
  };
  let cut = len - k;
  let head = string.str_slice(s, 0, cut);
  let tail = string.str_slice(s, cut, len);
  let r = string.str_concat(tail, head);
  r
}

/// Rotate `s` left by `n` byte positions ("abcde" rotated left by 2 is
/// "cdeab"). A negative `n` rotates right.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate_left(s: Str, n: Int) -> Str {
  let len = string.str_len(s);
  let k = _norm(n, len);
  if len == 0 || k == 0 {
    return s;
  };
  let head = string.str_slice(s, k, len);
  let tail = string.str_slice(s, 0, k);
  let r = string.str_concat(head, tail);
  r
}

/// Rotate `s` right by `n` byte positions; identical to `str_rotate` and kept
/// as the explicit right-rotation entry point.
/// Params: s the string to rotate; n the rotation amount in bytes.
/// Returns: the rotated string.
/// Error case: none; the empty string is returned unchanged.
/// Complexity: O(|s|).
pub fn str_rotate_right(s: Str, n: Int) -> Str {
  let r = str_rotate(s, n);
  r
}
