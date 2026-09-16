// XIOM - String: Line Break
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.linebreak

// Depends on: xiom.string

// ============================================================================
// Unicode line breaking (UAX #14, compact approximation). Break opportunities
// are reported as byte offsets and are computed from a small class table
// (AL/NU/SP/ID/BA/B2/GL/OP/CL/EX/IS/QU/PO/PR/WJ/ZW/NL/BK). Implemented rules:
// mandatory breaks at newlines and paragraph separators, breaks after space
// runs, around em/en dashes, after hyphens, around CJK ideographic runs, and
// before opening punctuation following a word. No-break zones: within
// letter/digit runs, around quotes, glue and word-joiners, and before closing
// punctuation. The full UAX #14 rule set is not implemented. The class range
// checks are split across small predicate functions so the compiler's -O2
// vectorizer never sees a long classification chain in a loop (see
// COMPILER_BUGS.md BUG 20).
// ============================================================================

use xiom.string;

/// Byte offsets in `s` where a line break is allowed, in increasing order.
/// The offsets are boundaries: the text up to an offset ends one line and the
/// text from that offset starts the next. Mandatory breaks (newline, paragraph
/// separator) are reported just after the break character, so the character
/// stays with the preceding line. See the module header for the covered rules.
/// Params: s the string to analyse.
/// Returns: the list of allowed break byte offsets (may be empty).
/// Error case: none; malformed UTF-8 bytes are skipped without break points.
/// Complexity: O(|s|).
pub fn unicode_line_break_points(s: Str) -> Vec[Int] {
  let len = string.str_len(s);
  var breaks = Vec[Int].new();
  var i: Int = 0;
  var prev_cls: Int = -1;
  while i < len {
    let pos = i;
    let cp = _decode(s, i, len);
    if cp < 0 {
      i = i + 1;
      continue;
    };
    let cl = _lb_class(cp);
    let adv = _char_len(cp);
    if cl == 16 || cl == 17 {
      // mandatory break: report after the break character
      breaks.push(pos + adv);
    } elif cl == 15 {
      // zero-width space: break after it
      breaks.push(pos + adv);
    } elif cl == 1 {
      // space run: the break is reported before the next non-space char
    } else {
      if prev_cls == 1 {
        breaks.push(pos);
      } elif cl == 2 {
        if prev_cls == 0 || prev_cls == 11 || prev_cls == 7 || prev_cls == 8 || prev_cls == 9 || prev_cls == 4 {
          breaks.push(pos);
        };
      } elif cl == 6 {
        if prev_cls == 0 || prev_cls == 11 || prev_cls == 2 || prev_cls == 7 || prev_cls == 8 || prev_cls == 9 || prev_cls == 12 || prev_cls == 4 || prev_cls == 10 {
          breaks.push(pos);
        };
      } elif cl == 4 {
        if prev_cls >= 0 {
          breaks.push(pos);
        };
      } elif cl == 7 || cl == 8 || cl == 9 {
        // no break before closing/exclamation/infix punctuation
      } else {
        if prev_cls == 3 || prev_cls == 4 {
          breaks.push(pos);
        } elif prev_cls == 2 {
          breaks.push(pos);
        };
      };
    };
    prev_cls = cl;
    i = i + adv;
  }
  breaks
}

/// Split `s` into lines at the allowed break points. The line break character
/// of a mandatory break stays with the preceding line; space runs also stay
/// with the preceding line. A trailing break produces a trailing empty line.
/// Params: s the string to split.
/// Returns: the list of line substrings.
/// Error case: none.
/// Complexity: O(|s| + number of break points).
pub fn unicode_split_lines(s: Str) -> Vec[Str] {
  let breaks = unicode_line_break_points(s);
  let len = string.str_len(s);
  var lines = Vec[Str].new();
  var start: Int = 0;
  var i: Int = 0;
  while i < breaks.len() {
    let b = breaks[i];
    if b > start {
      lines.push(string.str_slice(s, start, b));
    };
    start = b;
    i = i + 1;
  }
  if start < len {
    lines.push(string.str_slice(s, start, len));
  } else {
    lines.push("");
  };
  lines
}

// -- Private helpers ---------------------------------------------------------

// Line break classes: 0=AL 1=SP 2=ID 3=BA 4=B2 5=GL 6=OP 7=CL 8=EX 9=IS
// 10=QU 11=NU 12=PO 13=PR 14=WJ 15=ZW 16=NL 17=BK

/// Line break class of one codepoint; 0 (AL) when unmapped.
/// NOTE (BUG 20): the class table is walked through a small recursive helper;
/// a straight-line range-check chain would be SIMD-vectorized by the -O2
/// vectorizer into AVX-512 instructions that trap on CPUs without AVX-512.
fn _lb_class(cp: Int) -> Int {
  _lb_r(cp, 0)
}

