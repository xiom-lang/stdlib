// XIOM - Encoding: Percent
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.encoding.percent

// Depends on: xiom.string

// ============================================================================
// Percent (URL) encoding and decoding for bytes, components, and forms.
// Implemented locally (same-name delegation to xiom.encoding crashes the
// compiler -- see xiom.convert.base58 for the probe reference).
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// True iff c is an unreserved RFC 3986 character (A-Z a-z 0-9 - _ . ~).
fn _is_unreserved(c: Char) -> Bool {
  var code = to_int_from_char(c);
  if code >= 65 && code <= 90 { return true; }
  if code >= 97 && code <= 122 { return true; }
  if code >= 48 && code <= 57 { return true; }
  if c == '-' || c == '_' || c == '.' || c == '~' { return true; }
  false
}

/// Uppercase hex character for a nibble value (0-15).
fn _pct_nibble_upper(n: Int) -> UInt8 {
  if n < 10 { return (48 + n) as UInt8; }
  (55 + n) as UInt8
}

/// Numeric value of a hex byte (0-9, a-f, A-F); -1 for any other byte.
fn _pct_hex_value(c: UInt8) -> Int {
  var code = c as Int;
  code = code & 0xFF;
  if code >= 48 && code <= 57 { return code - 48; }
  if code >= 97 && code <= 102 { return code - 87; }
  if code >= 65 && code <= 70 { return code - 55; }
  -1
}

/// Shared single-pass percent encoder over UTF-8 code points. `spaces_as_plus`
/// selects form semantics (space -> '+', all other non-unreserved bytes %XX).
fn _percent_encode(s: Str, spaces_as_plus: Bool) -> Str {
  let s_len = s.len();
  unsafe {
    var buf = malloc(s_len * 3 + 1);
    var i = 0;
    var out = 0;
    while i < s_len {
      var c = s.char_at(i);
      if _is_unreserved(c) {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp[j];
          out = out + 1;
          j = j + 1;
        };
      } elif spaces_as_plus && c == ' ' {
        buf[out] = 43;
        out = out + 1;
      } else {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          var b = tmp[j] as Int;
          b = b & 0xFF;
          buf[out] = 37;
          buf[out + 1] = _pct_nibble_upper(b >> 4);
          buf[out + 2] = _pct_nibble_upper(b & 15);
          out = out + 3;
          j = j + 1;
        };
      };
      i = i + xiom.char.len_utf8(c);
    };
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

/// Percent-encodes every non-unreserved character of `s` per its UTF-8 bytes;
/// spaces become '%20'. Unreserved characters (A-Z a-z 0-9 - _ . ~) pass
/// through. Complexity: O(n).
pub fn percent_encode(s: Str) -> Str {
  _percent_encode(s, false)
}

/// Decodes percent-escapes in `s`. '+' is left as a literal '+'. Returns Err
/// on a truncated or malformed escape. Complexity: O(n).
pub fn percent_decode(s: Str) -> Result[Str, Str] {
  let len = s.len();
  if len == 0 { return Ok(""); };
  unsafe {
    var buf = malloc(len + 1);
    var i = 0;
    var out = 0;
    while i < len {
      var c = s.char_at(i);
      if c == '%' {
        if i + 2 >= len {
          return Err("truncated percent escape");
        };
        var hi = _pct_hex_value(string.byte_at(s, i + 1));
        var lo = _pct_hex_value(string.byte_at(s, i + 2));
        if hi < 0 || lo < 0 {
          return Err("invalid percent escape");
        };
        buf[out] = ((hi << 4) | lo) as UInt8;
        out = out + 1;
        i = i + 3;
      } else {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp[j];
          out = out + 1;
          j = j + 1;
        };
        i = i + xiom.char.len_utf8(c);
      };
    };
    buf[out] = 0;
    return Ok(Str.from_cstring(buf));
  }
}

