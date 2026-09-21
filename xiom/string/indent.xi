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

extern "C" {
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Prepends the given prefix to every line of `s` (lines are separated by
/// '\n'). An indent level at or below 0 leaves `s` unchanged.
/// Complexity: O(|s| * n).
fn _prefix_lines(s: Str, prefix: Str) -> Str {
  var lines = string.str_split(s, "\n");
  var result = "";
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      result = string.str_concat(result, "\n");
    };
    var line = lines[i];
    result = string.str_concat(result, prefix);
    result = string.str_concat(result, line);
    i = i + 1;
  };
  result
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
  requires: true  // extern char_at call in the scan loop (T002 confinement)
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
      let c = xiom_char_at(line, ws);
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
  var result = "";
  i = 0;
  while i < lines.len() {
    if i > 0 {
      result = string.str_concat(result, "\n");
    };
    var line = lines[i];
    let llen = string.str_len(line);
    var strip = min_indent;
    if strip > llen {
      strip = llen;
    };
    let rest = string.str_slice(line, strip, llen);
    result = string.str_concat(result, rest);
    i = i + 1;
  };
  result
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
  var result = "";
  var i: Int = 0;
  while i < lines.len() {
    if i > 0 {
      result = string.str_concat(result, "\n");
    };
    var line = lines[i];
    let llen = string.str_len(line);
    var pos: Int = 0;
    if pos < llen && (string.byte_at(line, 0) as Int) == 9 {
      pos = 1;
    } else {
      var removed: Int = 0;
      while pos < llen && removed < 4 {
        let b = (string.byte_at(line, pos) as Int) & 0xFF;
        if b == 32 {
          pos = pos + 1;
          removed = removed + 1;
        } else {
          break;
        };
      };
    };
    let rest = string.str_slice(line, pos, llen);
    result = string.str_concat(result, rest);
    i = i + 1;
  };
  result
}
