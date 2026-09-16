// XIOM - String: Interleave
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.string.interleave

// Depends on: none

// ============================================================================
// Merge strings by alternating characters or interleave multiple parts.
// NOTE: current implementation lives in string.combinatorics stub - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.char;

extern "C" {
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// Merges `a` and `b` by alternating their characters: the characters of `a`
/// and `b` are taken one at a time in turn; once the shorter string is
/// exhausted the remainder of the longer string is appended.
/// Params: a, b the strings to merge.
/// Returns: the interleaved string.
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn str_interleave(a: Str, b: Str) -> Str
  requires: true  // extern char_at calls in the loop (T002 confinement)
{
  let la = string.str_len(a);
  let lb = string.str_len(b);
  var ia: Int = 0;
  var ib: Int = 0;
  var result = "";
  while ia < la && ib < lb {
    let ca = xiom_char_at(a, ia);
    let bl_a = char.len_utf8(ca);
    let piece_a = string.str_slice(a, ia, ia + bl_a);
    result = string.str_concat(result, piece_a);
    ia = ia + bl_a;
    let cb = xiom_char_at(b, ib);
    let bl_b = char.len_utf8(cb);
    let piece_b = string.str_slice(b, ib, ib + bl_b);
    result = string.str_concat(result, piece_b);
    ib = ib + bl_b;
  };
  if ia < la {
    let tail_a = string.str_slice(a, ia, la);
    result = string.str_concat(result, tail_a);
  };
  if ib < lb {
    let tail_b = string.str_slice(b, ib, lb);
    result = string.str_concat(result, tail_b);
  };
  result
}

/// Merges the parts character by character in a round-robin fashion: the
/// first character of every part, then the second of every part, and so on.
/// `sep` is inserted between adjacent output characters (not before the first
/// and not after the last). An empty parts list yields the empty string.
/// Params: parts the strings to merge; sep the separator between characters.
/// Returns: the interleaved string with separators.
/// Error case: parts.len() == 0 => "".
/// Complexity: O(total chars * parts.len()).
pub fn str_interleave_n(parts: &Vec[Str], sep: Str) -> Str
  requires: true  // extern char_at calls in the loop (T002 confinement)
{
  let pcount = parts.len();
  if pcount == 0 {
    return "";
  };
  var pos = Vec[Int].new();
  var i: Int = 0;
  while i < pcount {
    pos.push(0);
    i = i + 1;
  };
  var result = "";
  var done = false;
  while !done {
    done = true;
    var j: Int = 0;
    while j < pcount {
      let plen = string.str_len(parts[j]);
      if pos[j] < plen {
        done = false;
        if string.str_len(result) > 0 {
          result = string.str_concat(result, sep);
        };
        let ch = xiom_char_at(parts[j], pos[j]);
        let bl = char.len_utf8(ch);
        let piece = string.str_slice(parts[j], pos[j], pos[j] + bl);
        result = string.str_concat(result, piece);
        pos[j] = pos[j] + bl;
      };
      j = j + 1;
    };
  };
  result
}
