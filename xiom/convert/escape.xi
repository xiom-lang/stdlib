// XIOM - Conversion: Escape
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.escape

// Depends on: xiom.string

// ============================================================================
// Escaping and quoting families for markup, delimited text, and shells.
// Covers HTML/XML entities, CSV/TSV fields, regex and glob literals, and
// POSIX/Windows shell quoting. URL component encoding lives in encoding.xi.
// All helpers are pure byte-wise functions over ASCII specials; the
// unescape/parse variants are non-failing (unrecognized sequences pass
// through unchanged).
// ============================================================================

use xiom.string;

/// Escape text for HTML body content: & < > " ' become entities.
/// Parameters: s -- the input text.
/// Returns: the escaped text (strictly longer unless no specials).
/// Complexity: O(n), n = input length.
pub fn html_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 38 {
      result = string.str_concat(result, "&amp;");
    } elif b == 60 {
      result = string.str_concat(result, "&lt;");
    } elif b == 62 {
      result = string.str_concat(result, "&gt;");
    } elif b == 34 {
      result = string.str_concat(result, "&quot;");
    } elif b == 39 {
      result = string.str_concat(result, "&#39;");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

/// Decode HTML entities back to characters: the named set (&amp; &lt; &gt;
/// &quot; &#39; &apos;) and numeric forms (&#NN; decimal, &#xHH; hex).
/// Parameters: s -- the escaped text.
/// Returns: the decoded text; unrecognized sequences pass through.
/// Complexity: O(n), n = input length.
pub fn html_unescape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 38 {
      var semi = _find_semicolon(s, i);
      if semi > i + 1 {
        var inner = string.str_slice(s, i + 1, semi);
        var decoded = _decode_entity(inner);
        result = string.str_concat(result, decoded);
        i = semi + 1;
      } else {
        var amp = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, amp);
        i = i + 1;
      }
    } else {
      var c2 = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c2);
      i = i + 1;
    }
  }
  return result;
}

/// Escape text for use inside HTML attribute quotes: same entity set as
/// html_escape plus both quote characters are always escaped.
/// Parameters: s -- the attribute value text.
/// Returns: the escaped text.
/// Complexity: O(n).
pub fn html_escape_attr(s: Str) -> Str {
  return html_escape(s);
}

/// Escape the five predefined XML entities: & " ' < >.
/// Parameters: s -- the input text.
/// Returns: the escaped text.
/// Complexity: O(n).
pub fn xml_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 38 {
      result = string.str_concat(result, "&amp;");
    } elif b == 34 {
      result = string.str_concat(result, "&quot;");
    } elif b == 39 {
      result = string.str_concat(result, "&apos;");
    } elif b == 60 {
      result = string.str_concat(result, "&lt;");
    } elif b == 62 {
      result = string.str_concat(result, "&gt;");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

/// Decode the predefined XML entities back to characters.
/// Parameters: s -- the escaped text.
/// Returns: the decoded text; unrecognized sequences pass through.
/// Complexity: O(n).
pub fn xml_unescape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 38 {
      var semi = _find_semicolon(s, i);
      if semi > i + 1 {
        var inner = string.str_slice(s, i + 1, semi);
        var decoded = _decode_entity(inner);
        result = string.str_concat(result, decoded);
        i = semi + 1;
      } else {
        var amp = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, amp);
        i = i + 1;
      }
    } else {
      var c2 = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c2);
      i = i + 1;
    }
  }
  return result;
}

