// XIOM - String: Unescape
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.string.unescape

// Depends on: none

// ============================================================================
// Decode escape sequences back into their literal characters. NOTE: current
// implementation lives in string.str_unescape - move the functions here during
// the implementation phase. TODO(compiler): implement.
// ============================================================================

use xiom.string;
use xiom.convert;
use xiom.char;

// Masked byte at `pos` (BUG 22 #10: `as Int` sign-extends UInt8).
// Complexity: O(1).
fn _byte(s: Str, i: Int) -> Int {
  let v = string.byte_at(s, i) as Int;
  v & 0xFF
}

// Hex digit value of `c`, or -1 when `c` is not a hex digit.
// Complexity: O(1).
fn _hex_val(c: Int) -> Int {
  if c >= 48 && c <= 57 {
    return c - 48;
  };
  if c >= 97 && c <= 102 {
    return c - 87;
  };
  if c >= 65 && c <= 70 {
    return c - 55;
  };
  -1
}

// One-char string holding the raw byte `b` (0..255); "" outside the range.
// Complexity: O(1).
fn _byte_str(b: Int) -> Str {
  if b < 0 || b > 255 {
    return "";
  };
  var out = Vec[UInt8].new();
  out.push(b as UInt8);
  out.push(0);
  unsafe {
    Str.from_cstring(out.data)
  }
}

// One-char (or multi-byte) string holding the UTF-8 encoding of the code
// point `cp`; "" for invalid code points.
// Complexity: O(1).
fn _cp_str(cp: Int) -> Str {
  var out = Vec[UInt8].new();
  let c_opt = convert.int_to_char(cp);
  match c_opt {
    Some(c) => {
      char.encode_utf8(c, &mut out);
    };
    None => {
      return "";
    };
  }
  if out.len() == 0 {
    return "";
  };
  out.push(0);
  unsafe {
    Str.from_cstring(out.data)
  }
}

/// Interpret the common escape sequences in `s` back into literal characters:
/// \n, \t, \r, \" and \\. Unrecognised backslash sequences are left unchanged,
/// so `str_escape` followed by `str_unescape` round-trips.
/// Params: s the string containing escape sequences.
/// Returns: the unescaped string.
/// Error case: none.
/// Complexity: O(|s|).
pub fn str_unescape(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _byte(s, i);
    if c == 92 && i + 1 < len {
      let n = _byte(s, i + 1);
      if n == 110 {
        result = string.str_concat(result, "\n");
        i = i + 2;
      } elif n == 116 {
        result = string.str_concat(result, "\t");
        i = i + 2;
      } elif n == 114 {
        result = string.str_concat(result, "\r");
        i = i + 2;
      } elif n == 34 {
        result = string.str_concat(result, "\"");
        i = i + 2;
      } elif n == 92 {
        result = string.str_concat(result, "\\");
        i = i + 2;
      } else {
        result = string.str_concat(result, string.str_slice(s, i, i + 1));
        i = i + 1;
      };
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  result
}

/// Interpret only the ASCII escapes in `s`: \n, \t and \xNN (exactly two hex
/// digits, producing the raw byte). Every other sequence, including \" and \\,
/// passes through unchanged.
/// Params: s the string containing escape sequences.
/// Returns: the unescaped string.
/// Error case: none; a malformed \xNN (fewer than two hex digits) is kept.
/// Complexity: O(|s|).
pub fn str_unescape_ascii(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _byte(s, i);
    if c == 92 && i + 1 < len {
      let n = _byte(s, i + 1);
      if n == 110 {
        result = string.str_concat(result, "\n");
        i = i + 2;
      } elif n == 116 {
        result = string.str_concat(result, "\t");
        i = i + 2;
      } elif n == 120 && i + 3 < len {
        let h1 = _hex_val(_byte(s, i + 2));
        let h2 = _hex_val(_byte(s, i + 3));
        if h1 >= 0 && h2 >= 0 {
          let b = h1 * 16 + h2;
          result = string.str_concat(result, _byte_str(b));
          i = i + 4;
        } else {
          result = string.str_concat(result, string.str_slice(s, i, i + 1));
          i = i + 1;
        };
      } else {
        result = string.str_concat(result, string.str_slice(s, i, i + 1));
        i = i + 1;
      };
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  result
}

/// Interpret the Unicode escapes in `s`: \uNNNN (exactly four hex digits) and
/// \UNNNNNNNN (exactly eight hex digits), producing the UTF-8 encoding of the
/// code point. Every other sequence passes through unchanged.
/// Params: s the string containing escape sequences.
/// Returns: the unescaped string.
/// Error case: none; a malformed escape (wrong digit count) is kept verbatim.
/// Complexity: O(|s|).
pub fn str_unescape_unicode(s: Str) -> Str {
  var result = "";
  let len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    let c = _byte(s, i);
    if c == 92 && i + 1 < len {
      let n = _byte(s, i + 1);
      if n == 117 && i + 5 < len {
        var cp: Int = 0;
        var ok = true;
        var k: Int = 0;
        while k < 4 {
          let hv = _hex_val(_byte(s, i + 2 + k));
          if hv < 0 {
            ok = false;
          } else {
            cp = cp * 16 + hv;
          };
          k = k + 1;
        };
        if ok {
          result = string.str_concat(result, _cp_str(cp));
          i = i + 6;
        } else {
          result = string.str_concat(result, string.str_slice(s, i, i + 1));
          i = i + 1;
        };
      } elif n == 85 && i + 9 < len {
        var cp2: Int = 0;
        var ok2 = true;
        var k2: Int = 0;
        while k2 < 8 {
          let hv2 = _hex_val(_byte(s, i + 2 + k2));
          if hv2 < 0 {
            ok2 = false;
          } else {
            cp2 = cp2 * 16 + hv2;
          };
          k2 = k2 + 1;
        };
        if ok2 {
          result = string.str_concat(result, _cp_str(cp2));
          i = i + 10;
        } else {
          result = string.str_concat(result, string.str_slice(s, i, i + 1));
          i = i + 1;
        };
      } else {
        result = string.str_concat(result, string.str_slice(s, i, i + 1));
        i = i + 1;
      };
    } else {
      result = string.str_concat(result, string.str_slice(s, i, i + 1));
      i = i + 1;
    };
  };
  result
}
