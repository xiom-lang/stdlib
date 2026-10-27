// XIOM -- HTTP Server Helpers (xiom.net.server)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure HTTP server-side helpers: request-line parsing, status line and
// response construction, and status-text lookup. No network I/O.

module xiom.net.server

use xiom.string;

extern "C" {
  fn malloc(size: UInt) -> *UInt8;
}

/// server_default_port returns the default HTTP server port (80).
/// Complexity: O(1). Pure.
pub fn server_default_port() -> Int
  ensures: result == 80
{
  80
}

/// server_parse_request_line parses an HTTP request line like
/// "GET /path HTTP/1.1" into (method, target, version). Returns None if
/// the line does not contain three space-separated tokens.
/// Complexity: O(n). Pure.
pub fn server_parse_request_line(line: Str) -> Option[(Str, Str, Str)]
  ensures: ((line.len() < 5) => (result.is_none == true)) && ((result.is_some == true) => (line.len() >= 5))
{
  let sp1 = idx_of(line, " ");
  if sp1 <= 0 {
    return None;
  }
  let method = string.str_slice(line, 0, sp1);
  let rest = string.str_slice(line, sp1 + 1, line.len());
  let sp2 = idx_of(rest, " ");
  if sp2 <= 0 {
    return None;
  }
  let target = string.str_slice(rest, 0, sp2);
  let version = string.str_slice(rest, sp2 + 1, rest.len());
  if target.len() == 0 || version.len() == 0 {
    return None;
  }
  Some((method, target, version))
}

/// Parsed HTTP/1.x request head plus the body span inside the raw buffer.
/// `body_len` is the Content-Length value (0 when the header is absent);
/// the body bytes are [body_start, body_start + body_len) in that buffer.
pub type ServerRequest = {
  method: Str;
  target: Str;
  version: Str;
  headers: Vec[(Str, Str)];
  body_start: Int;
  body_len: Int;
}

/// server_parse_request parses raw HTTP/1.x request bytes (head + body)
/// into method/target/version, a lowercased (name, value) header list and
/// the body span. Returns None when the request line is malformed, the
/// header block is not CRLF-terminated, a header has no colon, or a
/// Content-Length value is missing/negative/not an integer. The head is
/// parsed directly from the byte buffer using (start, len) spans: no
/// whole-head copy is made and each returned field is a single
/// allocation. Complexity: O(n). Pure.
pub fn server_parse_request(bytes: &Vec[UInt8]) -> Option[ServerRequest]
  ensures: (bytes.len() == 0) => (result.is_none == true)
{
  let n = bytes.len();
  if n == 0 { return None; }
  var head_end = -1;
  var body_start = -1;
  var i = 0;
  while i + 3 < n {
    if bytes[i] == 13u8 && bytes[i + 1] == 10u8 && bytes[i + 2] == 13u8 && bytes[i + 3] == 10u8 {
      head_end = i;
      body_start = i + 4;
      i = n;
    } else {
      i = i + 1;
    }
  }
  if body_start < 0 { return None; }

  // Request line: find the CRLF that ends it.
  var rl_end = -1;
  var a = 0;
  while a + 1 < head_end {
    if bytes[a] == 13u8 && bytes[a + 1] == 10u8 {
      rl_end = a;
      a = head_end;
    } else {
      a = a + 1;
    }
  }
  if rl_end <= 0 { return None; }
  var sp1 = -1;
  var b = 0;
  while b < rl_end {
    if bytes[b] == 32u8 {
      sp1 = b;
      b = rl_end;
    } else {
      b = b + 1;
    }
  }
  if sp1 <= 0 { return None; }
  var sp2 = -1;
  var c = sp1 + 1;
  while c < rl_end {
    if bytes[c] == 32u8 {
      sp2 = c;
      c = rl_end;
    } else {
      c = c + 1;
    }
  }
  if sp2 <= sp1 + 1 { return None; }
  if sp2 + 1 >= rl_end { return None; }
  let method = _str_from_byte_span(bytes, 0, sp1);
  let target = _str_from_byte_span(bytes, sp1 + 1, sp2);
  let version = _str_from_byte_span(bytes, sp2 + 1, rl_end);

  // Headers: parse name/value pairs straight from the buffer. The name is
  // lowercased in the same copy; the value skips one leading space to
  // match the historic single-OWS trim.
  var headers = Vec[(Str, Str)].with_capacity(8);
  var body_len = 0;
  var pos = rl_end + 2;
  while pos < head_end {
    var le = -1;
    var d = pos;
    while d + 1 < head_end {
      if bytes[d] == 13u8 && bytes[d + 1] == 10u8 {
        le = d;
        d = head_end;
      } else {
        d = d + 1;
      }
    }
    if le < 0 { le = head_end; }
    var colon = -1;
    var e = pos;
    while e < le {
      if bytes[e] == 58u8 {
        colon = e;
        e = le;
      } else {
        e = e + 1;
      }
    }
    if colon <= pos { return None; }
    let name = _str_lower_from_byte_span(bytes, pos, colon);
    var vstart = colon + 1;
    if vstart < le {
      if bytes[vstart] == 32u8 { vstart = vstart + 1; }
    }
    let value = _str_from_byte_span(bytes, vstart, le);
    if name == "content-length" {
      match string.str_to_int(value) {
        Ok(v) => {
          if v < 0 { return None; }
          body_len = v;
        },
        Err(_) => { return None; },
      }
    }
    headers.push((name, value));
    pos = le + 2;
  }
  return Some(ServerRequest{ method: method; target: target; version: version; headers: headers; body_start: body_start; body_len: body_len; });
}