/// Percent-encodes a single URL path or query component: only unreserved
/// characters pass through; everything else -- including '/', '?', '&', '=' --
/// is percent-encoded per UTF-8 byte. Complexity: O(n).
pub fn percent_encode_component(s: Str) -> Str {
  _percent_encode(s, false)
}

/// Decodes a URL component: '%XX' escapes are decoded; '+' is left as a
/// literal '+'. Returns Err on a truncated or malformed escape.
/// Complexity: O(n).
pub fn percent_decode_component(s: Str) -> Result[Str, Str] {
  percent_decode(s)
}

/// Percent-encodes raw bytes: unreserved ASCII bytes pass through, all other
/// bytes become '%XX'. Complexity: O(n).
pub fn percent_encode_bytes(data: &Vec[UInt8]) -> Str {
  let len = data.len();
  unsafe {
    var buf = malloc(len * 3 + 1);
    var i = 0;
    var out = 0;
    while i < len {
      var b = data[i] as Int;
      b = b & 0xFF;
      var safe = (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || (b >= 48 && b <= 57)
          || b == 45 || b == 95 || b == 46 || b == 126;
      if safe {
        buf[out] = b as UInt8;
        out = out + 1;
      } else {
        buf[out] = 37;
        buf[out + 1] = _pct_nibble_upper(b >> 4);
        buf[out + 2] = _pct_nibble_upper(b & 15);
        out = out + 3;
      };
      i = i + 1;
    };
    buf[out] = 0;
    return Str.from_cstring(buf);
  }
}

/// Decodes percent-escapes into bytes; '+' is left as a literal '+'. Returns
/// Err on a truncated or malformed escape. Complexity: O(n).
pub fn percent_decode_bytes(s: Str) -> Result[Vec[UInt8], Str] {
  var result = Vec[UInt8].new();
  let len = s.len();
  var i = 0;
  while i < len {
    var c = s.char_at(i);
    if c == '%' {
      if i + 2 >= len {
        return Err("truncated percent escape");
      };
      var hi = _pct_hex_value(string.byte_at(s, i + 1));
      var lo = _pct_hex_value(string.byte_at(s, i + 2));
      if hi < 0 || lo < 0 {
        return Err("invalid percent escape");
      };
      result.push(((hi << 4) | lo) as UInt8);
      i = i + 3;
    } else {
      var tmp = Vec[UInt8].new();
      xiom.char.encode_utf8(c, &tmp);
      var j = 0;
      while j < tmp.len() {
        result.push(tmp[j]);
        j = j + 1;
      };
      i = i + xiom.char.len_utf8(c);
    };
  };
  Ok(result)
}

/// Encodes as application/x-www-form-urlencoded: spaces become '+', all other
/// non-unreserved characters are percent-encoded per UTF-8 byte.
/// Complexity: O(n).
pub fn percent_encode_www_form(s: Str) -> Str {
  _percent_encode(s, true)
}

/// Decodes a form body: '+' becomes a space and '%XX' escapes are decoded.
/// Returns Err on a truncated or malformed escape. Complexity: O(n).
pub fn percent_decode_www_form(s: Str) -> Result[Str, Str] {
  let len = s.len();
  if len == 0 { return Ok(""); };
  unsafe {
    var buf = malloc(len + 1);
    var i = 0;
    var out = 0;
    while i < len {
      var c = s.char_at(i);
      if c == '%' {
        if i + 2 >= len {
          return Err("truncated percent escape");
        };
        var hi = _pct_hex_value(string.byte_at(s, i + 1));
        var lo = _pct_hex_value(string.byte_at(s, i + 2));
        if hi < 0 || lo < 0 {
          return Err("invalid percent escape");
        };
        buf[out] = ((hi << 4) | lo) as UInt8;
        out = out + 1;
        i = i + 3;
      } elif c == '+' {
        buf[out] = 32;
        out = out + 1;
        i = i + 1;
      } else {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp[j];
          out = out + 1;
          j = j + 1;
        };
        i = i + xiom.char.len_utf8(c);
      };
    };
    buf[out] = 0;
    return Ok(Str.from_cstring(buf));
  }
}
