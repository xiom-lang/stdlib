// XIOM - Networking: HTTPS Client
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.https

// Depends on: xiom.net.http + xiom.net.url
//
// HTTPS request/response builders. HTTPS shares the HTTP/1.1 message
// framing; the only difference is the default transport port (443) and
// the URL scheme. The builders in this module mirror xiom.net.http's
// request building and response parsing helpers.

use xiom.net.http;
use xiom.net.url;

// https_default_port returns the default HTTPS port (443).
// Complexity: O(1). Pure.
pub fn https_default_port() -> Int {
  443
}

// https_request_line builds the request line for a method and target,
// e.g. https_request_line("GET", "/") == "GET / HTTP/1.1".
// Complexity: O(1). Pure.
pub fn https_request_line(method: Str, target: Str) -> Str {
  method + " " + target + " HTTP/1.1"
}

// https_build_request builds a full HTTPS request text from a URL,
// method, headers, and body. The Host header carries the explicit port
// only when it differs from 443. Complexity: O(n). Pure.
pub fn https_build_request(method: Str, url_str: Str, headers: &Vec[(Str, Str)], body: &Vec[UInt8]) -> Result[Str, Str] {
  let parsed = url.url_parse(url_str);
  match parsed {
    Ok(p) => {
      var target = p.path;
      if target.len() == 0 {
        target = "/";
      }
      if p.query.len() > 0 {
        target = target + "?" + p.query;
      }
      var request = https_request_line(method, target);
      request = request + "\r\n";
      request = request + "Host: " + p.host;
      if p.port > 0 && p.port != 443 {
        request = request + ":" + p.port.to_str();
      }
      request = request + "\r\n";
      var hi = 0;
      while hi < headers.len() {
        request = request + headers[hi].0 + ": " + headers[hi].1 + "\r\n";
        hi = hi + 1;
      }
      request = request + "Content-Length: " + body.len().to_str() + "\r\n";
      request = request + "Connection: close\r\n";
      request = request + "\r\n";
      Ok(request)
    }
    Err(e) => Err(e),
  }
}

// https_parse_status_line parses the status line "HTTP/1.1 200 OK" and
// returns the status code, or -1 if malformed. Complexity: O(1). Pure.
fn https_parse_status_line(line: Str) -> Int {
  let sp1 = idx_of(line, " ");
  if sp1 < 0 {
    return -1;
  }
  let after = string.str_slice(line, sp1 + 1, line.len());
  let sp2 = idx_of(after, " ");
  var status_str = after;
  if sp2 >= 0 {
    status_str = string.str_slice(after, 0, sp2);
  }
  var value = 0;
  var i = 0;
  let slen = status_str.len();
  if slen != 3 {
    return -1;
  }
  while i < slen {
    let b = status_str.byte_at(i);
    if b < 48 || b > 57 {
      return -1;
    }
    value = value * 10 + (b as Int - 48);
    i = i + 1;
  }
  value
}

// https_status_text returns the standard reason phrase for a status
// code, or "Unknown" for codes not in the table. Complexity: O(1).
pub fn https_status_text(code: Int) -> Str {
  if code == 200 { return "OK"; }
  if code == 201 { return "Created"; }
  if code == 202 { return "Accepted"; }
  if code == 204 { return "No Content"; }
  if code == 301 { return "Moved Permanently"; }
  if code == 302 { return "Found"; }
  if code == 303 { return "See Other"; }
  if code == 304 { return "Not Modified"; }
  if code == 307 { return "Temporary Redirect"; }
  if code == 308 { return "Permanent Redirect"; }
  if code == 400 { return "Bad Request"; }
  if code == 401 { return "Unauthorized"; }
  if code == 403 { return "Forbidden"; }
  if code == 404 { return "Not Found"; }
  if code == 405 { return "Method Not Allowed"; }
  if code == 408 { return "Request Timeout"; }
  if code == 409 { return "Conflict"; }
  if code == 410 { return "Gone"; }
  if code == 413 { return "Payload Too Large"; }
  if code == 429 { return "Too Many Requests"; }
  if code == 500 { return "Internal Server Error"; }
  if code == 501 { return "Not Implemented"; }
  if code == 502 { return "Bad Gateway"; }
  if code == 503 { return "Service Unavailable"; }
  if code == 504 { return "Gateway Timeout"; }
  "Unknown"
}

// https_response_status extracts the HTTP status code from a raw
// response. Returns None if malformed. Complexity: O(1). Pure.
pub fn https_response_status(raw: Str) -> Option[Int] {
  let nl = idx_of(raw, "\r\n");
  var status_line = raw;
  if nl >= 0 {
    status_line = string.str_slice(raw, 0, nl);
  } else {
    let nl2 = idx_of(raw, "\n");
    if nl2 >= 0 {
      status_line = string.str_slice(raw, 0, nl2);
    }
  }
  let code = https_parse_status_line(status_line);
  if code < 0 {
    return None;
  }
  Some(code)
}

// https_parse_response_headers extracts the (name, value) header pairs
// from a raw response block. Complexity: O(n). Pure.
pub fn https_parse_response_headers(raw: Str) -> Vec[(Str, Str)] {
  http.http_parse_response_headers(raw)
}

// https_url_encode percent-encodes a string for use in a URL.
// Complexity: O(n). Pure.
pub fn https_url_encode(s: Str) -> Str {
  http.http_url_encode(s)
}

// https_url_decode percent-decodes a URL-encoded string.
// Complexity: O(n). Pure.
pub fn https_url_decode(s: Str) -> Result[Str, Str] {
  http.http_url_decode(s)
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
