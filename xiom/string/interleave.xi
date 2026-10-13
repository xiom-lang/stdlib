// XIOM - String: Interleave
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.interleave

// Depends on: none

// ============================================================================
// Merge strings by alternating characters or interleave multiple parts.
// NOTE: current implementation lives in string.combinatorics stub - move the
// functions here during the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.char;

// Raw byte at `i` (wave 128: cached raw pointer -- xiom_char_at strnlens the
// whole string per call, so the per-character merges were quadratic).
// Complexity: O(1).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

// Runtime-`xiom_char_at`-equivalent UTF-8 decode over a cached (base, len)
// view (copied byte-exact from slice.xi): continuation bytes are validated, a
// malformed or truncated sequence yields the leading byte itself, a stray
// continuation byte is returned as-is, and out-of-range positions read as 0.
// Complexity: O(1).
fn _char_at_runtime(base: *UInt8, len: Int, pos: Int) -> Char {
  if pos < 0 || pos >= len {
    return to_char(0);
  }
  var b0 = (_raw_byte(base, pos) as Int) & 0xFF;
  if b0 < 0x80 {
    return to_char(b0);
  }
  var n = 0;
  var cp = 0;
  if (b0 & 0xE0) == 0xC0 {
    n = 2;
    cp = b0 & 0x1F;
  } elif (b0 & 0xF0) == 0xE0 {
    n = 3;
    cp = b0 & 0x0F;
  } elif (b0 & 0xF8) == 0xF0 {
    n = 4;
    cp = b0 & 0x07;
  } else {
    return to_char(b0);
  }
  var i = 1;
  while i < n {
    var cb = 0;
    if pos + i < len {
      cb = (_raw_byte(base, pos + i) as Int) & 0xFF;
    }
    if (cb & 0xC0) != 0x80 {
      return to_char(b0);
    }
    cp = (cp << 6) | (cb & 0x3F);
    i = i + 1;
  }
  return to_char(cp);
}

/// Merges `a` and `b` by alternating their characters: the characters of `a`
/// and `b` are taken one at a time in turn; once the shorter string is
/// exhausted the remainder of the longer string is appended.
/// Params: a, b the strings to merge.
/// Returns: the interleaved string.
/// Error case: none.
/// Complexity: O(|a| + |b|).
pub fn str_interleave(a: Str, b: Str) -> Str
  requires: true  // raw-view decode in the loop (T002 confinement)
{
  let la = string.str_len(a);
  let lb = string.str_len(b);
  let ba = a.c_str();
  let bb = b.c_str();
  var ia: Int = 0;
  var ib: Int = 0;
  var out: Vec[UInt8] = Vec[UInt8].new();
  while ia < la && ib < lb {
    let ca = _char_at_runtime(ba, la, ia);
    let bl_a = char.len_utf8(ca);
    var k: Int = 0;
    while k < bl_a && ia + k < la {
      out.push(_raw_byte(ba, ia + k));
      k = k + 1;
    };
    ia = ia + bl_a;
    let cb = _char_at_runtime(bb, lb, ib);
    let bl_b = char.len_utf8(cb);
    var k2: Int = 0;
    while k2 < bl_b && ib + k2 < lb {
      out.push(_raw_byte(bb, ib + k2));
      k2 = k2 + 1;
    };
    ib = ib + bl_b;
  };
  var k3: Int = ia;
  while k3 < la {
    out.push(_raw_byte(ba, k3));
    k3 = k3 + 1;
  };
  var k4: Int = ib;
  while k4 < lb {
    out.push(_raw_byte(bb, k4));
    k4 = k4 + 1;
  };
  Str::from_utf8(out)
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
  requires: true  // raw-view decode in the loop (T002 confinement)
{
  let pcount = parts.len();
  if pcount == 0 {
    return "";
  };
  var pos = Vec[Int].new();
  var plens = Vec[Int].new();
  var i: Int = 0;
  while i < pcount {
    pos.push(0);
    plens.push(string.str_len(parts[i]));
    i = i + 1;
  };
  let bsep = sep.c_str();
  let sepl = string.str_len(sep);
  var out: Vec[UInt8] = Vec[UInt8].new();
  var done = false;
  while !done {
    done = true;
    var j: Int = 0;
    while j < pcount {
      let plen = plens[j];
      if pos[j] < plen {
        done = false;
        if out.len() > 0 {
          var ks: Int = 0;
          while ks < sepl {
            out.push(_raw_byte(bsep, ks));
            ks = ks + 1;
          };
        };
        let part = parts[j];
        let bp = part.c_str();
        let ch = _char_at_runtime(bp, plen, pos[j]);
        let bl = char.len_utf8(ch);
        var k: Int = 0;
        while k < bl && pos[j] + k < plen {
          out.push(_raw_byte(bp, pos[j] + k));
          k = k + 1;
        };
        pos[j] = pos[j] + bl;
      };
      j = j + 1;
    };
  };
  Str::from_utf8(out)
}
