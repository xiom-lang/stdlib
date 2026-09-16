// XIOM - Conversion: Urn
// Copyright (c) 2026 Eleftherios Notas - XIOM Foundation
// Licensed under the Apache-2.0 license.

module xiom.convert.urn

// Depends on: none

// ============================================================================
// URN (RFC 8141) parsing, validation, and building helpers. A URN has the
// form "urn:<NID>:<NSS>[?+<R>][?=<Q>]"; this module parses the NID and NSS
// and captures any r/q component as the third tuple element.
// ============================================================================

use xiom.string;

/// Parse a URN into its (nid, nss, rq) components.
/// Parameters: s -- the URN string.
/// Returns: Ok((nid, nss, rq)) on success, where rq is the concatenation of
///          the r-component and q-component ("" when absent); Err otherwise.
/// Complexity: O(n).
pub fn urn_parse(s: Str) -> Result[(Str, Str, Str), Str] {
  if string.str_len(s) < 7 {
    return Err("URN too short");
  }
  var head = string.str_slice(s, 0, 4);
  var head_l = _lower(head);
  if head_l != "urn:" {
    return Err("missing urn: prefix");
  }
  var body = string.str_slice(s, 4, string.str_len(s));
  var qidx = _index_of(body, "?");
  var nss_part = body;
  var rq = "";
  if qidx >= 0 {
    nss_part = string.str_slice(body, 0, qidx);
    rq = string.str_slice(body, qidx, string.str_len(body));
  }
  var nidx = _index_of(nss_part, ":");
  if nidx <= 0 {
    return Err("missing NID separator");
  }
  var nid = string.str_slice(nss_part, 0, nidx);
  var nss = string.str_slice(nss_part, nidx + 1, string.str_len(nss_part));
  if string.str_len(nss) == 0 {
    return Err("empty NSS");
  }
  if !_valid_nid(nid) {
    return Err("invalid NID");
  }
  if !_valid_nss(nss) {
    return Err("invalid NSS");
  }
  return Ok((nid, nss, rq));
}

/// Check that a string is a valid URN.
/// Parameters: s -- the candidate URN string.
/// Returns: true when the URN structure is valid.
/// Complexity: O(n).
pub fn urn_is_valid(s: Str) -> Bool {
  var r = urn_parse(s);
  return r.is_ok;
}

/// Assemble a URN from a namespace identifier and specific string.
/// Parameters: nid -- the namespace identifier (2-32 chars, alphanumeric plus
///          hyphen, not starting or ending with hyphen); nss -- the namespace
///          specific string.
/// Returns: "urn:<nid>:<nss>".
/// Complexity: O(n).
pub fn urn_build(nid: Str, nss: Str) -> Str {
  var result = "urn:";
  result = string.str_concat(result, nid);
  result = string.str_concat(result, ":");
  result = string.str_concat(result, nss);
  return result;
}

// NID rules: 2..32 chars, alphanumeric + '-', not starting/ending with '-'.
fn _valid_nid(nid: Str) -> Bool {
  var len = string.str_len(nid);
  if len < 2 || len > 32 {
    return false;
  }
  var first = string.byte_at(nid, 0);
  var last = string.byte_at(nid, len - 1);
  if first == 45 || last == 45 {
    return false;
  }
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(nid, i);
    if !_is_alnum(b) && b != 45 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

// NSS rules: non-empty, no whitespace, no control bytes, no '?', no '#'.
fn _valid_nss(nss: Str) -> Bool {
  var len = string.str_len(nss);
  if len == 0 {
    return false;
  }
  var i: Int = 0;
  while i < len {
    var b = string.byte_at(nss, i);
    var v = b as Int;
    v = v & 0xFF;
    if v < 33 || v == 63 || v == 35 {
      return false;
    }
    i = i + 1;
  }
  return true;
}

fn _is_alnum(b: UInt8) -> Bool {
  var v = b as Int;
  if v >= 48 && v <= 57 {
    return true;
  }
  if v >= 65 && v <= 90 {
    return true;
  }
  if v >= 97 && v <= 122 {
    return true;
  }
  return false;
}

fn _lower(s: Str) -> Str {
  var result = "";
  var i: Int = 0;
  var len = string.str_len(s);
  while i < len {
    var b = string.byte_at(s, i);
    if b >= 65 && b <= 90 {
      var buf = Vec[UInt8].new();
      buf.push(((b as Int) + 32) as UInt8);
      result = string.str_concat(result, Str::from_utf8(buf));
    } else {
      var c = string.str_slice(s, i, i + 1);
      result = string.str_concat(result, c);
    }
    i = i + 1;
  }
  return result;
}

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
