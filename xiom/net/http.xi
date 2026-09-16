// XIOM - Networking: HTTP Client
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.http

// Depends on: xiom.net + xiom.string
//
// HTTP request/response builders plus a minimal HTTP/1.1 client.
// The module is self-contained: URL parsing, request building, and
// response parsing are implemented locally on top of xiom.string and
// xiom.net.url so the module works independently of xiom.net's socket
// layer.

use xiom.string;
use xiom.net.url;

// type HttpResponse - an HTTP response: status code (Int), headers, and
// raw body bytes.
pub type HttpResponse = {
  status: Int;
  headers: Vec[(Str, Str)];
  body: Vec[UInt8];
} derive[Clone]

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

// split splits s on every occurrence of delim.
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

// is_ws_byte returns true for space/tab.
fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9
}

// trim_ws trims leading/trailing spaces and tabs.
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

// http_status_text returns the standard reason phrase for a status
// code, or "Unknown" for codes not in the table. Complexity: O(1).
pub fn http_status_text(code: Int) -> Str {
  if code == 200 { return "OK"; }
  if code == 201 { return "Created"; }
  if code == 202 { return "Accepted"; }
  if code == 204 { return "No Content"; }
  if code == 206 { return "Partial Content"; }
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
  if code == 406 { return "Not Acceptable"; }
  if code == 408 { return "Request Timeout"; }
  if code == 409 { return "Conflict"; }
  if code == 410 { return "Gone"; }
  if code == 413 { return "Payload Too Large"; }
  if code == 415 { return "Unsupported Media Type"; }
  if code == 422 { return "Unprocessable Entity"; }
  if code == 429 { return "Too Many Requests"; }
  if code == 500 { return "Internal Server Error"; }
  if code == 501 { return "Not Implemented"; }
  if code == 502 { return "Bad Gateway"; }
  if code == 503 { return "Service Unavailable"; }
  if code == 504 { return "Gateway Timeout"; }
  "Unknown"
}

// http_request_line builds the request line for a method and target,
// e.g. http_request_line("GET", "/") == "GET / HTTP/1.1".
// Complexity: O(1). Pure.
pub fn http_request_line(method: Str, target: Str) -> Str {
  method + " " + target + " HTTP/1.1"
}