fn _lb_r(cp: Int, i: Int) -> Int {
  if i == 0 {
    if cp == 0x09 { return 1; };
  };
  if i == 1 {
    if cp == 0x0D { return 1; };
  };
  if i == 2 {
    if cp == 0x20 { return 1; };
  };
  if i == 3 {
    if cp == 0x22 { return 10; };
  };
  if i == 4 {
    if cp == 0x24 || cp == 0xA2 || cp == 0xA3 || cp == 0xA5 { return 13; };
  };
  if i == 5 {
    if cp == 0x25 { return 12; };
  };
  if i == 6 {
    if cp == 0x27 { return 10; };
  };
  if i == 7 {
    if cp == 0x28 || cp == 0x5B || cp == 0x7B { return 6; };
  };
  if i == 8 {
    if cp == 0x29 || cp == 0x5D || cp == 0x7D { return 7; };
  };
  if i == 9 {
    if cp == 0x2C || cp == 0x2E { return 9; };
  };
  if i == 10 {
    if cp >= 0x30 && cp <= 0x39 { return 11; };
  };
  if i == 11 {
    if cp >= 0x3A && cp <= 0x3B { return 9; };
  };
  if i == 12 {
    if cp == 0x21 || cp == 0x3F { return 8; };
  };
  if i == 13 {
    if cp == 0xA0 { return 5; };
  };
  if i == 14 {
    if cp == 0x00AD { return 3; };
  };
  if i == 15 {
    if cp == 0x0A || cp == 0x85 || cp == 0x2028 { return 16; };
  };
  if i == 16 {
    if cp >= 0x0B && cp <= 0x0C { return 17; };
  };
  if i == 17 {
    if cp == 0x2029 { return 17; };
  };
  if i == 18 {
    if cp == 0x1680 { return 1; };
  };
  if i == 19 {
    if cp >= 0x2000 && cp <= 0x200A { return 1; };
  };
  if i == 20 {
    if cp == 0x200B { return 15; };
  };
  if i == 21 {
    if cp >= 0x2010 && cp <= 0x2011 { return 3; };
  };
  if i == 22 {
    if cp >= 0x2013 && cp <= 0x2014 { return 4; };
  };
  if i == 23 {
    if cp == 0x202F || cp == 0x205F || cp == 0x3000 { return 1; };
  };
  if i == 24 {
    if cp == 0x2060 || cp == 0xFEFF { return 14; };
  };
  if i == 25 {
    if cp >= 0x3001 && cp <= 0x303F { return 2; };
  };
  if i == 26 {
    if cp >= 0x3040 && cp <= 0x309F { return 2; };
  };
  if i == 27 {
    if cp >= 0x30A0 && cp <= 0x30FF { return 2; };
  };
  if i == 28 {
    if cp >= 0x3400 && cp <= 0x4DBF { return 2; };
  };
  if i == 29 {
    if cp >= 0x4E00 && cp <= 0x9FFF { return 2; };
  };
  if i == 30 {
    if cp >= 0xAC00 && cp <= 0xD7A3 { return 2; };
  };
  if i == 31 {
    if cp >= 0xF900 && cp <= 0xFAFF { return 2; };
  };
  if i == 32 {
    if cp >= 0x20000 && cp <= 0x2A6DF { return 2; };
  };
  if i == 33 {
    if cp >= 0x660 && cp <= 0x669 { return 11; };
  };
  if i < 33 {
    return _lb_r(cp, i + 1);
  };
  0
}

/// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
fn _byte_at(s: Str, pos: Int) -> Int {
  let v = string.byte_at(s, pos) as Int;
  v & 0xFF
}

/// UTF-8 sequence length given the leading byte.
fn _seq_len(b0: Int) -> Int {
  if b0 <= 0x7F { return 1; };
  if (b0 & 0xE0) == 0xC0 { return 2; };
  if (b0 & 0xF0) == 0xE0 { return 3; };
  if (b0 & 0xF8) == 0xF0 { return 4; };
  1
}

/// UTF-8 byte length of a valid codepoint.
fn _char_len(cp: Int) -> Int {
  if cp <= 0x7F { return 1; };
  if cp <= 0x7FF { return 2; };
  if cp <= 0xFFFF { return 3; };
  4
}

/// Decode the codepoint at byte `pos`, or -1 on malformed input.
fn _decode(s: Str, pos: Int, len: Int) -> Int {
  let b0 = _byte_at(s, pos);
  let n = _seq_len(b0);
  if pos + n > len { return -1; };
  if n == 1 { return b0; };
  if n == 2 {
    let b1 = _byte_at(s, pos + 1);
    if (b1 & 0xC0) != 0x80 { return -1; };
    return ((b0 & 0x1F) << 6) | (b1 & 0x3F);
  };
  if n == 3 {
    let b1 = _byte_at(s, pos + 1);
    let b2 = _byte_at(s, pos + 2);
    if (b1 & 0xC0) != 0x80 { return -1; };
    if (b2 & 0xC0) != 0x80 { return -1; };
    let cp = ((b0 & 0x0F) << 12) | ((b1 & 0x3F) << 6) | (b2 & 0x3F);
    if cp >= 0xD800 && cp <= 0xDFFF { return -1; };
    return cp;
  };
  let b1 = _byte_at(s, pos + 1);
  let b2 = _byte_at(s, pos + 2);
  let b3 = _byte_at(s, pos + 3);
  if (b1 & 0xC0) != 0x80 { return -1; };
  if (b2 & 0xC0) != 0x80 { return -1; };
  if (b3 & 0xC0) != 0x80 { return -1; };
  ((b0 & 0x07) << 18) | ((b1 & 0x3F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
}
