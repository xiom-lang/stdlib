// XIOM - Conversion: Uri
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.uri

// Depends on: xiom.net

// ============================================================================
// URI parsing, normalization, and resolution helpers (RFC 3986). The
// canonical implementation lives in xiom.net; parsing is reimplemented
// locally with a generic scheme/authority/path/query/fragment split, dot
// segment removal, and relative-reference resolution.
// ============================================================================

use xiom.string;

// Uri — parsed URI components.
pub type Uri = {
  scheme: Str;
  authority: Str;
  path: Str;
  query: Str;
  fragment: Str;
}

/// Parse a URI into its scheme, authority, path, query and fragment.
/// Parameters: s — the URI string.
/// Returns: Ok(Uri) on success; Err for an empty URI.
/// Complexity: O(n).
pub fn uri_parse(s: Str) -> Result[Uri, Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Err("empty URI");
  }
  var scheme = "";
  var rest = s;
  var colon = _index_of(s, ":");
  var slash = _index_of(s, "/");
  if colon >= 0 && (slash < 0 || colon < slash) {
    scheme = string.str_slice(s, 0, colon);
    rest = string.str_slice(s, colon + 1, len);
  }
  var authority = "";
  var path = rest;
  if string.str_len(path) >= 2 {
    var b0 = string.byte_at(path, 0);
    var b1 = string.byte_at(path, 1);
    if b0 == 47 && b1 == 47 {
      var path_body = string.str_slice(path, 2, string.str_len(path));
      var a_end = string.str_len(path_body);
      var p_start = _index_of(path_body, "/");
      var q_start = _index_of(path_body, "?");
      var f_start = _index_of(path_body, "#");
      if p_start >= 0 && p_start < a_end {
        a_end = p_start;
      }
      if q_start >= 0 && q_start < a_end {
        a_end = q_start;
      }
      if f_start >= 0 && f_start < a_end {
        a_end = f_start;
      }
      authority = string.str_slice(path_body, 0, a_end);
      path = string.str_slice(path_body, a_end, string.str_len(path_body));
    }
  }
  var query = "";
  var fragment = "";
  var q_idx = _index_of(path, "?");
  var f_idx = _index_of(path, "#");
  var path_len = string.str_len(path);
  if q_idx >= 0 && f_idx >= 0 && f_idx > q_idx {
    query = string.str_slice(path, q_idx + 1, f_idx);
    fragment = string.str_slice(path, f_idx + 1, path_len);
  } elif q_idx >= 0 {
    query = string.str_slice(path, q_idx + 1, path_len);
  } elif f_idx >= 0 {
    fragment = string.str_slice(path, f_idx + 1, path_len);
  }
  if q_idx >= 0 {
    path = string.str_slice(path, 0, q_idx);
  } elif f_idx >= 0 {
    path = string.str_slice(path, 0, f_idx);
  }
  if string.str_len(path) == 0 {
    path = "/";
  }
  return Ok(Uri{ scheme: scheme; authority: authority; path: path; query: query; fragment: fragment; });
}

/// Normalize a URI into canonical form: lowercase scheme, remove dot
/// segments from the path, and keep the authority/query/fragment.
/// Parameters: s — the URI string.
/// Returns: Ok(canonical) on success; Err for an empty URI.
/// Complexity: O(n).
pub fn uri_normalize(s: Str) -> Result[Str, Str] {
  var parsed = uri_parse(s);
  if !parsed.is_ok {
    return Err(parsed.error);
  }
  var u = parsed.value;
  var result = string.str_concat(_lower(u.scheme), ":");
  if string.str_len(u.authority) > 0 {
    result = string.str_concat(result, "//");
    result = string.str_concat(result, _lower(u.authority));
  }
  result = string.str_concat(result, _remove_dot_segments(u.path));
  if string.str_len(u.query) > 0 {
    result = string.str_concat(result, "?");
    result = string.str_concat(result, u.query);
  }
  if string.str_len(u.fragment) > 0 {
    result = string.str_concat(result, "#");
    result = string.str_concat(result, u.fragment);
  }
  return Ok(result);
}

