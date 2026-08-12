// XIOM - Conversion: Json
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.json

// Depends on: xiom.serialize

// ============================================================================
// JSON string escaping, validation, and pretty-printing helpers. The
// reference implementation lives in xiom.serialize; the escape/unescape and
// pretty-print logic is reimplemented here (same function names as the
// canonical module — same-name delegation miscompiles, BUG 25 #1) and the
// validator is a compact recursive-descent parser. All invalid inputs return
// an error instead of crashing.
// ============================================================================

use xiom.string;

/// Escape a string for embedding in JSON (without surrounding quotes).
/// Handles ", \, \n, \r, \t, \b, \f.
/// Parameters: s — the raw text.
/// Returns: the escaped text.
/// Complexity: O(n), n = string length.
pub fn json_escape(s: Str) -> Str {
  var result = "";
  var len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 34 {
      result = string.str_concat(result, "\\\"");
    } elif b == 92 {
      result = string.str_concat(result, "\\\\");
    } elif b == 10 {
      result = string.str_concat(result, "\\n");
    } elif b == 13 {
      result = string.str_concat(result, "\\r");
    } elif b == 9 {
      result = string.str_concat(result, "\\t");
    } elif b == 8 {
      result = string.str_concat(result, "\\b");
    } elif b == 12 {
      result = string.str_concat(result, "\\f");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

/// Unescape a JSON string literal (without surrounding quotes).
/// Handles \\, \", \/, \b, \f, \n, \r, \t, and \uNNNN.
/// Parameters: s — the escaped text.
/// Returns: Ok(text) on success; Err on an invalid escape or a truncated
///          \u sequence.
/// Complexity: O(n), n = string length.
pub fn json_unescape(s: Str) -> Result[Str, Str] {
  var result = "";
  var len = string.str_len(s);
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 {
      if i + 1 >= len {
        return Err("json_unescape: unexpected end after backslash");
      }
      var esc = string.byte_at(s, i + 1);
      if esc == 34 {
        result = string.str_concat(result, "\"");
      } elif esc == 92 {
        result = string.str_concat(result, "\\");
      } elif esc == 47 {
        result = string.str_concat(result, "/");
      } elif esc == 98 {
        result = string.str_concat(result, "\b");
      } elif esc == 102 {
        result = string.str_concat(result, "\f");
      } elif esc == 110 {
        result = string.str_concat(result, "\n");
      } elif esc == 114 {
        result = string.str_concat(result, "\r");
      } elif esc == 116 {
        result = string.str_concat(result, "\t");
      } elif esc == 117 {
        if i + 5 >= len {
          return Err("json_unescape: truncated \\u escape");
        }
        var hex = string.str_slice(s, i + 2, i + 6);
        var cp = _hex4(hex);
        if cp < 0 {
          return Err("json_unescape: invalid \\u escape");
        }
        var ch = _cp_to_str(cp);
        result = string.str_concat(result, ch);
        i = i + 4;
      } else {
        return Err("json_unescape: invalid escape sequence");
      }
      i = i + 2;
    } else {
      var c2 = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c2);
      i = i + 1;
    }
  }
  return Ok(result);
}

/// Wrap a string in JSON quotes with escaping.
/// Parameters: s — the raw text.
/// Returns: the quoted, escaped JSON string literal.
/// Complexity: O(n).
pub fn json_quote(s: Str) -> Str {
  return string.str_concat("\"", string.str_concat(json_escape(s), "\""));
}

/// Check that a string is valid JSON (a single top-level value).
/// Parameters: s — the candidate JSON text.
/// Returns: true when the whole input parses as one JSON value.
/// Complexity: O(n).
pub fn json_is_valid(s: Str) -> Bool {
  var pos: Int = 0;
  _skip_ws(s, &pos);
  if !_valid_value(s, &pos) {
    return false;
  }
  _skip_ws(s, &pos);
  return pos == string.str_len(s);
}

