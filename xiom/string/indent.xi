// XIOM - String: Indent
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.indent

// Depends on: none

// ============================================================================
// Indent or remove indentation from each line of a string. NOTE: current
// implementation lives in fmt.format_indent - move the functions here during the
// implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;

// Wave 127: raw byte reads over the cached pointer -- xiom_char_at /
// string.byte_at strnlen the whole string per call, so the per-position
// scans were quadratic. Both helpers keep the previous byte-level semantics
// (this module only ever compares ASCII space / tab bytes).
// Complexity: O(1).
fn _char_at(s: Str, i: Int) -> Char
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return ((*(base + i)) as Int) as Char;
  }
}

// Masked raw byte at `pos` (see _char_at).
// Complexity: O(1).
fn _byte_at(s: Str, i: Int) -> Int
  requires: true  // raw byte read; callers bound i against the cached len (T007)
{
  unsafe {
    let base: *UInt8 = s.c_str();
    return ((*(base + i)) as Int) & 0xFF;
  }
}

// Pushes the raw bytes of `w` onto `out` (the Vec[UInt8] builder idiom).
// Wave 127: the indent builders joined their lines with str_concat per line,
// which allocates ~n^2/2 bytes for many-line inputs (strings leak by design).
// Complexity: O(|w|).
fn _push_str(out: &mut Vec[UInt8], w: Str) {
  var k: Int = 0;
  let wl = string.str_len(w);
  while k < wl {
    out.push(_byte_at(w, k) as UInt8);
    k = k + 1;
  };
}

/// Prepends the given prefix to every line of `s` (lines are separated by
/// '\n'). An indent level at or below 0 leaves `s` unchanged.
/// Complexity: O(|s| * n).
fn _prefix_lines(s: Str, prefix: Str) -> Str {
  var lines = string.str_split(s, "\n");
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      out.push(10);
    };
    var line = lines[i];
    _push_str(&mut out, prefix);
    _push_str(&mut out, line);
    i = i + 1;
  };
  Str::from_utf8(out)
}

/// Prepends `n` spaces to each line of `s`. An indent level at or below 0
/// leaves `s` unchanged; empty lines are indented too.
/// Params: s the source string; n the number of spaces per line.
/// Returns: the indented string.
/// Error case: none; n <= 0 is a no-op.
/// Complexity: O(|s| * n).
pub fn str_indent(s: Str, n: Int) -> Str {
  if n <= 0 {
    return s;
  };
  let prefix = string.str_repeat(" ", n);
  _prefix_lines(s, prefix)
}

/// Prepends `prefix` repeated `n` times to each line of `s`. An indent level
/// at or below 0 leaves `s` unchanged; empty lines are indented too.
/// Params: s the source string; n the repeat count; prefix the indentation
///         unit.
/// Returns: the indented string.
/// Error case: none; n <= 0 is a no-op.
/// Complexity: O(|s| * n * |prefix|).
pub fn str_indent_with(s: Str, n: Int, prefix: Str) -> Str {
  if n <= 0 {
    return s;
  };
  let pre = string.str_repeat(prefix, n);
  _prefix_lines(s, pre)
}

/// Removes the common leading whitespace (spaces and tabs) from all lines of
/// `s`. Lines that are empty are ignored when computing the common width; a
/// string with no common indentation is returned unchanged.
/// Params: s the source string.
/// Returns: the dedented string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_dedent(s: Str) -> Str
  requires: true  // raw-view scan in the loop (T002 confinement)
{
  var lines = string.str_split(s, "\n");
  var min_indent: Int = -1;
  var i: Int = 0;
  while i < lines.len() {
    var line = lines[i];
    let llen = string.str_len(line);
    if llen == 0 {
      i = i + 1;
      continue;
    };
    var ws: Int = 0;
    while ws < llen {
      let c = _char_at(line, ws);
      if c == ' ' || c == '\t' {
        ws = ws + 1;
      } else {
        break;
      };
    };
    if min_indent < 0 || ws < min_indent {
      min_indent = ws;
    };
    i = i + 1;
  };
  if min_indent <= 0 {
    return s;
  };
  var out: Vec[UInt8] = Vec[UInt8].new();
  i = 0;
  while i < lines.len() {
    if i > 0 {
      out.push(10);
    };
    var line = lines[i];
    let llen = string.str_len(line);
    var strip = min_indent;
    if strip > llen {
      strip = llen;
    };
    var k: Int = strip;
    while k < llen {
      out.push(_byte_at(line, k) as UInt8);
      k = k + 1;
    };
    i = i + 1;
  };
  Str::from_utf8(out)
}

/// Removes one level of indentation from each line of `s`: a leading tab, or
/// otherwise up to 4 leading spaces (fewer if the line has fewer). Lines with
/// no leading whitespace are left unchanged.
/// Params: s the source string.
/// Returns: the unindented string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_unindent(s: Str) -> Str {
  var lines = string.str_split(s, "\n");
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      out.push(10);
    };
    var line = lines[i];
    let llen = string.str_len(line);
    var pos: Int = 0;
    if pos < llen && _byte_at(line, 0) == 9 {
      pos = 1;
    } else {
      var removed: Int = 0;
      while pos < llen && removed < 4 {
        let b = _byte_at(line, pos);
        if b == 32 {
          pos = pos + 1;
          removed = removed + 1;
        } else {
          break;
        };
      };
    };
    var k: Int = pos;
    while k < llen {
      out.push(_byte_at(line, k) as UInt8);
      k = k + 1;
    };
    i = i + 1;
  };
  Str::from_utf8(out)
}
