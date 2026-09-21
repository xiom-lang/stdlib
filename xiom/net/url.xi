// XIOM -- URL Parsing Utilities (xiom.net.url)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure URL/URI parsing helpers. All string operations are implemented
// locally on top of the safe xiom.string / xiom.encoding primitives so the
// module works independently of xiom.net's socket layer.

module xiom.net.url

use xiom.net.UrlParts;
use xiom.string;
use xiom.encoding;

fn hex_digit_value(b: UInt8) -> Int {
  let c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  -1
}

// idx_of returns the byte index of needle in hay, or -1 if not found.
fn idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
}

// last_idx_of returns the last byte index of needle in hay, or -1.
fn last_idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return hlen; }
  if nlen > hlen { return -1; }
  var i = hlen - nlen;
  while i >= 0 {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i - 1;
  }
  -1
}

// split splits s on every occurrence of delim. Empty delimiters split into
// single characters.
fn split(s: Str, delim: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let dlen = delim.len();
  if dlen == 0 {
    var i = 0;
    while i < s.len() {
      result.push(string.str_slice(s, i, i + 1));
      i = i + 1;
    }
    return result;
  }
  var start = 0;
  var pos = 0;
  let slen = s.len();
  while pos < slen {
    if pos + dlen <= slen && string.str_slice(s, pos, pos + dlen) == delim {
      result.push(string.str_slice(s, start, pos));
      pos = pos + dlen;
      start = pos;
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  result
}

// str_to_int parses leading decimal digits into an integer.
fn str_to_int(s: Str) -> Int {
  var result = 0;
  var i = 0;
  let len = s.len();
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 { break; }
    result = result * 10 + (b as Int - 48);
    i = i + 1;
  }
  result
}

fn starts_with(s: Str, prefix: Str) -> Bool {
  let plen = prefix.len();
  if plen > s.len() { return false; }
  string.str_slice(s, 0, plen) == prefix
}

/// url_parse parses a URL into its scheme/host/port/path/query/fragment
/// components. Userinfo (user:pass@) is skipped.
pub fn url_parse(url: Str) -> Result[UrlParts, Str] {
  let len = url.len();
  if len == 0 {
    return Err("empty URL");
  }
  var scheme = "";
  var rest = url;
  let scheme_pos = idx_of(url, "://");
  if scheme_pos >= 0 {
    scheme = string.str_slice(url, 0, scheme_pos);
    rest = string.str_slice(url, scheme_pos + 3, len);
  }
  var host = "";
  var port = 0;
  var path = "/";
  var query = "";
  var fragment = "";
  var authority_end = rest.len();
  let path_start = idx_of(rest, "/");
  let query_start = idx_of(rest, "?");
  let frag_start = idx_of(rest, "#");
  if path_start >= 0 && path_start < authority_end { authority_end = path_start; }
  if query_start >= 0 && query_start < authority_end { authority_end = query_start; }
  if frag_start >= 0 && frag_start < authority_end { authority_end = frag_start; }
  var authority = string.str_slice(rest, 0, authority_end);
  let at_pos = last_idx_of(authority, "@");
  if at_pos >= 0 {
    authority = string.str_slice(authority, at_pos + 1, authority.len());
  }
  let colon_pos = idx_of(authority, ":");
  if colon_pos >= 0 {
    host = string.str_slice(authority, 0, colon_pos);
    let port_str = string.str_slice(authority, colon_pos + 1, authority.len());
    port = str_to_int(port_str);
  } else {
    host = authority;
  }
  if host.len() == 0 {
    return Err("URL has no host");
  }
  let after_authority = string.str_slice(rest, authority_end, rest.len());
  if after_authority.len() > 0 {
    var path_end = after_authority.len();
    let q_pos = idx_of(after_authority, "?");
    let f_pos = idx_of(after_authority, "#");
    if q_pos >= 0 && q_pos < path_end { path_end = q_pos; }
    if f_pos >= 0 && f_pos < path_end { path_end = f_pos; }
    path = string.str_slice(after_authority, 0, path_end);
    if path.len() == 0 { path = "/"; }
    if q_pos >= 0 {
      var q_end = after_authority.len();
      if f_pos >= 0 && f_pos > q_pos { q_end = f_pos; }
      query = string.str_slice(after_authority, q_pos + 1, q_end);
    }
    if f_pos >= 0 {
      fragment = string.str_slice(after_authority, f_pos + 1, after_authority.len());
    }
  }
  Ok(UrlParts{ scheme: scheme; host: host; port: port; path: path; query: query; fragment: fragment; })
}

/// url_decode_component percent-decodes %XX sequences. '+' is left as-is
/// (component semantics -- '+' is only a space in form-encoding).
pub fn url_decode_component(s: Str) -> Result[Str, Str] {
  let len = s.len();
  if len == 0 {
    return Ok("");
  }
  var buf: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < len {
    let b = s.byte_at(i);
    if b == 37 {
      if i + 2 >= len {
        return Err("truncated percent escape in url component");
      }
      let hi = hex_digit_value(s.byte_at(i + 1));
      let lo = hex_digit_value(s.byte_at(i + 2));
      if hi < 0 || lo < 0 {
        return Err("invalid percent escape in url component");
      }
      buf.push(((hi << 4) | lo) as UInt8);
      i = i + 3;
    } else {
      buf.push(b);
      i = i + 1;
    }
  }
  Ok(Str::from_utf8(buf))
}

/// url_encode_component percent-encodes everything except the unreserved
/// characters A-Z a-z 0-9 - _ . ~ (reuses xiom.encoding.percent_encode).
pub fn url_encode_component(s: Str) -> Result[Str, Str] {
  // Bind the module-qualified Str-returning call to a local first (compiler
  // bug: using its result directly in an expression emits inttoptr of a ptr).
  let enc = encoding.percent_encode(s);
  Ok(enc)
}

/// url_query_parse splits a query string on '&' and each pair on the first
/// '=', percent-decoding both sides and converting '+' to a space
/// (application/x-www-form-urlencoded semantics).
pub fn url_query_parse(query: Str) -> Vec[(Str, Str)] {
  var result: Vec[(Str, Str)] = Vec[(Str, Str)]::new();
  if query.len() == 0 {
    return result;
  }
  let pairs = split(query, "&");
  var i = 0;
  while i < pairs.len() {
    let pair = pairs[i];
    let eq = idx_of(pair, "=");
    var key: Str = "";
    var value: Str = "";
    if eq >= 0 {
      key = string.str_slice(pair, 0, eq);
      value = string.str_slice(pair, eq + 1, pair.len());
    } else {
      key = string.str_slice(pair, 0, pair.len());
    }
    let key_dec = encoding.url_decode(key);
    let val_dec = encoding.url_decode(value);
    match key_dec {
      Ok(d) => { key = d; }
      Err(_) => { }
    }
    match val_dec {
      Ok(d) => { value = d; }
      Err(_) => { }
    }
    result.push((key, value));
    i = i + 1;
  }
  result
}
/// url_query_build joins key/value pairs as k=v separated by '&', applying
/// component encoding to both keys and values.
pub fn url_query_build(pairs: Vec[(Str, Str)]) -> Str {
  var result = "";
  var i = 0;
  while i < pairs.len() {
    if i > 0 {
      result = result + "&";
    }
    // Bind module-qualified Str-returning calls to locals first (compiler
    // bug: direct use in expressions emits inttoptr of a ptr).
    let k_enc = encoding.percent_encode(pairs[i].0);
    let v_enc = encoding.percent_encode(pairs[i].1);
    result = result + k_enc;
    result = result + "=";
    result = result + v_enc;
    i = i + 1;
  }
  result
}

// normalize_path removes "." and ".." dot segments, collapses duplicate
// slashes, and preserves a leading slash.
fn normalize_path(path: Str) -> Str {
  let parts = split(path, "/");
  var stack: Vec[Str] = Vec[Str]::new();
  var i = 0;
  while i < parts.len() {
    let seg = parts[i];
    if seg == "." {
      // skip
    } elif seg == ".." {
      if stack.len() > 0 {
        stack.pop();
      }
    } elif seg.len() == 0 && stack.len() > 0 {
      // collapse duplicate slashes
    } else {
      stack.push(seg);
    }
    i = i + 1;
  }
  var result = "";
  var j = 0;
  while j < stack.len() {
    if j > 0 {
      result = result + "/";
    }
    result = result + stack[j];
    j = j + 1;
  }
  if result.len() == 0 {
    return "/";
  }
  result
}

/// url_normalize lowercases the scheme and host, strips the default port,
/// and removes dot segments from the path. Query and fragment are kept.
pub fn url_normalize(url: Str) -> Result[Str, Str] {
  let parsed = url_parse(url);
  match parsed {
    Ok(p) => {
      let scheme = string.str_lower(p.scheme);
      let host = string.str_lower(p.host);
      var result = scheme + "://" + host;
      if p.port > 0 {
        let is_default = (scheme == "http" && p.port == 80) || (scheme == "https" && p.port == 443);
        if !is_default {
          result = result + ":" + p.port.to_str();
        }
      }
      result = result + normalize_path(p.path);
      if p.query.len() > 0 {
        result = result + "?" + p.query;
      }
      if p.fragment.len() > 0 {
        result = result + "#" + p.fragment;
      }
      Ok(result)
    }
    Err(e) => Err(e),
  }
}

/// url_is_absolute returns true if the URL carries a scheme (a ':' before
/// any '/').
pub fn url_is_absolute(url: Str) -> Bool {
  let len = url.len();
  var i = 0;
  while i < len {
    let b = url.byte_at(i);
    if b == 58 {
      return true;
    }
    if b == 47 {
      return false;
    }
    i = i + 1;
  }
  false
}

// path_dir returns the directory portion of a path, including the trailing
// slash. "/x/y" -> "/x/"; "/x" -> "/".
fn path_dir(path: Str) -> Str {
  let last_slash = last_idx_of(path, "/");
  if last_slash <= 0 {
    return "/";
  }
  string.str_slice(path, 0, last_slash + 1)
}

/// url_join resolves a relative reference against a base URL (RFC 3986 S5.3
/// merge), then normalizes dot segments. If the reference carries its own
/// scheme it is returned unchanged.
pub fn url_join(base: Str, relative: Str) -> Result[Str, Str] {
  if url_is_absolute(relative) {
    return Ok(relative);
  }
  let base_res = url_parse(base);
  match base_res {
    Ok(bp) => {
      if starts_with(relative, "//") {
        return Ok(bp.scheme + ":" + relative);
      }
      var merged = bp.scheme + "://" + bp.host;
      if bp.port > 0 {
        merged = merged + ":" + bp.port.to_str();
      }
      if starts_with(relative, "/") {
        merged = merged + relative;
      } else {
        merged = merged + path_dir(bp.path) + relative;
      }
      url_normalize(merged)
    }
    Err(e) => Err(e),
  }
}
