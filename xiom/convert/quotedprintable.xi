// XIOM - Conversion: Quoted-Printable
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.quotedprintable

// Depends on: xiom.string

// ============================================================================
// Quoted-Printable encoding and decoding per RFC 2045, used in email MIME.
// Bytes in the printable set pass through; '=' and trailing whitespace are
// escaped as =HH; long lines get soft breaks (=\r\n) at the configured width.
// ============================================================================

use xiom.string;

/// Encode bytes to Quoted-Printable with default 76-column lines.
/// Parameters: data -- the raw bytes.
/// Returns: the QP-encoded text (ASCII).
/// Complexity: O(n).
pub fn qp_encode(data: &Vec[UInt8]) -> Str {
  return qp_encode_maxline(data, 76);
}

/// Encode bytes to Quoted-Printable using a custom maximum line width.
/// Parameters: data -- the raw bytes; max_line -- the target column limit.
/// Returns: the QP-encoded text.
/// Complexity: O(n).
pub fn qp_encode_maxline(data: &Vec[UInt8], max_line: Int) -> Str {
  var result = "";
  var col: Int = 0;
  var i: Int = 0;
  var n = data.len();
  while i < n {
    var b = data[i];
    var v = b as Int;
    v = v & 0xFF;
    if v == 13 || v == 10 {
      result = string.str_concat(result, _byte_str(v));
      col = 0;
    } elif _qp_printable(v) {
      if col + 1 > max_line {
        result = string.str_concat(result, "=\r\n");
        col = 0;
      }
      result = string.str_concat(result, _byte_str(v));
      col = col + 1;
    } else {
      if col + 3 > max_line {
        result = string.str_concat(result, "=\r\n");
        col = 0;
      }
      result = string.str_concat(result, qp_escape_byte(b));
      col = col + 3;
    }
    i = i + 1;
  }
  return result;
}

/// Decode a Quoted-Printable string to bytes.
/// Parameters: s -- the QP-encoded text.
/// Returns: Ok(bytes) on success; Err for a truncated or invalid =HH escape.
/// Complexity: O(n).
pub fn qp_decode(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  var len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 61 {
      if i + 1 < len {
        var next = string.byte_at(s, i + 1);
        if next == 13 {
          if i + 2 < len {
            var n2 = string.byte_at(s, i + 2);
            if n2 == 10 {
              i = i + 3;
            } else {
              i = i + 2;
            }
          } else {
            i = i + 2;
          }
        } elif next == 10 {
          i = i + 2;
        } else {
          if i + 2 >= len {
            return Err("qp_decode: truncated escape");
          }
          var hi = _hex_val(string.byte_at(s, i + 1));
          var lo = _hex_val(string.byte_at(s, i + 2));
          if hi < 0 || lo < 0 {
            return Err("qp_decode: invalid escape");
          }
          result.push(((hi << 4) | lo) as UInt8);
          i = i + 3;
        }
      } else {
        return Err("qp_decode: truncated escape");
      }
    } else {
      result.push(b);
      i = i + 1;
    }
  }
  return Ok(result);
}

/// Insert soft line breaks (=CRLF) into already-encoded text.
/// Parameters: s -- the encoded text; width -- the maximum line width.
/// Returns: the re-wrapped text.
/// Complexity: O(n).
pub fn qp_soft_linebreak(s: Str, width: Int) -> Str {
  var result = "";
  var col: Int = 0;
  var len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 13 || b == 10 {
      result = string.str_concat(result, _byte_str(b as Int));
      col = 0;
      i = i + 1;
    } else {
      var width_needed: Int = 1;
      if b == 61 {
        width_needed = 3;
      }
      if col + width_needed > width {
        result = string.str_concat(result, "=\r\n");
        col = 0;
      }
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
      col = col + width_needed;
      i = i + 1;
    }
  }
  return result;
}

/// Report whether the string is too binary for safe Quoted-Printable use
/// (contains NUL or more than a third of its bytes are control bytes).
/// Parameters: s -- the candidate text.
/// Returns: true when the content is too binary.
/// Complexity: O(n).
pub fn qp_is_binary(s: Str) -> Bool {
  var len = string.str_len(s);
  if len == 0 {
    return false;
  }
  var control: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    var v = b as Int;
    v = v & 0xFF;
    if v == 0 {
      return true;
    }
    if v < 32 && v != 9 && v != 10 && v != 13 {
      control = control + 1;
    }
    i = i + 1;
  }
  return control * 3 > len;
}

/// Return the =HH escape for a single byte.
/// Parameters: b -- the byte.
/// Returns: a three-character "=HH" string (uppercase hex).
/// Complexity: O(1).
pub fn qp_escape_byte(b: UInt8) -> Str {
  var v = b as Int;
  v = v & 0xFF;
  var result = "=";
  result = string.str_concat(result, _hex_digit((v >> 4) & 0x0F));
  result = string.str_concat(result, _hex_digit(v & 0x0F));
  return result;
}

// Printable QP characters: tab, space, and 33..60 / 62..126 (excludes '=').
fn _qp_printable(v: Int) -> Bool {
  if v == 9 || v == 32 {
    return true;
  }
  if v >= 33 && v <= 60 {
    return true;
  }
  if v >= 62 && v <= 126 {
    return true;
  }
  return false;
}

fn _hex_val(b: UInt8) -> Int {
  var v = b as Int;
  if v >= 48 && v <= 57 {
    return v - 48;
  }
  if v >= 97 && v <= 102 {
    return v - 87;
  }
  if v >= 65 && v <= 70 {
    return v - 55;
  }
  return -1;
}

fn _hex_digit(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("ABCDEF", d - 10, d - 9);
}

fn _byte_str(v: Int) -> Str {
  var buf = Vec[UInt8].new();
  buf.push(v as UInt8);
  return Str::from_utf8(buf);
}
