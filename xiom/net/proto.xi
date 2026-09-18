// XIOM -- Protocol Helpers (xiom.net.proto)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure protocol helpers: JSON-RPC 2.0 message framing, SSE formatting,
// HTTP header parsing, and HTTP authentication header construction.

module xiom.net.proto

use xiom.string;
use xiom.encoding;

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

fn is_ws_byte(b: UInt8) -> Bool {
  b == 32 || b == 9 || b == 10 || b == 13
}

fn trim(s: Str) -> Str {
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

// jsonrpc_request builds a JSON-RPC 2.0 request object. The params value
// is embedded verbatim as pre-serialized JSON.
/// jsonrpc_request builds a JSON-RPC 2.0 request object. The params value
/// is embedded verbatim as pre-serialized JSON.
pub fn jsonrpc_request(id: Int, method: Str, params_json: Str) -> Str {
  var result = "{\"jsonrpc\":\"2.0\",\"id\":";
  result = result + id.to_str();
  result = result + ",\"method\":\"";
  result = result + method;
  result = result + "\",\"params\":";
  result = result + params_json;
  result = result + "}";
  result
}

// jsonrpc_success builds a JSON-RPC 2.0 success response. The result value
// is embedded verbatim as pre-serialized JSON.
/// jsonrpc_success builds a JSON-RPC 2.0 success response. The result value
/// is embedded verbatim as pre-serialized JSON.
pub fn jsonrpc_success(id: Int, result_json: Str) -> Str {
  var result = "{\"jsonrpc\":\"2.0\",\"id\":";
  result = result + id.to_str();
  result = result + ",\"result\":";
  result = result + result_json;
  result = result + "}";
  result
}

// jsonrpc_error builds a JSON-RPC 2.0 error response.
/// jsonrpc_error builds a JSON-RPC 2.0 error response.
pub fn jsonrpc_error(id: Int, code: Int, message: Str) -> Str {
  var result = "{\"jsonrpc\":\"2.0\",\"id\":";
  result = result + id.to_str();
  result = result + ",\"error\":{\"code\":";
  result = result + code.to_str();
  result = result + ",\"message\":\"";
  result = result + message;
  result = result + "\"}}";
  result
}

// sse_data_lines prefixes every line of data with "data: " followed by a
// newline.
fn sse_data_lines(data: Str) -> Str {
  var result = "";
  if data.len() == 0 {
    return "data: \n";
  }
  let lines = split(data, "\n");
  var i = 0;
  while i < lines.len() {
    result = result + "data: ";
    result = result + lines[i];
    result = result + "\n";
    i = i + 1;
  }
  result
}

// sse_format_event formats an SSE event with an "event:" line followed by
// "data:" lines and a terminating blank line.
/// sse_format_event formats an SSE event with an "event:" line followed by
/// "data:" lines and a terminating blank line.
pub fn sse_format_event(event: Str, data: Str) -> Str {
  var result = "event: ";
  result = result + event;
  result = result + "\n";
  result = result + sse_data_lines(data);
  result = result + "\n";
  result
}

// sse_format_data formats a single SSE data message with a terminating
// blank line.
/// sse_format_data formats a single SSE data message with a terminating
/// blank line.
pub fn sse_format_data(data: Str) -> Str {
  sse_data_lines(data) + "\n"
}

// http_header_parse parses a block of "Name: value" lines (one per line,
// '\r' tolerated) into (name, value) pairs. Blank lines are skipped.
/// http_header_parse parses a block of "Name: value" lines (one per line,
/// '\r' tolerated) into (name, value) pairs. Blank lines are skipped.
pub fn http_header_parse(headers: Str) -> Vec[(Str, Str)] {
  var result: Vec[(Str, Str)] = Vec[(Str, Str)]::new();
  let lines = split(headers, "\n");
  var i = 0;
  while i < lines.len() {
    var line = lines[i];
    if line.len() > 0 && line.byte_at(line.len() - 1) == 13 {
      line = string.str_slice(line, 0, line.len() - 1);
    }
    line = trim(line);
    if line.len() > 0 {
      let colon = idx_of(line, ":");
      if colon >= 0 {
        let name = trim(string.str_slice(line, 0, colon));
        let value = trim(string.str_slice(line, colon + 1, line.len()));
        result.push((name, value));
      }
    }
    i = i + 1;
  }
  result
}

// http_header_get finds the value for a header name in a parsed header
// list, matching case-insensitively and returning the first match.
/// http_header_get finds the value for a header name in a parsed header
/// list, matching case-insensitively and returning the first match.
pub fn http_header_get(headers: Vec[(Str, Str)], name: Str) -> Option[Str] {
  let lname = string.str_lower(name);
  var i = 0;
  while i < headers.len() {
    let k = string.str_lower(headers[i].0);
    if k == lname {
      return Some(headers[i].1);
    }
    i = i + 1;
  }
  None
}

// basic_auth_header builds a "Basic <base64(user:password)>" Authorization
// header value.
/// basic_auth_header builds a "Basic <base64(user:password)>" Authorization
/// header value.
pub fn basic_auth_header(username: Str, password: Str) -> Str {
  "Basic " + encoding.base64_encode_str(username + ":" + password)
}

// bearer_auth_header builds a "Bearer <token>" Authorization header value.
/// bearer_auth_header builds a "Bearer <token>" Authorization header value.
pub fn bearer_auth_header(token: Str) -> Str {
  "Bearer " + token
}

// http_status_text maps an HTTP status code to its standard reason phrase,
// or "Unknown" for codes not in the table.
/// http_status_text maps an HTTP status code to its standard reason phrase,
/// or "Unknown" for codes not in the table.
pub fn http_status_text(code: Int) -> Str {
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
