// XIOM -- HTTP Server Helpers (xiom.net.server)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure HTTP server-side helpers: request-line parsing, status line and
// response construction, and status-text lookup. No network I/O.

module xiom.net.server

use xiom.string;

// server_default_port returns the default HTTP server port (80).
// Complexity: O(1). Pure.
/// server_default_port returns the default HTTP server port (80).
/// Complexity: O(1). Pure.
pub fn server_default_port() -> Int {
  80
}

// server_parse_request_line parses an HTTP request line like
// "GET /path HTTP/1.1" into (method, target, version). Returns None if
// the line does not contain three space-separated tokens.
// Complexity: O(n). Pure.
/// server_parse_request_line parses an HTTP request line like
/// "GET /path HTTP/1.1" into (method, target, version). Returns None if
/// the line does not contain three space-separated tokens.
/// Complexity: O(n). Pure.
pub fn server_parse_request_line(line: Str) -> Option[(Str, Str, Str)] {
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

// server_build_status_line builds a status line like
// "HTTP/1.1 200 OK". Complexity: O(1). Pure.
/// server_build_status_line builds a status line like
/// "HTTP/1.1 200 OK". Complexity: O(1). Pure.
pub fn server_build_status_line(code: Int) -> Str {
  "HTTP/1.1 " + code.to_str() + " " + server_status_text(code)
}

// server_build_response builds a minimal HTTP/1.1 response with a
// text/plain body. Complexity: O(n). Pure.
/// server_build_response builds a minimal HTTP/1.1 response with a
/// text/plain body. Complexity: O(n). Pure.
pub fn server_build_response(code: Int, body: Str) -> Str {
  var resp = server_build_status_line(code);
  resp = resp + "\r\n";
  resp = resp + "Content-Type: text/plain\r\n";
  resp = resp + "Content-Length: " + body.len().to_str() + "\r\n";
  resp = resp + "Connection: close\r\n";
  resp = resp + "\r\n";
  resp = resp + body;
  resp
}

// server_build_response_headers builds an HTTP/1.1 response with custom
// (name, value) header pairs and a text body. Complexity: O(n). Pure.
/// server_build_response_headers builds an HTTP/1.1 response with custom
/// (name, value) header pairs and a text body. Complexity: O(n). Pure.
pub fn server_build_response_headers(code: Int, headers: &Vec[(Str, Str)], body: Str) -> Str {
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

// server_status_text returns the standard reason phrase for a status
// code, or "Unknown" for codes not in the table. Complexity: O(1).
/// server_status_text returns the standard reason phrase for a status
/// code, or "Unknown" for codes not in the table. Complexity: O(1).
pub fn server_status_text(code: Int) -> Str {
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
