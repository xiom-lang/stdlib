// XIOM - Conversion: Url
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.url

// Depends on: xiom.net, xiom.encoding

// ============================================================================
// URL parsing, building, and percent-encoding helpers. Parsing is
// reimplemented locally (the canonical xiom.net.url.url_parse shares the
// function name -- same-name delegation miscompiles, BUG 25 #1); encoding
// delegates to xiom.encoding (different names -- safe).
// ============================================================================

use xiom.string;
use xiom.encoding;

// Url -- parsed URL components.
pub type Url = {
  scheme: Str;
  host: Str;
  port: Int;
  path: Str;
  query: Str;
}

/// Parse a URL into its scheme, host, port, path and query components.
/// Userinfo (user:pass@) is skipped.
/// Parameters: s -- the URL string.
/// Returns: Ok(Url) on success; Err for an empty URL or a missing host.
/// Complexity: O(n).
pub fn url_parse(s: Str) -> Result[Url, Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Err("empty URL");
  }
  var scheme = "";
  var rest = s;
  var idx = _index_of(s, "://");
  if idx >= 0 {
    scheme = string.str_slice(s, 0, idx);
    rest = string.str_slice(s, idx + 3, len);
  }
  var host = "";
  var port: Int = 0;
  var path = "/";
  var query = "";
  var authority_end = string.str_len(rest);
  var path_start = _index_of(rest, "/");
  var query_start = _index_of(rest, "?");
  if path_start >= 0 && path_start < authority_end {
    authority_end = path_start;
  }
  if query_start >= 0 && query_start < authority_end {
    authority_end = query_start;
  }
  var authority = string.str_slice(rest, 0, authority_end);
  var at_pos = _last_index_of(authority, "@");
  if at_pos >= 0 {
    authority = string.str_slice(authority, at_pos + 1, string.str_len(authority));
  }
  var colon_pos = _index_of(authority, ":");
  if colon_pos >= 0 {
    host = string.str_slice(authority, 0, colon_pos);
    var port_str = string.str_slice(authority, colon_pos + 1, string.str_len(authority));
    port = _parse_digits(port_str);
  } else {
    host = authority;
  }
  if string.str_len(host) == 0 {
    return Err("URL has no host");
  }
  var after_authority = string.str_slice(rest, authority_end, string.str_len(rest));
  if string.str_len(after_authority) > 0 {
    var path_end = string.str_len(after_authority);
    var q_pos = _index_of(after_authority, "?");
    if q_pos >= 0 && q_pos < path_end {
      path_end = q_pos;
    }
    path = string.str_slice(after_authority, 0, path_end);
    if string.str_len(path) == 0 {
      path = "/";
    }
    if q_pos >= 0 {
      query = string.str_slice(after_authority, q_pos + 1, string.str_len(after_authority));
    }
  }
  return Ok(Url{ scheme: scheme; host: host; port: port; path: path; query: query; });
}

/// Assemble a URL string from its parts.
/// Parameters: scheme -- e.g. "https"; host -- e.g. "example.com"; port -- 0
///          means "no explicit port"; path -- must start with "/"; query -- the
///          raw query string without '?' (empty means none).
/// Returns: the assembled URL.
/// Complexity: O(n).
pub fn url_build(scheme: Str, host: Str, port: Int, path: Str, query: Str) -> Str {
  var result = string.str_concat(scheme, "://");
  result = string.str_concat(result, host);
  if port > 0 {
    result = string.str_concat(result, ":");
    result = string.str_concat(result, to_string(port));
  }
  var p = path;
  if string.str_len(p) == 0 || string.byte_at(p, 0) != 47 {
    p = string.str_concat("/", p);
  }
  result = string.str_concat(result, p);
  if string.str_len(query) > 0 {
    result = string.str_concat(result, "?");
    result = string.str_concat(result, query);
  }
  return result;
}

/// Percent-encode a URL (unreserved characters A-Z a-z 0-9 - _ . ~ pass
/// through; everything else becomes %HH).
/// Parameters: s -- the text to encode.
/// Returns: the percent-encoded string.
/// Complexity: O(n).
pub fn url_encode(s: Str) -> Str {
  var enc = encoding.percent_encode(s);
  return enc;
}

/// Percent-decode a URL.
/// Parameters: s -- the encoded text.
/// Returns: Ok(decoded) on success; Err for a truncated or invalid escape.
/// Complexity: O(n).
pub fn url_decode(s: Str) -> Result[Str, Str] {
  return encoding.percent_decode(s);
}

// Byte index of needle in hay, or -1.
fn _index_of(hay: Str, needle: Str) -> Int {
  var hlen = string.str_len(hay);
  var nlen = string.str_len(needle);
  if nlen == 0 {
    return 0;
  }
  if nlen > hlen {
    return -1;
  }
  var i: Int = 0;
  while i <= hlen - nlen {
    var sub = string.str_slice(hay, i, i + nlen);
    if sub == needle {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// Last byte index of needle in hay, or -1.
fn _last_index_of(hay: Str, needle: Str) -> Int {
  var hlen = string.str_len(hay);
  var nlen = string.str_len(needle);
  if nlen == 0 {
    return hlen;
  }
  if nlen > hlen {
    return -1;
  }
  var i = hlen - nlen;
  while i >= 0 {
    var sub = string.str_slice(hay, i, i + nlen);
    if sub == needle {
      return i;
    }
    i = i - 1;
  }
  return -1;
}

// Parse leading decimal digits into an Int (0 when none).
fn _parse_digits(s: Str) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b < 48 || b > 57 {
      break;
    }
    result = result * 10 + ((b as Int) - 48);
    i = i + 1;
  }
  return result;
}
