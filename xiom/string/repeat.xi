// XIOM - String: Repeat
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.repeat

// Depends on: xiom.string, xiom.char, xiom.core

// ============================================================================
// Repeat a string or a single character a given number of times. A count of
// zero or less yields the empty string; `str_repeat` delegates to the flat
// string library, `str_repeat_char` encodes the character once and repeats
// the single-char string.
//
// TODO(compiler): BUG 22 #15 -- a catalog fn whose unsafe block contains a
// while loop + string build loses statements when inlined into the caller
// (the identical code works with extra statements inside the block; the flat
// string.xi str_concat shape works because it returns directly from inside
// the block). `str_repeat_char` therefore keeps NO loop inside its unsafe
// block: encoding happens in `_char_to_str` (str_concat shape) and the
// repetition reuses the proven flat `string.str_repeat`.
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

// Encodes `c` as a single-character string (str_concat-proven unsafe shape:
// no loop, direct return from inside the block). Complexity: O(1).
fn _char_to_str(c: Char) -> Str {
  let code = to_int_from_char(c);
  var bl = 1;
  if code > 0x7FF {
    bl = 3;
  } elif code > 0x7F {
    bl = 2;
  };
  if code > 0xFFFF {
    bl = 4;
  };
  unsafe {
    var buf = malloc(bl + 1);
    if code <= 0x7F {
      buf[0] = code as UInt8;
    } elif code <= 0x7FF {
      buf[0] = (0xC0 | (code >> 6)) as UInt8;
      buf[1] = (0x80 | (code & 0x3F)) as UInt8;
    } elif code <= 0xFFFF {
      buf[0] = (0xE0 | (code >> 12)) as UInt8;
      buf[1] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
      buf[2] = (0x80 | (code & 0x3F)) as UInt8;
    } else {
      buf[0] = (0xF0 | (code >> 18)) as UInt8;
      buf[1] = (0x80 | ((code >> 12) & 0x3F)) as UInt8;
      buf[2] = (0x80 | ((code >> 6) & 0x3F)) as UInt8;
      buf[3] = (0x80 | (code & 0x3F)) as UInt8;
    };
    buf[bl] = 0;
    return Str.from_cstring(buf);
  }
}

/// Repeats `s` `n` times. Returns the empty string when `n <= 0`.
/// Complexity: O(n * |s|).
pub fn str_repeat(s: Str, n: Int) -> Str {
  return string.str_repeat(s, n);
}

/// Returns a string consisting of `c` repeated `n` times. Returns the empty
/// string when `n <= 0`. Multi-byte characters are encoded correctly.
/// Complexity: O(n).
pub fn str_repeat_char(c: Char, n: Int) -> Str {
  if n <= 0 {
    return "";
  };
  let one = _char_to_str(c);
  return string.str_repeat(one, n);
}