/// Pretty-print a JSON string with 2-space indentation.
/// Parameters: s — the minified JSON text.
/// Returns: Ok(pretty) on success; Err for invalid JSON (unterminated
///          string or unbalanced brackets).
/// Complexity: O(n), n = input length.
pub fn json_pretty(s: Str) -> Result[Str, Str] {
  var result = "";
  var len = string.str_len(s);
  var i: Int = 0;
  var depth: Int = 0;
  var in_string = false;
  var need_newline = false;
  var after_colon = false;
  while i < len {
    var b = string.byte_at(s, i);
    if in_string {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
      if b == 92 {
        i = i + 1;
        if i < len {
          var esc = string.str_slice(s, i, i + 1);
          result = string.str_concat(result, esc);
        }
      } elif b == 34 {
        in_string = false;
      }
    } else {
      if b == 34 {
        if need_newline {
          result = string.str_concat(result, "\n");
          result = string.str_concat(result, _indent(depth));
          need_newline = false;
        }
        in_string = true;
        result = string.str_concat(result, "\"");
      } elif b == 123 || b == 91 {
        if need_newline {
          result = string.str_concat(result, "\n");
          result = string.str_concat(result, _indent(depth));
          need_newline = false;
        }
        var open = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, open);
        depth = depth + 1;
        need_newline = true;
      } elif b == 125 || b == 93 {
        depth = depth - 1;
        if need_newline {
          result = string.str_concat(result, "\n");
          result = string.str_concat(result, _indent(depth));
          need_newline = false;
        }
        var close = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, close);
      } elif b == 44 {
        result = string.str_concat(result, ",");
        need_newline = true;
      } elif b == 58 {
        result = string.str_concat(result, ": ");
      } else {
        if need_newline {
          result = string.str_concat(result, "\n");
          result = string.str_concat(result, _indent(depth));
          need_newline = false;
        }
        var c2 = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, c2);
      }
    }
    i = i + 1;
  }
  if in_string {
    return Err("json_pretty: unterminated string");
  }
  return Ok(result);
}

// Skip JSON whitespace starting at *pos.
fn _skip_ws(s: Str, pos: &mut Int) {
  var len = string.str_len(s);
  while *pos < len {
    var b = string.byte_at(s, *pos);
    if b == 32 || b == 9 || b == 10 || b == 13 {
      *pos = *pos + 1;
    } else {
      break;
    }
  }
}

// Validate one JSON value starting at *pos (advances on success).
fn _valid_value(s: Str, pos: &mut Int) -> Bool {
  var len = string.str_len(s);
  if *pos >= len {
    return false;
  }
  var b = string.byte_at(s, *pos);
  if b == 123 {
    return _valid_object(s, pos);
  }
  if b == 91 {
    return _valid_array(s, pos);
  }
  if b == 34 {
    return _valid_string(s, pos);
  }
  if b == 116 {
    return _valid_literal(s, pos, "true");
  }
  if b == 102 {
    return _valid_literal(s, pos, "false");
  }
  if b == 110 {
    return _valid_literal(s, pos, "null");
  }
  return _valid_number(s, pos);
}

// Validate {"k": v, ...}.
fn _valid_object(s: Str, pos: &mut Int) -> Bool {
  *pos = *pos + 1;
  _skip_ws(s, pos);
  if _peek(s, pos) == 125 {
    *pos = *pos + 1;
    return true;
  }
  loop {
    _skip_ws(s, pos);
    if !_valid_string(s, pos) {
      return false;
    }
    _skip_ws(s, pos);
    if _peek(s, pos) != 58 {
      return false;
    }
    *pos = *pos + 1;
    _skip_ws(s, pos);
    if !_valid_value(s, pos) {
      return false;
    }
    _skip_ws(s, pos);
    var c = _peek(s, pos);
    if c == 44 {
      *pos = *pos + 1;
    } elif c == 125 {
      *pos = *pos + 1;
      return true;
    } else {
      return false;
    }
  }
}

// Validate [v, ...].
fn _valid_array(s: Str, pos: &mut Int) -> Bool {
  *pos = *pos + 1;
  _skip_ws(s, pos);
  if _peek(s, pos) == 93 {
    *pos = *pos + 1;
    return true;
  }
  loop {
    _skip_ws(s, pos);
    if !_valid_value(s, pos) {
      return false;
    }
    _skip_ws(s, pos);
    var c = _peek(s, pos);
    if c == 44 {
      *pos = *pos + 1;
    } elif c == 93 {
      *pos = *pos + 1;
      return true;
    } else {
      return false;
    }
  }
}

