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

// Wave 134: cached-pointer byte access + Vec builders for the escape family.
// string.byte_at / str_slice rescan the source per call (runtime strnlen),
// so the per-position scans and 1-byte slices were quadratic.
// Complexity: O(1) / O(range).
fn _raw_byte(base: *UInt8, i: Int) -> UInt8
  requires: true  // raw byte read; callers bound i against len (T007)
{
  unsafe { return *(base + i); }
}

fn _push_str(out: &mut Vec[UInt8], w: Str) {
  var k: Int = 0;
  let wl = string.str_len(w);
  let base = w.c_str();
  while k < wl {
    out.push(_raw_byte(base, k));
    k = k + 1;
  };
}

fn _slice_fast(base: *UInt8, start: Int, end: Int) -> Str
  requires: true  // raw byte copy; callers bound the range (T007)
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  unsafe {
    var i: Int = start;
    while i < end {
      out.push(*(base + i));
      i = i + 1;
    };
  };
  Str::from_utf8(out)
}

/// Escape text for HTML body content: & < > " ' become entities.
/// Parameters: s -- the input text.
/// Returns: the escaped text (strictly longer unless no specials).
/// Complexity: O(n), n = input length.
pub fn html_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 38 {
      _push_str(&mut out, "&amp;");
    } elif b == 60 {
      _push_str(&mut out, "&lt;");
    } elif b == 62 {
      _push_str(&mut out, "&gt;");
    } elif b == 34 {
      _push_str(&mut out, "&quot;");
    } elif b == 39 {
      _push_str(&mut out, "&#39;");
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Decode HTML entities back to characters: the named set (&amp; &lt; &gt;
/// &quot; &#39; &apos;) and numeric forms (&#NN; decimal, &#xHH; hex).
/// Parameters: s -- the escaped text.
/// Returns: the decoded text; unrecognized sequences pass through.
/// Complexity: O(n), n = input length.
pub fn html_unescape(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 38 {
      var semi = _find_semicolon(base, len, i);
      if semi > i + 1 {
        var inner = _slice_fast(base, i + 1, semi);
        var decoded = _decode_entity(inner);
        _push_str(&mut out, decoded);
        i = semi + 1;
      } else {
        out.push(b);
        i = i + 1;
      }
    } else {
      out.push(b);
      i = i + 1;
    }
  }
  Str::from_utf8(out)
}

/// Escape text for use inside HTML attribute quotes: same entity set as
/// html_escape plus both quote characters are always escaped.
/// Parameters: s -- the attribute value text.
/// Returns: the escaped text.
/// Complexity: O(n).
pub fn html_escape_attr(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  return html_escape(s);
}

/// Escape the five predefined XML entities: & " ' < >.
/// Parameters: s -- the input text.
/// Returns: the escaped text.
/// Complexity: O(n).
pub fn xml_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 38 {
      _push_str(&mut out, "&amp;");
    } elif b == 34 {
      _push_str(&mut out, "&quot;");
    } elif b == 39 {
      _push_str(&mut out, "&apos;");
    } elif b == 60 {
      _push_str(&mut out, "&lt;");
    } elif b == 62 {
      _push_str(&mut out, "&gt;");
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Decode the predefined XML entities back to characters.
/// Parameters: s -- the escaped text.
/// Returns: the decoded text; unrecognized sequences pass through.
/// Complexity: O(n).
pub fn xml_unescape(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 38 {
      var semi = _find_semicolon(base, len, i);
      if semi > i + 1 {
        var inner = _slice_fast(base, i + 1, semi);
        var decoded = _decode_entity(inner);
        _push_str(&mut out, decoded);
        i = semi + 1;
      } else {
        out.push(b);
        i = i + 1;
      }
    } else {
      out.push(b);
      i = i + 1;
    }
  }
  Str::from_utf8(out)
}

/// Escape and quote a field for RFC 4180 CSV output: the field is quoted when
/// it contains a comma, quote, CR or LF, and embedded quotes are doubled.
/// Parameters: s -- the raw field value.
/// Returns: the CSV-ready field.
/// Complexity: O(n).
pub fn csv_escape_field(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var len = string.str_len(s);
  let base = s.c_str();
  if !_csv_needs_quote(base, len) {
    return s;
  }
  var out: Vec[UInt8] = Vec[UInt8].new();
  out.push(34);
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i);
    if b == 34 {
      out.push(34);
      out.push(34);
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  out.push(34);
  Str::from_utf8(out)
}

/// Parse and unquote a single CSV field: a quoted field is unquoted and
/// doubled quotes are restored; unquoted fields pass through unchanged.
/// Parameters: s -- a single CSV field (no separators).
/// Returns: the raw field value.
/// Complexity: O(n).
pub fn csv_unescape_field(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var len = string.str_len(s);
  let base = s.c_str();
  if len >= 2 {
    var first = _raw_byte(base, 0);
    var last = _raw_byte(base, len - 1);
    if first == 34 && last == 34 {
      var inner = _slice_fast(base, 1, len - 1);
      var ibase = inner.c_str();
      var ilen = string.str_len(inner);
      var out: Vec[UInt8] = Vec[UInt8].new();
      var i: Int = 0;
      while i < ilen {
        var b = _raw_byte(ibase, i);
        if b == 34 && i + 1 < ilen {
          var next = _raw_byte(ibase, i + 1);
          if next == 34 {
            out.push(34);
            i = i + 2;
          } else {
            out.push(b);
            i = i + 1;
          }
        } else {
          out.push(b);
          i = i + 1;
        }
      }
      return Str::from_utf8(out);
    }
  }
  return s;
}

/// Escape tab, CR and LF characters in a TSV field as \\t, \\r, \\n.
/// Parameters: s -- the raw field value.
/// Returns: the escaped field.
/// Complexity: O(n).
pub fn tsv_escape_field(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 9 {
      _push_str(&mut out, "\\t");
    } elif b == 13 {
      _push_str(&mut out, "\\r");
    } elif b == 10 {
      _push_str(&mut out, "\\n");
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Restore tab, CR and LF escapes in a TSV field.
/// Parameters: s -- the escaped field.
/// Returns: the raw field value.
/// Complexity: O(n).
pub fn tsv_unescape_field(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 92 && i + 1 < len {
      var next = _raw_byte(base, i + 1);
      if next == 116 {
        out.push(9);
        i = i + 2;
      } elif next == 114 {
        out.push(13);
        i = i + 2;
      } elif next == 110 {
        out.push(10);
        i = i + 2;
      } else {
        out.push(b);
        i = i + 1;
      }
    } else {
      out.push(b);
      i = i + 1;
    }
  }
  Str::from_utf8(out)
}

/// Escape regex metacharacters in a literal string with a backslash.
/// Escapes: \ . ^ $ * + ? ( ) [ ] { } |.
/// Parameters: s -- the literal text.
/// Returns: the regex-safe text.
/// Complexity: O(n).
pub fn regex_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if _is_regex_meta(b) {
      out.push(92);
    }
    out.push(b);
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Escape glob wildcard metacharacters (* ? [ ] and backslash) in a literal
/// string with a backslash.
/// Parameters: s -- the literal text.
/// Returns: the glob-safe text.
/// Complexity: O(n).
pub fn glob_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 42 || b == 63 || b == 91 || b == 93 || b == 92 {
      out.push(92);
    }
    out.push(b);
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Restore escaped glob metacharacters: a backslash before a glob character
/// is removed.
/// Parameters: s -- the escaped text.
/// Returns: the literal text.
/// Complexity: O(n).
pub fn glob_unescape(s: Str) -> Str
  ensures: result.len() <= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 92 && i + 1 < len {
      var next = _raw_byte(base, i + 1);
      if next == 42 || next == 63 || next == 91 || next == 93 || next == 92 {
        out.push(next);
        i = i + 2;
      } else {
        out.push(b);
        i = i + 1;
      }
    } else {
      out.push(b);
      i = i + 1;
    }
  }
  Str::from_utf8(out)
}

