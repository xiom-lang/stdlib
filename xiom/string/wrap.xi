// XIOM - String: Wrap
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.wrap

// Depends on: none

// ============================================================================
// Wrap a string into lines of a maximum width with hard, soft, and joined
// variants. NOTE: current implementation lives in fmt.format_wrap - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Raw byte at `i` (wave 130: cached raw pointer -- string.byte_at strnlens
// the whole string per call).
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Appends the bytes of `w` onto `out` (the Vec[UInt8] builder idiom).
// Complexity: O(|w|).
fn _push_str(out: &mut Vec[UInt8], w: Str) {
  var k: Int = 0;
  let wl = string.str_len(w);
  let base = w.c_str();
  while k < wl {
    out.push(_raw_byte(base, k));
    k = k + 1;
  };
}

// Slice [start, end) over a cached pointer WITHOUT the str_len clamp
// (wave 130): str_slice rescans the source per call (strlen), so per-chunk
// slices were O(|s|) each. Callers guarantee 0 <= start <= end <= len.
// Complexity: O(end - start).
fn _slice_fast(base: *UInt8, start: Int, end: Int) -> Str
  requires: true  // raw byte copy; callers bound the range (T007)
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  unsafe {
    var i: Int = start;
    while i < end {
      out.push(*(base + i));
      i = i + 1;
    };
  };
  Str::from_utf8(out)
}

/// Wraps `s` into lines no longer than `width` bytes (soft wrapping): words
/// are kept whole and the width is measured in bytes; a single word longer
/// than the width is hard-split to honour the limit. A width below 1 or an
/// empty input yields an empty vector.
/// Params: s the source string; width the maximum line width in bytes.
/// Returns: a Vec[Str] of wrapped lines.
/// Error case: width < 1 => empty vector.
/// Complexity: O(|s|).
pub fn str_wrap(s: Str, width: Int) -> Vec[Str]
  ensures: width < 1 => result.len() == 0
{
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  var words = string.words(s);
  var cur: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < words.len() {
    var w = words[i];
    var wlen = string.str_len(w);
    if cur.len() > 0 && cur.len() + 1 + wlen > width {
      lines.push(Str::from_utf8(cur));
      cur = Vec[UInt8].new();
    };
    if wlen > width {
      while wlen > width {
        let chunk = string.str_slice(w, 0, width);
        lines.push(chunk);
        w = string.str_slice(w, width, wlen);
        wlen = string.str_len(w);
      };
      cur = Vec[UInt8].new();
      _push_str(&mut cur, w);
    } else {
      if cur.len() == 0 {
        _push_str(&mut cur, w);
      } else {
        cur.push(32);
        _push_str(&mut cur, w);
      };
    };
    i = i + 1;
  };
  if cur.len() > 0 {
    lines.push(Str::from_utf8(cur));
  };
  lines
}

/// Wraps `s` by breaking at exactly `width` bytes regardless of word
/// boundaries. A width below 1 or an empty input yields an empty vector.
/// Params: s the source string; width the chunk size in bytes.
/// Returns: a Vec[Str] of fixed-width lines (the last may be shorter).
/// Error case: width < 1 => empty vector.
/// Complexity: O(|s|).
pub fn str_wrap_hard(s: Str, width: Int) -> Vec[Str]
  ensures: width < 1 => result.len() == 0
{
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  let len = string.str_len(s);
  let base = s.c_str();
  var i: Int = 0;
  while i < len {
    var end = i + width;
    if end > len {
      end = len;
    };
    let chunk = _slice_fast(base, i, end);
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
pub fn str_wrap_soft(s: Str, width: Int) -> Vec[Str]
  ensures: width < 1 => result.len() == 0
{
  var lines = Vec[Str].new();
  if width < 1 {
    return lines;
  };
  var words = string.words(s);
  var cur: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < words.len() {
    var w = words[i];
    if cur.len() == 0 {
      _push_str(&mut cur, w);
    } else {
      let w_len = string.str_len(w);
      if cur.len() + 1 + w_len <= width {
        cur.push(32);
        _push_str(&mut cur, w);
      } else {
        lines.push(Str::from_utf8(cur));
        cur = Vec[UInt8].new();
        _push_str(&mut cur, w);
      };
    };
    i = i + 1;
  };
  if cur.len() > 0 {
    lines.push(Str::from_utf8(cur));
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
pub fn str_wrap_join(s: Str, width: Int, sep: Str) -> Str
  ensures: width < 1 => result.len() == 0
{
  var lines = str_wrap(s, width);
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      _push_str(&mut out, sep);
    };
    var line = lines[i];
    _push_str(&mut out, line);
    i = i + 1;
  };
  Str::from_utf8(out)
}