/// Resolve a relative URI against a base URI (RFC 3986 §5).
/// Parameters: base — the absolute base URI; rel — the reference (may be
///          absolute or relative).
/// Returns: Ok(resolved) on success; Err when parsing fails.
/// Complexity: O(n).
pub fn uri_resolve(base: Str, rel: Str) -> Result[Str, Str] {
  var rel_parsed = uri_parse(rel);
  if !rel_parsed.is_ok {
    return Err(rel_parsed.error);
  }
  var r = rel_parsed.value;
  if string.str_len(r.scheme) > 0 {
    return uri_normalize(rel);
  }
  var base_parsed = uri_parse(base);
  if !base_parsed.is_ok {
    return Err(base_parsed.error);
  }
  var b = base_parsed.value;
  var scheme = b.scheme;
  var authority = b.authority;
  var path = r.path;
  var is_abs = false;
  if string.str_len(path) > 0 {
    var p0 = string.byte_at(path, 0);
    if p0 == 47 {
      is_abs = true;
    }
  }
  if !is_abs && string.str_len(r.authority) == 0 {
    if string.str_len(path) > 0 {
      path = _merge_paths(b.path, path);
    } else {
      path = b.path;
    }
  }
  if string.str_len(r.authority) > 0 {
    authority = r.authority;
  }
  var result = string.str_concat(scheme, ":");
  if string.str_len(authority) > 0 {
    result = string.str_concat(result, "//");
    result = string.str_concat(result, authority);
  }
  result = string.str_concat(result, _remove_dot_segments(path));
  if string.str_len(r.query) > 0 {
    result = string.str_concat(result, "?");
    result = string.str_concat(result, r.query);
  }
  if string.str_len(r.fragment) > 0 {
    result = string.str_concat(result, "#");
    result = string.str_concat(result, r.fragment);
  }
  return Ok(result);
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

// Remove "." and ".." dot segments per RFC 3986 §5.2.4 (keeps a leading "/").
fn _remove_dot_segments(path: Str) -> Str {
  var parts = _split(path, "/");
  var stack = Vec[Str].new();
  var i: Int = 0;
  while i < parts.len() {
    var seg = parts[i];
    if seg == "." {
      // skip
    } elif seg == ".." {
      if stack.len() > 0 {
        stack.pop();
      }
    } else {
      stack.push(seg);
    }
    i = i + 1;
  }
  var result = "";
  var j: Int = 0;
  while j < stack.len() {
    if j > 0 {
      result = string.str_concat(result, "/");
    }
    result = string.str_concat(result, stack[j]);
    j = j + 1;
  }
  if string.str_len(result) == 0 {
    return "/";
  }
  return result;
}

// Merge a base path directory with a relative path.
fn _merge_paths(base_path: Str, rel: Str) -> Str {
  var last_slash = _last_index_of(base_path, "/");
  var dir = "";
  if last_slash >= 0 {
    dir = string.str_slice(base_path, 0, last_slash + 1);
  }
  return string.str_concat(dir, rel);
}

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

// Split a string on every '/' (no empty delimiters).
fn _split(s: Str, delim: Str) -> Vec[Str] {
  var result = Vec[Str].new();
  var dlen = string.str_len(delim);
  var slen = string.str_len(s);
  var start: Int = 0;
  var pos: Int = 0;
  while pos < slen {
    if pos + dlen <= slen {
      var sub = string.str_slice(s, pos, pos + dlen);
      if sub == delim {
        result.push(string.str_slice(s, start, pos));
        pos = pos + dlen;
        start = pos;
      } else {
        pos = pos + 1;
      }
    } else {
      pos = pos + 1;
    }
  }
  result.push(string.str_slice(s, start, slen));
  return result;
}

// ASCII lowercasing (non-ASCII passes through).
fn _lower(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b >= 65 && b <= 90 {
      result = string.str_concat(result, _byte_str((b as Int) + 32));
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

// Render a single byte value as a one-character string.
fn _byte_str(v: Int) -> Str {
  var buf = Vec[UInt8].new();
  buf.push(v as UInt8);
  return Str::from_utf8(buf);
}
