// XIOM - Conversion: Percent
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.percent

// Depends on: xiom.encoding.percent

// ============================================================================
// DEPRECATED (dedup wave, 2026-09-15): partially delegating shim over
// xiom.encoding.percent. The component and decode legs are identical to the
// canonical implementations and now delegate (via the `enc_pct` alias).
//
// `percent_encode` stays LOCAL: its full-URL mode (RFC 3986 reserved
// separators such as '/' ':' '?' '&' '=' pass through) has no counterpart in
// xiom.encoding.percent, whose `percent_encode` is the component mode (only
// unreserved). New code should use `percent_encode_component` +
// xiom.encoding.percent directly; the legacy 4-fn surface is preserved.
// ============================================================================

use xiom.encoding.percent as enc_pct;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

/// True iff c may pass through unescaped in a full URL (unreserved plus the
/// common reserved separators '-', '_', '.', '~', '/', ':', '?', '&', '=', '+',
/// ',', '$', '#', '@', '%', '!', '*', '(', ')').
fn _is_url_safe(c: Char) -> Bool {
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

/// Single-pass full-URL percent encoder (reserved separators pass through).
fn _percent_encode_url(s: Str) -> Str {
  let s_len = s.len();
  unsafe {
    var buf = malloc(s_len * 3 + 1);
    var i = 0;
    var out = 0;
    while i < s_len {
      var c = s.char_at(i);
      if _is_url_safe(c) {
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
  return _percent_encode_url(s);
}

/// Percent-decodes a URL string: '%XX' escapes are decoded; '+' is left as a
/// literal '+'. Returns Err on a truncated or malformed escape.
/// Complexity: O(n).
pub fn percent_decode(s: Str) -> Result[Str, Str] {
  return enc_pct.percent_decode(s);
}

/// Percent-encodes a single URL component (path segment / query value): only
/// unreserved characters (A-Z a-z 0-9 - _ . ~) pass through; everything else
/// -- including '/', '?', '&', '=', ':' -- is percent-encoded per UTF-8 byte.
/// Complexity: O(n).
pub fn percent_encode_component(s: Str) -> Str {
  return enc_pct.percent_encode_component(s);
}

/// Percent-decodes a URL component: '%XX' escapes are decoded and '+' is
/// converted to a space (application/x-www-form-urlencoded semantics).
/// Returns Err on a truncated or malformed escape. Complexity: O(n).
pub fn percent_decode_component(s: Str) -> Result[Str, Str] {
  return enc_pct.percent_decode_www_form(s);
}