/// Escape and quote a field for RFC 4180 CSV output: the field is quoted when
/// it contains a comma, quote, CR or LF, and embedded quotes are doubled.
/// Parameters: s -- the raw field value.
/// Returns: the CSV-ready field.
/// Complexity: O(n).
pub fn csv_escape_field(s: Str) -> Str {
  if !_csv_needs_quote(s) {
    return s;
  }
  var result = "\"";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 34 {
      result = string.str_concat(result, "\"\"");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  result = string.str_concat(result, "\"");
  return result;
}

/// Parse and unquote a single CSV field: a quoted field is unquoted and
/// doubled quotes are restored; unquoted fields pass through unchanged.
/// Parameters: s -- a single CSV field (no separators).
/// Returns: the raw field value.
/// Complexity: O(n).
pub fn csv_unescape_field(s: Str) -> Str {
  var len = string.str_len(s);
  if len >= 2 {
    var first = string.byte_at(s, 0);
    var last = string.byte_at(s, len - 1);
    if first == 34 && last == 34 {
      var inner = string.str_slice(s, 1, len - 1);
      var result = "";
      var i: Int = 0;
      var ilen = string.str_len(inner);
      while i < ilen {
        var b = string.byte_at(inner, i);
        if b == 34 && i + 1 < ilen {
          var next = string.byte_at(inner, i + 1);
          if next == 34 {
            result = string.str_concat(result, "\"");
            i = i + 2;
          } else {
            var c = string.str_slice(inner, i, i + 1);
            result = string.str_concat(result, c);
            i = i + 1;
          }
        } else {
          var c2 = string.str_slice(inner, i, i + 1);
          result = string.str_concat(result, c2);
          i = i + 1;
        }
      }
      return result;
    }
  }
  return s;
}

/// Escape tab, CR and LF characters in a TSV field as \\t, \\r, \\n.
/// Parameters: s -- the raw field value.
/// Returns: the escaped field.
/// Complexity: O(n).
pub fn tsv_escape_field(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 9 {
      result = string.str_concat(result, "\\t");
    } elif b == 13 {
      result = string.str_concat(result, "\\r");
    } elif b == 10 {
      result = string.str_concat(result, "\\n");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

/// Restore tab, CR and LF escapes in a TSV field.
/// Parameters: s -- the escaped field.
/// Returns: the raw field value.
/// Complexity: O(n).
pub fn tsv_unescape_field(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 && i + 1 < len {
      var next = string.byte_at(s, i + 1);
      if next == 116 {
        result = string.str_concat(result, "\t");
        i = i + 2;
      } elif next == 114 {
        result = string.str_concat(result, "\r");
        i = i + 2;
      } elif next == 110 {
        result = string.str_concat(result, "\n");
        i = i + 2;
      } else {
        var c = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, c);
        i = i + 1;
      }
    } else {
      var c2 = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c2);
      i = i + 1;
    }
  }
  return result;
}

/// Escape regex metacharacters in a literal string with a backslash.
/// Escapes: \ . ^ $ * + ? ( ) [ ] { } |.
/// Parameters: s -- the literal text.
/// Returns: the regex-safe text.
/// Complexity: O(n).
pub fn regex_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if _is_regex_meta(b) {
      result = string.str_concat(result, "\\");
    }
    var c = string.str_slice(s, i, i + 1);
    result = string.str_concat(result, c);
    i = i + 1;
  }
  return result;
}

/// Escape glob wildcard metacharacters (* ? [ ] and backslash) in a literal
/// string with a backslash.
/// Parameters: s -- the literal text.
/// Returns: the glob-safe text.
/// Complexity: O(n).
pub fn glob_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 42 || b == 63 || b == 91 || b == 93 || b == 92 {
      result = string.str_concat(result, "\\");
    }
    var c = string.str_slice(s, i, i + 1);
    result = string.str_concat(result, c);
    i = i + 1;
  }
  return result;
}

/// Restore escaped glob metacharacters: a backslash before a glob character
/// is removed.
/// Parameters: s -- the escaped text.
/// Returns: the literal text.
/// Complexity: O(n).
pub fn glob_unescape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 92 && i + 1 < len {
      var next = string.byte_at(s, i + 1);
      if next == 42 || next == 63 || next == 91 || next == 93 || next == 92 {
        var c = string.str_slice(s, i + 1, i + 2);
        result = string.str_concat(result, c);
        i = i + 2;
      } else {
        var c2 = string.str_slice(s, i, i + 1);
        result = string.str_concat(result, c2);
        i = i + 1;
      }
    } else {
      var c3 = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c3);
      i = i + 1;
    }
  }
  return result;
}

/// Escape a string for safe use in a POSIX shell command: every character
/// outside the safe set (alphanumerics plus _ - . / , : @ % + =) is preceded
/// by a backslash.
/// Parameters: s -- the raw argument.
/// Returns: the shell-escaped argument.
/// Complexity: O(n).
pub fn shell_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if !_is_shell_safe(b) {
      result = string.str_concat(result, "\\");
    }
    var c = string.str_slice(s, i, i + 1);
    result = string.str_concat(result, c);
    i = i + 1;
  }
  return result;
}

