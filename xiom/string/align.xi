// XIOM - String: Align
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.align

// Depends on: none

// ============================================================================
// Align a string within a fixed width: left, right, center, or justified.
// NOTE: current implementation lives in fmt.format_align_left/right - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Left-aligns `s` in a field of `width` bytes, padding on the right with
/// spaces. A string already at or over the width is returned unchanged; a
/// negative width is rejected (returns `s`).
/// Params: s the source string; width the field width in bytes.
/// Returns: the left-aligned string.
/// Error case: none; width < 0 is a no-op.
/// Complexity: O(width).
pub fn str_align_left(s: Str, width: Int) -> Str {
  if width < 0 {
    return s;
  };
  string.str_pad_right(s, width, ' ')
}

/// Right-aligns `s` in a field of `width` bytes, padding on the left with
/// spaces. A string already at or over the width is returned unchanged; a
/// negative width is rejected (returns `s`).
/// Params: s the source string; width the field width in bytes.
/// Returns: the right-aligned string.
/// Error case: none; width < 0 is a no-op.
/// Complexity: O(width).
pub fn str_align_right(s: Str, width: Int) -> Str {
  if width < 0 {
    return s;
  };
  string.str_pad_left(s, width, ' ')
}

/// Centers `s` in a field of `width` bytes, padding both sides with spaces;
/// when the padding does not split evenly the extra space goes on the right.
/// A string already at or over the width is returned unchanged; a negative
/// width is rejected (returns `s`).
/// Params: s the source string; width the field width in bytes.
/// Returns: the centered string.
/// Error case: none; width < 0 is a no-op.
/// Complexity: O(width).
pub fn str_align_center(s: Str, width: Int) -> Str {
  if width < 0 {
    return s;
  };
  string.str_center(s, width)
}

/// Justifies `s` to `width` bytes by distributing the extra space between the
/// words: gaps are padded from left to right, so earlier gaps may receive one
/// extra space. When there is only one word, or the words already fill the
/// width, or `width` is negative, `s` is returned unchanged.
/// Params: s the source string; width the target width in bytes.
/// Returns: the justified string.
/// Error case: none; width < 0 is a no-op.
/// Complexity: O(|s| + width).
pub fn str_align_justify(s: Str, width: Int) -> Str {
  if width < 0 {
    return s;
  };
  var words = string.words(s);
  let wcount = words.len();
  if wcount == 0 {
    return s;
  };
  var total_len: Int = 0;
  var i: Int = 0;
  while i < wcount {
    var wi = words[i];
    let wi_len = string.str_len(wi);
    total_len = total_len + wi_len;
    i = i + 1;
  };
  if wcount == 1 {
    var w0 = words[0];
    return string.str_pad_right(w0, width, ' ');
  };
  if total_len + (wcount - 1) >= width {
    return s;
  };
  let gaps = wcount - 1;
  let extra = width - total_len;
  let base = extra / gaps;
  let rem = extra % gaps;
  var result = "";
  i = 0;
  while i < wcount {
    if i > 0 {
      var gap = base;
      if i <= rem {
        gap = base + 1;
      };
      var g: Int = 0;
      while g < gap {
        result = string.str_concat(result, " ");
        g = g + 1;
      };
    };
    var wi = words[i];
    result = string.str_concat(result, wi);
    i = i + 1;
  };
  result
}
