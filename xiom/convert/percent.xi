// XIOM - Conversion: Percent
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.percent

// Depends on: none

// ============================================================================
// Percent-encoding (RFC 3986) for full URLs and for path/query components.
// LOCAL implementation retained (dedup deferred 2026-09-15): the shared
// component/decode legs are behaviorally identical to xiom.encoding.percent,
// but importing that module here makes its leaf "percent" live in the same
// graph as this module. A consumer's leaf-qualified call
// (`use xiom.convert.percent;` + `percent.percent_encode`) then binds the
// WRONG module (component mode instead of this full-URL mode) -- probes
// p_pct_probe / p_b32_alias in stdlib_ws\probes; reported in COMPILER_BUGS.
// This module's percent_encode is the only full-URL mode in the stdlib, so
// a wrong-wide binding here changes results. Re-attempt the delegation once
// same-leaf alias resolution is scope-first/order-independent.
// ============================================================================

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
  fn free(ptr: *UInt8);
  fn xiom_char_at(s: Str, pos: Int) -> Char;
}

/// True iff c is an unreserved RFC 3986 character (A-Z a-z 0-9 - _ . ~).
fn _is_unreserved(c: Char) -> Bool {
  var code = c as UInt8 as Int;
  code = code & 0xFF;
  if code >= 65 && code <= 90 { return true; }
  if code >= 97 && code <= 122 { return true; }
  if code >= 48 && code <= 57 { return true; }
  if c == '-' || c == '_' || c == '.' || c == '~' { return true; }
  false
}

/// True iff c may pass through unescaped in a full URL (unreserved plus the
/// common reserved separators '-', '_', '.', '~', '/', ':', '?', '&', '=', '+',
/// ',', '$', '#', '@', '%', '!', '*', '(', ')', '[', ']').
fn _is_url_safe(c: Char) -> Bool {
  // Single `as Int` cast: `c as UInt8 as Int` miscompiles for char_at-derived
  // chars (BUG 26 #5 -- two-step cast loses the value).
  var code = c as Int;
  code = code & 0xFF;
  if code >= 65 && code <= 90 { return true; }
  if code >= 97 && code <= 122 { return true; }
  if code >= 48 && code <= 57 { return true; }
  if c == '-' || c == '_' || c == '.' || c == '~' { return true; }
  if c == '/' || c == ':' || c == '?' || c == '&' { return true; }
  if c == '=' || c == '+' || c == ',' || c == '$' { return true; }
  if c == '#' || c == '@' || c == '%' || c == '!' { return true; }
  if c == '*' || c == '(' || c == ')' { return true; }
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

/// Shared single-pass percent encoder. `component` selects between full-URL
/// (reserved separators pass through) and component (only unreserved) modes.
fn _percent_encode(s: Str, component: Bool) -> Str {
  let s_len = s.len();
  unsafe {
    var buf = malloc(s_len * 3 + 1);
    var i = 0;
    var out = 0;
    while i < s_len {
      var c = s.char_at(i);
      var safe = false;
      if component {
        safe = _is_unreserved(c);
      } else {
        safe = _is_url_safe(c);
      };
      if safe {
        var tmp = Vec[UInt8].new();
        xiom.char.encode_utf8(c, &tmp);
        var j = 0;
        while j < tmp.len() {
          buf[out] = tmp[j];
          out = out + 1;
          j = j + 1;
        };
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

/// Percent-encodes a full URL string. Reserved separators ('/', ':', '?',
/// '&', '=', '+', '#', '@', etc.) pass through; all other non-unreserved
/// characters are percent-encoded per UTF-8 byte. Complexity: O(n).
pub fn percent_encode(s: Str) -> Str {
  _percent_encode(s, false)
}

/// Percent-decodes a URL string: '%XX' escapes are decoded; '+' is left as a
/// literal '+'. Returns Err on a truncated or malformed escape.
/// Complexity: O(n).
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

/// Percent-encodes a single URL component (path segment / query value): only
/// unreserved characters (A-Z a-z 0-9 - _ . ~) pass through; everything else
/// -- including '/', '?', '&', '=', ':' -- is percent-encoded per UTF-8 byte.
/// Complexity: O(n).
pub fn percent_encode_component(s: Str) -> Str {
  _percent_encode(s, true)
}

/// Percent-decodes a URL component: '%XX' escapes are decoded and '+' is
/// converted to a space (application/x-www-form-urlencoded semantics).
/// Returns Err on a truncated or malformed escape. Complexity: O(n).
pub fn percent_decode_component(s: Str) -> Result[Str, Str] {
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
