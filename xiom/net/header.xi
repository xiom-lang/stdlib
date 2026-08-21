// XIOM - Network: HTTP Headers
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.header

// Depends on: xiom.net, xiom.string

// ============================================================================
// Helpers for working with HTTP header lists stored as (name, value) pairs.
// Header names are matched case-insensitively per RFC 7230. All functions are
// pure string operations.
// ============================================================================

use xiom.string;

// Tuple (Str, Str) holds a single header as (name, value).

// is_ws_byte returns true for space and tab.
fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9
}

// trim_ws trims leading and trailing spaces and tabs.
fn trim_ws(s: Str) -> Str {
  let len = s.len();
  var start = 0;
  var end = len;
  while start < end && is_ws_byte(s.byte_at(start)) {
    start = start + 1;
  }
  while end > start && is_ws_byte(s.byte_at(end - 1)) {
    end = end - 1;
  }
  string.str_slice(s, start, end)
}

// lower returns the lowercase form of s.
fn lower(s: Str) -> Str {
  string.str_lower(s)
}

// matches_name returns true when the stored header name equals name under
// case-insensitive comparison.
fn matches_name(stored: Str, name: Str) -> Bool {
  lower(stored) == lower(name)
}

/// Fetch the first value for a header name (case-insensitive).
/// Parameters: headers -- the header list; name -- the header name.
/// Returns: Some(first value) when present, None otherwise.
/// Complexity: O(n) with n = header count. Pure.
pub fn header_get(headers: &Vec[(Str, Str)], name: Str) -> Option[Str] {
  var i = 0;
  while i < headers.len() {
    let h = headers[i];
    if matches_name(h.0, name) {
      return Some(h.1);
    }
    i = i + 1;
  }
  None
}

/// Set a header, replacing any existing entry with the same name
/// (case-insensitive); the new entry keeps the caller's spelling.
/// Parameters: headers -- the mutable header list; name -- the header name;
///          value -- the header value.
/// Returns: Unit.
/// Complexity: O(n) with n = header count. Pure.
pub fn header_set(headers: &mut Vec[(Str, Str)], name: Str, value: Str) {
  var i = 0;
  while i < headers.len() {
    let h = headers[i];
    if matches_name(h.0, name) {
      let _ = headers.remove(i);
      headers.insert(i, (name, value));
      return;
    }
    i = i + 1;
  }
  headers.push((name, value));
}

/// Remove all entries for a header name (case-insensitive).
/// Parameters: headers -- the mutable header list; name -- the header name.
/// Returns: true when at least one entry was removed.
/// Complexity: O(n) with n = header count. Pure.
pub fn header_remove(headers: &mut Vec[(Str, Str)], name: Str) -> Bool {
  var removed = false;
  var i = 0;
  while i < headers.len() {
    let h = headers[i];
    if matches_name(h.0, name) {
      let _ = headers.remove(i);
      removed = true;
    } else {
      i = i + 1;
    }
  }
  removed
}

/// Test if a header name is present (case-insensitive).
/// Parameters: headers -- the header list; name -- the header name.
/// Returns: true when at least one entry matches.
/// Complexity: O(n) with n = header count. Pure.
pub fn header_contains(headers: &Vec[(Str, Str)], name: Str) -> Bool {
  var i = 0;
  while i < headers.len() {
    let h = headers[i];
    if matches_name(h.0, name) {
      return true;
    }
    i = i + 1;
  }
  false
}

/// Parse one "Name: value" line into a (name, value) pair.
/// Parameters: line -- a single header line (may include a trailing CRLF).
/// Returns: Some((name, value)) for a well-formed line, None otherwise. The
///          name is preserved verbatim; the value is trimmed.
/// Complexity: O(n). Pure.
pub fn header_parse_line(line: Str) -> Option[(Str, Str)] {
  let len = line.len();
  var end = len;
  if end >= 2 && line.byte_at(end - 2) == 13 && line.byte_at(end - 1) == 10 {
    end = end - 2;
  } elif end >= 1 && line.byte_at(end - 1) == 10 {
    end = end - 1;
  } elif end >= 1 && line.byte_at(end - 1) == 13 {
    end = end - 1;
  }
  var colon = -1;
  var i = 0;
  while i < end {
    if line.byte_at(i) == 58 {
      colon = i;
      break;
    }
    i = i + 1;
  }
  if colon <= 0 {
    return None;
  }
  let name = string.str_slice(line, 0, colon);
  let value = trim_ws(string.str_slice(line, colon + 1, end));
  Some((name, value))
}

/// Serialize headers into "Name: value" lines.
/// Parameters: headers -- the header list.
/// Returns: the concatenated header block; each line ends with CRLF.
/// Complexity: O(n) with n = header count. Pure.
pub fn header_serialize(headers: &Vec[(Str, Str)]) -> Str {
  var result = "";
  var i = 0;
  while i < headers.len() {
    let h = headers[i];
    result = result + h.0 + ": " + h.1 + "\r\n";
    i = i + 1;
  }
  result
}
