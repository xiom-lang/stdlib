// XIOM - String: Line Accessors
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.lines

// Depends on: xiom.string (materializing slices only)

// ============================================================================
// Allocation-free line accessors (2026-10-01 intake row 2; requesters
// consensus / macro / legacy-proto -- line scanners over large inputs).
// Lines are byte ranges [start, end) over the source Str; the terminator byte
// is excluded. Splitting semantics match string.lines()/str_split(s, "\n"):
// an empty source has one empty line and a trailing newline opens one final
// empty line. The byte-range accessors allocate nothing; `c_str()` is bound
// once per call and the cursor carries the cached (base, len) view for
// iteration. CR is a normal line byte (split semantics; strip it at the call
// site when the input may be CRLF).
// ============================================================================

use xiom.string;

// Raw byte at `i` over a cached pointer (T007 confinement; callers bound i).
fn _lines_raw(base: *UInt8, i: Int) -> UInt8
  requires: true
{
  unsafe { return *(base + i); }
}

/// Iteration cursor over the lines of a Str: `base`/`len` cache the source
/// view, `pos` is the next line's start byte, `line` is the 0-based index of
/// the next line (equal to the number of lines already yielded).
pub type LineCursor = { base: *UInt8; len: Int; pos: Int; line: Int; }

/// New cursor over the lines of `s`. Complexity: O(1).
pub fn lines_new(s: Str) -> LineCursor
  requires: true  // c_str() read confined to the cursor fields (T007)
  ensures: result.len == s.len()
  ensures: result.pos == 0
  ensures: result.line == 0
{
  unsafe {
    return LineCursor{ base: s.c_str(), len: s.len(), pos: 0, line: 0 };
  }
}

/// Number of lines: newline count + 1 (matches str_split(s, "\n")). O(n).
pub fn lines_count(s: Str) -> Int
  ensures: result >= 1
{
  let len = s.len();
  let base = s.c_str();
  var count = 1;
  var i = 0;
  while i < len {
    if _lines_raw(base, i) == 10 {
      count = count + 1;
    };
    i = i + 1;
  };
  count
}

/// Byte offsets of every newline byte, in source order. Complexity: O(n).
pub fn lines_newline_index(s: Str) -> Vec[Int] {
  var result = Vec[Int].new();
  let len = s.len();
  let base = s.c_str();
  var i = 0;
  while i < len {
    if _lines_raw(base, i) == 10 {
      result.push(i);
    };
    i = i + 1;
  };
  result
}

/// Byte range [start, end) of line `idx` (terminator excluded), or None when
/// `idx` is negative or >= lines_count. Allocates nothing.
/// Complexity: O(start of line idx) -- one forward pass.
pub fn lines_span(s: Str, idx: Int) -> Option[(Int, Int)] {
  if idx < 0 {
    return None;
  };
  let len = s.len();
  let base = s.c_str();
  var line = 0;
  var start = 0;
  var i = 0;
  while i < len {
    if _lines_raw(base, i) == 10 {
      if line == idx {
        return Some((start, i));
      };
      line = line + 1;
      start = i + 1;
    };
    i = i + 1;
  };
  if line == idx {
    return Some((start, len));
  };
  None
}

/// Next line range; advances the cursor. None once all lines were yielded.
/// Complexity: O(line length) -- the cursor never rescans the source.
pub fn lines_next(c: &mut LineCursor) -> Option[(Int, Int)] {
  let start = c.pos;
  if start > c.len {
    return None;
  };
  var i = start;
  while i < c.len && _lines_raw(c.base, i) != 10 {
    i = i + 1;
  };
  c.pos = i + 1;
  c.line = c.line + 1;
  Some((start, i))
}

/// Materializing form of lines_span: a copied Str for line `idx`, or None.
/// Complexity: O(start of line idx + line length).
pub fn lines_slice(s: Str, idx: Int) -> Option[Str] {
  let span = lines_span(s, idx);
  match span {
    Some(range) => {
      return Some(string.str_slice(s, range.0, range.1));
    },
    None => {
      return None;
    },
  }
}
