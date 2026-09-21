// XIOM - Conversion: Iri
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.convert.iri

// Depends on: xiom.net

// ============================================================================
// Internationalized Resource Identifier (IRI) parsing and URI conversion.
// An IRI is a URI that may carry non-ASCII characters; iri_to_uri percent-
// encodes every byte >= 0x80 so the result is a valid ASCII URI.
// ============================================================================

use xiom.string;

/// Iri -- parsed IRI components.
pub type Iri = {
  scheme: Str;
  authority: Str;
  path: Str;
  query: Str;
  fragment: Str;
}

/// Parse an IRI into its scheme, authority, path, query and fragment.
/// Parameters: s -- the IRI string (non-ASCII characters allowed).
/// Returns: Ok(Iri) on success; Err for an empty IRI.
/// Complexity: O(n).
pub fn iri_parse(s: Str) -> Result[Iri, Str] {
  var len = string.str_len(s);
  if len == 0 {
    return Err("empty IRI");
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
  return Ok(Iri{ scheme: scheme; authority: authority; path: path; query: query; fragment: fragment; });
}

/// Convert an IRI to an ASCII-only URI by percent-encoding every byte >= 0x80
/// in the authority, path, query and fragment.
/// Parameters: s -- the IRI string.
/// Returns: Ok(URI) on success; Err for an empty IRI.
/// Complexity: O(n).
pub fn iri_to_uri(s: Str) -> Result[Str, Str] {
  var parsed = iri_parse(s);
  if !parsed.is_ok {
    return Err(parsed.error);
  }
  var i = parsed.value;
  var result = string.str_concat(_ascii(i.scheme), ":");
  if string.str_len(i.authority) > 0 {
    result = string.str_concat(result, "//");
    result = string.str_concat(result, _ascii(i.authority));
  }
  result = string.str_concat(result, _ascii(i.path));
  if string.str_len(i.query) > 0 {
    result = string.str_concat(result, "?");
    result = string.str_concat(result, _ascii(i.query));
  }
  if string.str_len(i.fragment) > 0 {
    result = string.str_concat(result, "#");
    result = string.str_concat(result, _ascii(i.fragment));
  }
  return Ok(result);
}

/// Normalize an IRI into canonical form (lowercase scheme, non-ASCII bytes
/// percent-encoded in place).
/// Parameters: s -- the IRI string.
/// Returns: Ok(canonical) on success; Err for an empty IRI.
/// Complexity: O(n).
pub fn iri_normalize(s: Str) -> Result[Str, Str] {
  var parsed = iri_parse(s);
  if !parsed.is_ok {
    return Err(parsed.error);
  }
  var i = parsed.value;
  var result = string.str_concat(_lower(i.scheme), ":");
  if string.str_len(i.authority) > 0 {
    result = string.str_concat(result, "//");
    result = string.str_concat(result, _ascii(_lower(i.authority)));
  }
  result = string.str_concat(result, _ascii(i.path));
  if string.str_len(i.query) > 0 {
    result = string.str_concat(result, "?");
    result = string.str_concat(result, _ascii(i.query));
  }
  if string.str_len(i.fragment) > 0 {
    result = string.str_concat(result, "#");
    result = string.str_concat(result, _ascii(i.fragment));
  }
  return Ok(result);
}

// Percent-encode every byte >= 0x80 as %HH; ASCII passes through.
fn _ascii(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    var v = b as Int;
    v = v & 0xFF;
    if v >= 0x80 {
      result = string.str_concat(result, "%");
      result = string.str_concat(result, _hex_digit((v >> 4) & 0x0F));
      result = string.str_concat(result, _hex_digit(v & 0x0F));
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
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

fn _hex_digit(d: Int) -> Str {
  if d < 10 {
    return string.str_slice("0123456789", d, d + 1);
  }
  return string.str_slice("ABCDEF", d - 10, d - 9);
}