/// Escape a string for safe use in a POSIX shell command: every character
/// outside the safe set (alphanumerics plus _ - . / , : @ % + =) is preceded
/// by a backslash.
/// Parameters: s -- the raw argument.
/// Returns: the shell-escaped argument.
/// Complexity: O(n).
pub fn shell_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if !_is_shell_safe(b) {
      out.push(92);
    }
    out.push(b);
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Quote a string with single quotes for a POSIX shell; embedded single
/// quotes are closed, escaped and reopened ('\'').
/// Parameters: s -- the raw argument.
/// Returns: the single-quoted argument.
/// Complexity: O(n).
pub fn shell_quote(s: Str) -> Str
  ensures: result.len() >= s.len() + 2
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  out.push(39);
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 39 {
      out.push(39);
      out.push(92);
      out.push(39);
      out.push(39);
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  out.push(39);
  Str::from_utf8(out)
}

/// Escape a string for safe use in a Windows cmd command line: ^ & | < >
/// ( ) " % are escaped with a caret.
/// Parameters: s -- the raw argument.
/// Returns: the cmd-escaped argument.
/// Complexity: O(n).
pub fn cmd_escape(s: Str) -> Str
  ensures: result.len() >= s.len()
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 94 || b == 38 || b == 124 || b == 60 || b == 62 || b == 40 || b == 41 || b == 34 || b == 37 {
      out.push(94);
    }
    out.push(b);
    i = i + 1;
  }
  Str::from_utf8(out)
}

/// Quote a string for a Windows cmd command line: wrap in double quotes and
/// double any embedded quote characters.
/// Parameters: s -- the raw argument.
/// Returns: the double-quoted argument.
/// Complexity: O(n).
pub fn cmd_quote(s: Str) -> Str
  ensures: result.len() >= s.len() + 2
{
  var out: Vec[UInt8] = Vec[UInt8].new();
  out.push(34);
  var i: Int = 0;
  var len = string.str_len(s);
  let base = s.c_str();
  while i < len {
    var b = _raw_byte(base, i);
    if b == 34 {
      out.push(34);
      out.push(34);
    } else {
      out.push(b);
    }
    i = i + 1;
  }
  out.push(34);
  Str::from_utf8(out)
}

// True when a CSV field needs RFC 4180 quoting.
fn _csv_needs_quote(base: *UInt8, len: Int) -> Bool {
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i);
    if b == 44 || b == 34 || b == 13 || b == 10 {
      return true;
    }
    i = i + 1;
  }
  return false;
}

// Index of the next ';' at or after `start`, or -1.
fn _find_semicolon(base: *UInt8, len: Int, start: Int) -> Int {
  var i = start;
  while i < len {
    var b = _raw_byte(base, i);
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
    let ibase = inner.c_str();
    var first = _raw_byte(ibase, 0);
    if first == 35 {
      var numstr = _slice_fast(ibase, 1, ilen);
      var is_hex = false;
      var nbase = numstr.c_str();
      var second = _raw_byte(nbase, 0);
      if second == 120 || second == 88 {
        is_hex = true;
        numstr = _slice_fast(nbase, 1, string.str_len(numstr));
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
  let base = s.c_str();
  var v: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = _raw_byte(base, i);
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