/// Quote a string with single quotes for a POSIX shell; embedded single
/// quotes are closed, escaped and reopened ('\'').
/// Parameters: s -- the raw argument.
/// Returns: the single-quoted argument.
/// Complexity: O(n).
pub fn shell_quote(s: Str) -> Str {
  var result = "'";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 39 {
      result = string.str_concat(result, "'\\''");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  result = string.str_concat(result, "'");
  return result;
}

/// Escape a string for safe use in a Windows cmd command line: ^ & | < >
/// ( ) " % are escaped with a caret.
/// Parameters: s -- the raw argument.
/// Returns: the cmd-escaped argument.
/// Complexity: O(n).
pub fn cmd_escape(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 94 || b == 38 || b == 124 || b == 60 || b == 62 || b == 40 || b == 41 || b == 34 || b == 37 {
      result = string.str_concat(result, "^");
    }
    var c = string.str_slice(s, i, i + 1);
    result = string.str_concat(result, c);
    i = i + 1;
  }
  return result;
}

/// Quote a string for a Windows cmd command line: wrap in double quotes and
/// double any embedded quote characters.
/// Parameters: s -- the raw argument.
/// Returns: the double-quoted argument.
/// Complexity: O(n).
pub fn cmd_quote(s: Str) -> Str {
  var result = "\"";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 34 {
      result = string.str_concat(result, "\"\"");
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  result = string.str_concat(result, "\"");
  return result;
}

// True when a CSV field needs RFC 4180 quoting.
fn _csv_needs_quote(s: Str) -> Bool {
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 44 || b == 34 || b == 13 || b == 10 {
      return true;
    }
    i = i + 1;
  }
  return false;
}

// Index of the next ';' at or after `start`, or -1.
fn _find_semicolon(s: Str, start: Int) -> Int {
  var i = start;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b == 59 {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// Decode a known entity name or numeric reference (without '&' and ';').
// Unrecognized input renders as the original text prefixed by '&'.
fn _decode_entity(inner: Str) -> Str {
  if inner == "amp" { return "&"; }
  if inner == "lt" { return "<"; }
  if inner == "gt" { return ">"; }
  if inner == "quot" { return "\""; }
  if inner == "apos" { return "'"; }
  if inner == "#39" { return "'"; }
  var ilen = string.str_len(inner);
  if ilen > 2 {
    var first = string.byte_at(inner, 0);
    if first == 35 {
      var numstr = string.str_slice(inner, 1, ilen);
      var is_hex = false;
      var second = string.byte_at(numstr, 0);
      if second == 120 || second == 88 {
        is_hex = true;
        numstr = string.str_slice(numstr, 1, string.str_len(numstr));
      }
      var cp = _parse_entity_number(numstr, is_hex);
      if cp >= 0 && cp <= 1114111 {
        return _cp_to_str(cp);
      }
    }
  }
  return string.str_concat("&", inner);
}

// Parse a decimal or hexadecimal digit string to an Int; -1 on error.
fn _parse_entity_number(s: Str, is_hex: Bool) -> Int {
  var len = string.str_len(s);
  if len == 0 {
    return -1;
  }
  var v: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(s, i);
    var d: Int = -1;
    if b >= 48 && b <= 57 {
      d = (b as Int) - 48;
    } elif is_hex {
      if b >= 97 && b <= 102 {
        d = (b as Int) - 87;
      } elif b >= 65 && b <= 70 {
        d = (b as Int) - 55;
      }
    }
    if d < 0 {
      return -1;
    }
    if is_hex {
      v = v * 16 + d;
    } else {
      v = v * 10 + d;
    }
    i = i + 1;
  }
  return v;
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

fn _is_regex_meta(b: UInt8) -> Bool {
  var v = b as Int;
  if v == 92 || v == 46 || v == 94 || v == 36 || v == 42 || v == 43 || v == 63 {
    return true;
  }
  if v == 40 || v == 41 || v == 91 || v == 93 || v == 123 || v == 125 || v == 124 {
    return true;
  }
  return false;
}

fn _is_shell_safe(b: UInt8) -> Bool {
  var v = b as Int;
  if v >= 48 && v <= 57 { return true; }
  if v >= 65 && v <= 90 { return true; }
  if v >= 97 && v <= 122 { return true; }
  if v == 95 || v == 45 || v == 46 || v == 47 || v == 44 || v == 58 {
    return true;
  }
  if v == 64 || v == 37 || v == 43 || v == 61 {
    return true;
  }
  return false;
}