// http_build_request builds a full HTTP/1.1 request text from a parsed
// URL, method, headers, and body. Used by the client and exposed for
// callers that want to send raw requests themselves.
pub fn http_build_request(method: Str, url_str: Str, headers: &Vec[(Str, Str)], body: &Vec[UInt8]) -> Result[Str, Str] {
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
      var request = http_request_line(method, target);
      request = request + "\r\n";
      request = request + "Host: " + p.host;
      if p.port > 0 {
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

// http_parse_status parses the status line "HTTP/1.1 200 OK" and
// returns the status code, or -1 if malformed.
fn http_parse_status(line: Str) -> Int {
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

// http_response_status extracts the HTTP status code from a raw
// response without allocating a full response value. Returns None if
// the status line is malformed. Complexity: O(1). Pure.
pub fn http_response_status(raw: Str) -> Option[Int] {
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
  let code = http_parse_status(status_line);
  if code < 0 {
    return None;
  }
  Some(code)
}

// http_parse_response_headers extracts the (name, value) header pairs
// from a raw HTTP response block (everything after the status line and
// before the blank line). Complexity: O(n). Pure.
pub fn http_parse_response_headers(raw: Str) -> Vec[(Str, Str)] {
  var result: Vec[(Str, Str)] = Vec[(Str, Str)]::new();
  let nl = idx_of(raw, "\r\n");
  var rest = raw;
  if nl >= 0 {
    rest = string.str_slice(raw, nl + 2, raw.len());
  } else {
    let nl2 = idx_of(raw, "\n");
    if nl2 >= 0 {
      rest = string.str_slice(raw, nl2 + 1, raw.len());
    }
  }
  let sep = idx_of(rest, "\r\n\r\n");
  if sep >= 0 {
    rest = string.str_slice(rest, 0, sep);
  } else {
    let sep2 = idx_of(rest, "\n\n");
    if sep2 >= 0 {
      rest = string.str_slice(rest, 0, sep2);
    }
  }
  let lines = split(rest, "\n");
  var li = 0;
  while li < lines.len() {
    var line = lines[li];
    let llen = line.len();
    if llen > 0 && line.byte_at(llen - 1) == 13 {
      line = string.str_slice(line, 0, llen - 1);
    }
    let colon = idx_of(line, ":");
    if colon > 0 {
      let name = trim_ws(string.str_slice(line, 0, colon));
      let value = trim_ws(string.str_slice(line, colon + 1, line.len()));
      result.push((name, value));
    }
    li = li + 1;
  }
  result
}

// http_parse_response parses a raw HTTP/1.1 response into an
// HttpResponse. Invalid input returns Err. Complexity: O(n). Pure.
pub fn http_parse_response(raw: Str) -> Result[HttpResponse, Str] {
  let nl = idx_of(raw, "\r\n");
  var status_line = raw;
  var rest = "";
  if nl >= 0 {
    status_line = string.str_slice(raw, 0, nl);
    rest = string.str_slice(raw, nl + 2, raw.len());
  } else {
    let nl2 = idx_of(raw, "\n");
    if nl2 >= 0 {
      status_line = string.str_slice(raw, 0, nl2);
      rest = string.str_slice(raw, nl2 + 1, raw.len());
    }
  }
  let status = http_parse_status(status_line);
  if status < 0 {
    return Err("invalid HTTP status line");
  }
  let headers = http_parse_response_headers(raw);
  var body: Vec[UInt8] = Vec[UInt8]::new();
  let sep = idx_of(rest, "\r\n\r\n");
  if sep >= 0 {
    let body_start = sep + 4;
    var i = body_start;
    while i < rest.len() {
      body.push(rest.byte_at(i));
      i = i + 1;
    }
  } else {
    let sep2 = idx_of(rest, "\n\n");
    if sep2 >= 0 {
      let body_start = sep2 + 2;
      var i = body_start;
      while i < rest.len() {
        body.push(rest.byte_at(i));
        i = i + 1;
      }
    }
  }
  Ok(HttpResponse{ status: status; headers: headers; body: body; })
}

// http_status_code returns the HTTP status code of a response.
// Complexity: O(1). Pure.
pub fn http_status_code(resp: &HttpResponse) -> Int {
  resp.status
}

// http_header returns the value of a named response header (matched
// case-insensitively), or None if absent. Complexity: O(h). Pure.
pub fn http_header(resp: &HttpResponse, name: Str) -> Option[Str] {
  let lname = string.str_lower(name);
  var i = 0;
  while i < resp.headers.len() {
    let k = string.str_lower(resp.headers[i].0);
    if k == lname {
      return Some(resp.headers[i].1);
    }
    i = i + 1;
  }
  None
}

// http_body_text decodes the response body bytes as UTF-8 text.
// Complexity: O(n). Pure.
pub fn http_body_text(resp: &HttpResponse) -> Str {
  var buf: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < resp.body.len() {
    buf.push(resp.body[i]);
    i = i + 1;
  }
  let s = Str::from_utf8(buf);
  s
}

// http_url_encode percent-encodes a string for use in a URL.
// Complexity: O(n). Pure.
pub fn http_url_encode(s: Str) -> Str {
  var result = "";
  let len = s.len();
  var i = 0;
  while i < len {
    let b = s.byte_at(i);
    let c = b as Int;
    let unreserved = (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 45 || c == 46 || c == 95 || c == 126;
    if unreserved {
      result = result + string.str_slice(s, i, i + 1);
    } else {
      result = result + "%";
      let hi = c / 16;
      let lo = c % 16;
      result = result + hex_nib(hi);
      result = result + hex_nib(lo);
    }
    i = i + 1;
  }
  result
}

// hex_nib returns the uppercase hex digit for a nibble (0-15).
fn hex_nib(v: Int) -> Str {
  if v < 10 {
    return string.str_slice("0123456789", v, v + 1);
  }
  string.str_slice("ABCDEF", v - 10, v - 9)
}

// hex_digit_value returns the numeric value of a hex digit byte, or -1.
fn hex_digit_value(b: UInt8) -> Int {
  let c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  -1
}

// http_url_decode percent-decodes a URL-encoded string. Returns Err on
// truncated or invalid escapes. Complexity: O(n). Pure.
pub fn http_url_decode(s: Str) -> Result[Str, Str] {
  let len = s.len();
  var out: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < len {
    let b = s.byte_at(i);
    if b == 37 {
      if i + 2 >= len {
        return Err("truncated percent escape");
      }
      let hi = hex_digit_value(s.byte_at(i + 1));
      let lo = hex_digit_value(s.byte_at(i + 2));
      if hi < 0 || lo < 0 {
        return Err("invalid percent escape");
      }
      out.push(((hi << 4) | lo) as UInt8);
      i = i + 3;
    } else if b == 43 {
      out.push(32 as UInt8);
      i = i + 1;
    } else {
      out.push(b);
      i = i + 1;
    }
  }
  let result = Str::from_utf8(out);
  Ok(result)
}

// --- Network client functions -------------------------------------------------
// These perform real HTTP/1.1 requests. They are implemented locally with
// the same extern socket primitives used by xiom.net, so no network setup is
// required at the module level.

extern "C" {
  fn xiom_socket_create(family: Int, typ: Int, proto: Int) -> Int;
  fn xiom_socket_connect(sock: Int, host: *UInt8, port: Int) -> Int;
  fn xiom_socket_send(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_recv(sock: Int, buf: *UInt8, len: Int) -> Int;
  fn xiom_socket_close(sock: Int) -> Int;
}

// http_get performs an HTTP GET request and returns the response.
// Complexity: network I/O.
pub fn http_get(url: Str) -> Result[HttpResponse, Str] {
  http_request("GET", url, Vec[(Str, Str)]::new(), Vec[UInt8]::new())
}

// http_post performs an HTTP POST with a raw byte body.
// Complexity: network I/O.
pub fn http_post(url: Str, body: &Vec[UInt8]) -> Result[HttpResponse, Str] {
  http_request("POST", url, Vec[(Str, Str)]::new(), body)
}

// http_put performs an HTTP PUT with a raw byte body.
// Complexity: network I/O.
pub fn http_put(url: Str, body: &Vec[UInt8]) -> Result[HttpResponse, Str] {
  http_request("PUT", url, Vec[(Str, Str)]::new(), body)
}

// http_delete performs an HTTP DELETE request.
// Complexity: network I/O.
pub fn http_delete(url: Str) -> Result[HttpResponse, Str] {
  http_request("DELETE", url, Vec[(Str, Str)]::new(), Vec[UInt8]::new())
}

// http_head performs an HTTP HEAD request.
// Complexity: network I/O.
pub fn http_head(url: Str) -> Result[HttpResponse, Str] {
  http_request("HEAD", url, Vec[(Str, Str)]::new(), Vec[UInt8]::new())
}

// http_patch performs an HTTP PATCH with a raw byte body.
// Complexity: network I/O.
pub fn http_patch(url: Str, body: &Vec[UInt8]) -> Result[HttpResponse, Str] {
  http_request("PATCH", url, Vec[(Str, Str)]::new(), body)
}

// http_get_text performs an HTTP GET and returns the response body
// decoded as text. Complexity: network I/O.
pub fn http_get_text(url: Str) -> Result[Str, Str] {
  let resp = http_get(url);
  match resp {
    Ok(r) => Ok(http_body_text(&r));
    Err(e) => Err(e);
  }
}

// http_get_bytes performs an HTTP GET and returns the raw body bytes.
// Complexity: network I/O.
pub fn http_get_bytes(url: Str) -> Result[Vec[UInt8], Str] {
  let resp = http_get(url);
  match resp {
    Ok(r) => Ok(r.body);
    Err(e) => Err(e);
  }
}

// http_redirect_follow follows up to max HTTP redirects (301/302/303/
// 307/308) before returning the final response. Complexity: network I/O.
pub fn http_redirect_follow(url: Str, max: Int) -> Result[HttpResponse, Str] {
  var current = url;
  var hops = 0;
  while hops <= max {
    let resp = http_get(current);
    match resp {
      Ok(r) => {
        let s = r.status;
        let is_redirect = s == 301 || s == 302 || s == 303 || s == 307 || s == 308;
        if is_redirect && hops < max {
          let loc = http_header(&r, "location");
          match loc {
            Some(l) => {
              current = l;
              hops = hops + 1;
            }
            None => { return Ok(r); }
          }
        } else {
          return Ok(r);
        }
      }
      Err(e) => { return Err(e); }
    }
  }
  Err("too many redirects")
}

// http_request performs a generic HTTP request; each tuple in headers
// is a (name, value) header pair. Complexity: network I/O.
pub fn http_request(method: Str, url: Str, headers: &Vec[(Str, Str)], body: &Vec[UInt8]) -> Result[HttpResponse, Str] {
  let parsed = url.url_parse(url);
  var host = "";
  var port = 0;
  match parsed {
    Ok(p) => {
      host = p.host;
      port = p.port;
      if port <= 0 {
        port = 80;
      }
    }
    Err(e) => { return Err(e); }
  }
  if host.len() == 0 {
    return Err("invalid URL: no host");
  }
  let request = http_build_request(method, url, headers, body);
  var req_str = "";
  match request {
    Ok(r) => { req_str = r; }
    Err(e) => { return Err(e); }
  }
  let fd = unsafe { xiom_socket_create(2, 1, 0) };
  if fd < 0 {
    return Err("failed to create socket");
  }
  var c_host: [256]UInt8;
  var hi = 0;
  let hlen = host.len();
  while hi < hlen && hi < 255 {
    c_host[hi] = host.byte_at(hi);
    hi = hi + 1;
  }
  c_host[hi] = 0 as UInt8;
  let conn = unsafe { xiom_socket_connect(fd, &c_host as *UInt8, port) };
  if conn < 0 {
    unsafe { xiom_socket_close(fd); }
    return Err("connection failed");
  }
  var send_buf: [4096]UInt8;
  var si = 0;
  let rlen = req_str.len();
  if rlen > 4096 {
    unsafe { xiom_socket_close(fd); }
    return Err("request too large");
  }
  while si < rlen {
    send_buf[si] = req_str.byte_at(si);
    si = si + 1;
  }
  let sent = unsafe { xiom_socket_send(fd, &send_buf as *UInt8, rlen) };
  if sent < 0 {
    unsafe { xiom_socket_close(fd); }
    return Err("send failed");
  }
  var recv_buf: [8192]UInt8;
  var raw: Vec[UInt8] = Vec[UInt8]::with_capacity(8192);
  var done = false;
  while !done {
    let n = unsafe { xiom_socket_recv(fd, &recv_buf as *UInt8, 8192) };
    if n <= 0 {
      done = true;
    } else {
      var ri = 0;
      while ri < n {
        raw.push(recv_buf[ri]);
        ri = ri + 1;
      }
    }
  }
  unsafe { xiom_socket_close(fd); }
  let s = Str::from_utf8(raw);
  http_parse_response(s)
}