/// server_build_status_line builds a status line like
/// "HTTP/1.1 200 OK". Complexity: O(1). Pure.
pub fn server_build_status_line(code: Int) -> Str
  ensures: result.len() >= 13 && ((code == 200) => (result == "HTTP/1.1 200 OK")) && ((code == 404) => (result == "HTTP/1.1 404 Not Found")) && ((code == 500) => (result == "HTTP/1.1 500 Internal Server Error"))
{
  "HTTP/1.1 " + code.to_str() + " " + server_status_text(code)
}

/// server_build_response builds a minimal HTTP/1.1 response with a
/// text/plain body. Complexity: O(n). Pure.
pub fn server_build_response(code: Int, body: Str) -> Str
  ensures: result.len() >= body.len() + 81
{
  var resp = server_build_status_line(code);
  resp = resp + "\r\n";
  resp = resp + "Content-Type: text/plain\r\n";
  resp = resp + "Content-Length: " + body.len().to_str() + "\r\n";
  resp = resp + "Connection: close\r\n";
  resp = resp + "\r\n";
  resp = resp + body;
  resp
}

/// server_build_response_headers builds an HTTP/1.1 response with custom
/// (name, value) header pairs and a text body. Complexity: O(n). Pure.
pub fn server_build_response_headers(code: Int, headers: &Vec[(Str, Str)], body: Str) -> Str
  ensures: result.len() >= body.len() + (headers.len() * 4) + 36
{
  var resp = server_build_status_line(code);
  resp = resp + "\r\n";
  var i = 0;
  while i < headers.len() {
    resp = resp + headers[i].0 + ": " + headers[i].1 + "\r\n";
    i = i + 1;
  }
  resp = resp + "Content-Length: " + body.len().to_str() + "\r\n";
  resp = resp + "\r\n";
  resp = resp + body;
  resp
}

/// server_status_text returns the standard reason phrase for a status
/// code, or "Unknown" for codes not in the table. Complexity: O(1).
pub fn server_status_text(code: Int) -> Str
  ensures: result.len() > 0 && ((code == 200) => (result == "OK")) && ((code == 404) => (result == "Not Found")) && ((code == 500) => (result == "Internal Server Error"))
{
  if code == 200 { return "OK"; }
  if code == 201 { return "Created"; }
  if code == 204 { return "No Content"; }
  if code == 301 { return "Moved Permanently"; }
  if code == 302 { return "Found"; }
  if code == 304 { return "Not Modified"; }
  if code == 400 { return "Bad Request"; }
  if code == 401 { return "Unauthorized"; }
  if code == 403 { return "Forbidden"; }
  if code == 404 { return "Not Found"; }
  if code == 405 { return "Method Not Allowed"; }
  if code == 408 { return "Request Timeout"; }
  if code == 409 { return "Conflict"; }
  if code == 413 { return "Payload Too Large"; }
  if code == 429 { return "Too Many Requests"; }
  if code == 500 { return "Internal Server Error"; }
  if code == 501 { return "Not Implemented"; }
  if code == 502 { return "Bad Gateway"; }
  if code == 503 { return "Service Unavailable"; }
  if code == 504 { return "Gateway Timeout"; }
  "Unknown"
}

// _str_from_byte_span copies bytes[start, end) into a fresh Str (one
// allocation). Empty/clamped ranges return the empty Str.
fn _str_from_byte_span(bytes: &Vec[UInt8], start: Int, end: Int) -> Str {
  var s = start;
  var e = end;
  if s < 0 { s = 0; }
  if e > bytes.len() { e = bytes.len(); }
  if s >= e { return ""; }
  let len = e - s;
  unsafe {
    var buf = malloc((len + 1) as UInt);
    var i = 0;
    while i < len {
      buf[i] = bytes[s + i];
      i = i + 1;
    }
    buf[len] = 0u8;
    return Str.from_cstring(buf);
  }
}

// _str_lower_from_byte_span copies bytes[start, end) into a fresh Str,
// ASCII-lowercasing A-Z in the same pass (one allocation).
fn _str_lower_from_byte_span(bytes: &Vec[UInt8], start: Int, end: Int) -> Str {
  var s = start;
  var e = end;
  if s < 0 { s = 0; }
  if e > bytes.len() { e = bytes.len(); }
  if s >= e { return ""; }
  let len = e - s;
  unsafe {
    var buf = malloc((len + 1) as UInt);
    var i = 0;
    while i < len {
      let b = bytes[s + i];
      if b >= 65u8 && b <= 90u8 {
        buf[i] = (b + 32) as UInt8;
      } else {
        buf[i] = b;
      }
      i = i + 1;
    }
    buf[len] = 0u8;
    return Str.from_cstring(buf);
  }
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
