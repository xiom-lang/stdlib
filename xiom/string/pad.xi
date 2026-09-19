// XIOM - String: Pad
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.pad

// Depends on: xiom.string

// ============================================================================
// Pad a string to a target width on the left, right, or both sides. Padding
// only uses single-byte pad characters correctly; a string already as long as
// the requested width is returned unchanged. The left/right variants delegate
// to the flat string library.
// ============================================================================

use xiom.string;

/// Pads `s` on the left with `pad` up to `width` bytes.
/// Returns `s` unchanged when `s` is already at least `width` bytes long.
/// Complexity: O(width - |s|).
pub fn str_pad_left(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  return string.str_pad_left(s, width, pad);
}

/// Pads `s` on the right with `pad` up to `width` bytes.
/// Returns `s` unchanged when `s` is already at least `width` bytes long.
/// Complexity: O(width - |s|).
pub fn str_pad_right(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  return string.str_pad_right(s, width, pad);
}

/// Pads `s` on both sides with `pad` up to `width` bytes, distributing the
/// padding so that the left side carries the extra character when the pad count
/// is odd.
/// Returns `s` unchanged when `s` is already at least `width` bytes long.
/// Complexity: O(width - |s|).
pub fn str_pad_both(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  let s_len = string.str_len(s);
  if s_len >= width {
    return s;
  };
  let total = width - s_len;
  let left = total / 2;
  let right = total - left;
  let after_left = string.str_pad_left(s, s_len + left, pad);
  return string.str_pad_right(after_left, width, pad);
}

/// Centers `s` in a field of `width` bytes using `pad`. Equivalent to
/// `str_pad_both`.
/// Returns `s` unchanged when `s` is already at least `width` bytes long.
/// Complexity: O(width - |s|).
pub fn str_center(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  str_pad_both(s, width, pad)
}

/// Alias of `str_pad_left`: pads `s` at the start with `pad` up to `width`.
/// Complexity: O(width - |s|).
pub fn str_pad_start(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  return string.str_pad_left(s, width, pad);
}

/// Alias of `str_pad_right`: pads `s` at the end with `pad` up to `width`.
/// Complexity: O(width - |s|).
pub fn str_pad_end(s: Str, width: Int, pad: Char) -> Str
  ensures: width <= s.len() => result == s
{
  return string.str_pad_right(s, width, pad);
}
