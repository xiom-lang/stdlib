// XIOM - String: Wrap
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.wrap

// Depends on: none

// ============================================================================
// Wrap a string into lines of a maximum width with hard, soft, and joined
// variants. NOTE: current implementation lives in fmt.format_wrap - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

/// Wraps `s` into lines no longer than `width` bytes (soft wrapping): words
/// are kept whole and the width is measured in bytes; a single word longer
/// than the width is hard-split to honour the limit. A width below 1 or an
/// empty input yields an empty vector.
/// Params: s the source string; width the maximum line width in bytes.
/// Returns: a Vec[Str] of wrapped lines.
/// Error case: width < 1 => empty vector.
/// Complexity: O(|s|).
pub fn str_wrap(s: Str, width: Int) -> Vec[Str] {
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  var words = string.words(s);
  var cur = "";
  var i: Int = 0;
  while i < words.len() {
    var w = words[i];
    var wlen = string.str_len(w);
    let cur_len = string.str_len(cur);
    if cur_len > 0 && cur_len + 1 + wlen > width {
      lines.push(cur);
      cur = "";
    };
    if wlen > width {
      while wlen > width {
        let chunk = string.str_slice(w, 0, width);
        lines.push(chunk);
        w = string.str_slice(w, width, wlen);
        wlen = string.str_len(w);
      };
      cur = w;
    } else {
      if string.str_len(cur) == 0 {
        cur = w;
      } else {
        cur = string.str_concat(cur, " ");
        cur = string.str_concat(cur, w);
      };
    };
    i = i + 1;
  };
  let cur_len2 = string.str_len(cur);
  if cur_len2 > 0 {
    lines.push(cur);
  };
  lines
}

/// Wraps `s` by breaking at exactly `width` bytes regardless of word
/// boundaries. A width below 1 or an empty input yields an empty vector.
/// Params: s the source string; width the chunk size in bytes.
/// Returns: a Vec[Str] of fixed-width lines (the last may be shorter).
/// Error case: width < 1 => empty vector.
/// Complexity: O(|s|).
pub fn str_wrap_hard(s: Str, width: Int) -> Vec[Str] {
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var end = i + width;
    if end > len {
      end = len;
    };
    let chunk = string.str_slice(s, i, end);
    lines.push(chunk);
    i = end;
  };
  lines
}

/// Wraps `s` at word boundaries without ever splitting a word: words are
/// packed greedily and a word longer than `width` becomes its own line.
/// A width below 1 or an empty input yields an empty vector.
/// Params: s the source string; width the maximum line width in bytes.
/// Returns: a Vec[Str] of wrapped lines.
/// Error case: width < 1 => empty vector.
/// Complexity: O(|s|).
pub fn str_wrap_soft(s: Str, width: Int) -> Vec[Str] {
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  var words = string.words(s);
  var cur = "";
  var i: Int = 0;
  while i < words.len() {
    var w = words[i];
    let cur_len = string.str_len(cur);
    if cur_len == 0 {
      cur = w;
    } else {
      let w_len = string.str_len(w);
      if cur_len + 1 + w_len <= width {
        cur = string.str_concat(cur, " ");
        cur = string.str_concat(cur, w);
      } else {
        lines.push(cur);
        cur = w;
      };
    };
    i = i + 1;
  };
  let cur_len2 = string.str_len(cur);
  if cur_len2 > 0 {
    lines.push(cur);
  };
  lines
}

/// Wraps `s` with str_wrap and joins the resulting lines with `sep`.
/// A width below 1 yields the empty string.
/// Params: s the source string; width the maximum line width in bytes;
///         sep the line separator.
/// Returns: the wrapped lines joined by `sep`.
/// Error case: width < 1 => "".
/// Complexity: O(|s|).
pub fn str_wrap_join(s: Str, width: Int, sep: Str) -> Str {
  var lines = str_wrap(s, width);
  var result = "";
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      result = string.str_concat(result, sep);
    };
    var line = lines[i];
    result = string.str_concat(result, line);
    i = i + 1;
  };
  result
}