// Validate a quoted string (control bytes below 0x20 are rejected).
fn _valid_string(s: Str, pos: &mut Int) -> Bool {
  var len = string.str_len(s);
  *pos = *pos + 1;
  while *pos < len {
    var b = string.byte_at(s, *pos);
    if b == 34 {
      *pos = *pos + 1;
      return true;
    }
    if b == 92 {
      if *pos + 1 >= len {
        return false;
      }
      var esc = string.byte_at(s, *pos + 1);
      if esc == 34 || esc == 92 || esc == 47 || esc == 98 || esc == 102 || esc == 110 || esc == 114 || esc == 116 {
        *pos = *pos + 2;
      } elif esc == 117 {
        if *pos + 5 >= len {
          return false;
        }
        var hi = _hex4(string.str_slice(s, *pos + 2, *pos + 6));
        if hi < 0 {
          return false;
        }
        *pos = *pos + 6;
      } else {
        return false;
      }
    } elif b < 32 {
      return false;
    } else {
      *pos = *pos + 1;
    }
  }
  return false;
}

// Validate a number literal: -? digits (. digits)? ([eE][+-]? digits)?
fn _valid_number(s: Str, pos: &mut Int) -> Bool {
  var len = string.str_len(s);
  var start = *pos;
  if _peek(s, pos) == 45 {
    *pos = *pos + 1;
  }
  if _peek(s, pos) == 48 {
    *pos = *pos + 1;
  } else {
    if !_is_digit(_peek(s, pos)) {
      *pos = start;
      return false;
    }
    while _is_digit(_peek(s, pos)) {
      *pos = *pos + 1;
    }
  }
  if _peek(s, pos) == 46 {
    *pos = *pos + 1;
    if !_is_digit(_peek(s, pos)) {
      *pos = start;
      return false;
    }
    while _is_digit(_peek(s, pos)) {
      *pos = *pos + 1;
    }
  }
  var e = _peek(s, pos);
  if e == 101 || e == 69 {
    *pos = *pos + 1;
    var sign = _peek(s, pos);
    if sign == 43 || sign == 45 {
      *pos = *pos + 1;
    }
    if !_is_digit(_peek(s, pos)) {
      *pos = start;
      return false;
    }
    while _is_digit(_peek(s, pos)) {
      *pos = *pos + 1;
    }
  }
  return *pos > start;
}

// Validate a fixed keyword literal.
fn _valid_literal(s: Str, pos: &mut Int, kw: Str) -> Bool {
  var len = string.str_len(s);
  var klen = string.str_len(kw);
  if *pos + klen > len {
    return false;
  }
  var i: Int = 0;
  while i < klen {
    var a = string.byte_at(s, *pos + i);
    var b = string.byte_at(kw, i);
    if a != b {
      return false;
    }
    i = i + 1;
  }
  *pos = *pos + klen;
  return true;
}

// Byte at *pos, or 0 when exhausted.
fn _peek(s: Str, pos: &mut Int) -> Int {
  if *pos < string.str_len(s) {
    return string.byte_at(s, *pos) as Int;
  }
  return 0;
}

fn _is_digit(b: Int) -> Bool {
  return b >= 48 && b <= 57;
}

// Parse a 4-digit hex string (0-9a-fA-F) into an Int; -1 on error.
fn _hex4(s: Str) -> Int {
  var v: Int = 0;
  var i: Int = 0;
  while i < 4 {
    var b = string.byte_at(s, i);
    var d: Int = -1;
    if b >= 48 && b <= 57 {
      d = (b as Int) - 48;
    } elif b >= 97 && b <= 102 {
      d = (b as Int) - 87;
    } elif b >= 65 && b <= 70 {
      d = (b as Int) - 55;
    }
    if d < 0 {
      return -1;
    }
    v = v * 16 + d;
    i = i + 1;
  }
  return v;
}

// depth * 2 spaces.
fn _indent(depth: Int) -> Str {
  var result = "";
  var i: Int = 0;
  while i < depth {
    result = string.str_concat(result, "  ");
    i = i + 1;
  }
  return result;
}

// Render a code point as a UTF-8 string.
fn _cp_to_str(cp: Int) -> Str {
  var buf = Vec[UInt8].new();
  if cp <= 0x7F {
    buf.push(cp as UInt8);
  } elif cp <= 0x7FF {
    buf.push((0xC0 | (cp >> 6)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
  } elif cp <= 0xFFFF {
    buf.push((0xE0 | (cp >> 12)) as UInt8);
    buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
  } else {
    buf.push((0xF0 | (cp >> 18)) as UInt8);
    buf.push((0x80 | ((cp >> 12) & 0x3F)) as UInt8);
    buf.push((0x80 | ((cp >> 6) & 0x3F)) as UInt8);
    buf.push((0x80 | (cp & 0x3F)) as UInt8);
  }
  return Str::from_utf8(buf);
}
