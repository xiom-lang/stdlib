// XIOM -- WebSocket URL Helpers (xiom.net.ws)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure WebSocket URL parsing and building helpers for the ws:// and
// wss:// schemes. No network I/O.

module xiom.net.ws

use xiom.string;

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

// ws_default_port returns the default port for a ws scheme ("ws" -> 80,
// "wss" -> 443, anything else -> 80). Complexity: O(1). Pure.
pub fn ws_default_port(scheme: Str) -> Int {
  if scheme == "wss" {
    return 443;
  }
  80
}

// ws_parse_url splits a ws:// or wss:// URL into (host, port, path).
// The port is the explicit port from the URL when present, otherwise the
// scheme default. Returns Err for malformed input. Complexity: O(n).
pub fn ws_parse_url(url: Str) -> Result[(Str, Int, Str), Str] {
  let len = url.len();
  if len == 0 {
    return Err("empty websocket url");
  }
  let scheme_pos = idx_of(url, "://");
  if scheme_pos < 0 {
    return Err("missing scheme separator");
  }
  let scheme = string.str_slice(url, 0, scheme_pos);
  if scheme != "ws" && scheme != "wss" {
    return Err("unsupported websocket scheme");
  }
  var default_port = ws_default_port(scheme);
  var rest = string.str_slice(url, scheme_pos + 3, len);
  if rest.len() == 0 {
    return Err("missing host");
  }
  var host = "";
  var port = default_port;
  var path = "/";
  var authority_end = rest.len();
  let path_start = idx_of(rest, "/");
  let query_start = idx_of(rest, "?");
  let frag_start = idx_of(rest, "#");
  if path_start >= 0 && path_start < authority_end { authority_end = path_start; }
  if query_start >= 0 && query_start < authority_end { authority_end = query_start; }
  if frag_start >= 0 && frag_start < authority_end { authority_end = frag_start; }
  var authority = string.str_slice(rest, 0, authority_end);
  if authority.len() == 0 {
    return Err("missing host");
  }
  let colon_pos = idx_of(authority, ":");
  if colon_pos >= 0 {
    host = string.str_slice(authority, 0, colon_pos);
    let port_str = string.str_slice(authority, colon_pos + 1, authority.len());
    if port_str.len() > 0 {
      port = str_to_int(port_str);
    }
  } else {
    host = authority;
  }
  if host.len() == 0 {
    return Err("missing host");
  }
  let after = string.str_slice(rest, authority_end, rest.len());
  if after.len() > 0 {
    var path_end = after.len();
    let q_pos = idx_of(after, "?");
    let f_pos = idx_of(after, "#");
    if q_pos >= 0 && q_pos < path_end { path_end = q_pos; }
    if f_pos >= 0 && f_pos < path_end { path_end = f_pos; }
    let p = string.str_slice(after, 0, path_end);
    if p.len() > 0 {
      path = p;
    }
  }
  Ok((host, port, path))
}

// ws_build_url builds a ws:// or wss:// URL from host, port, and path.
// When port matches the scheme default it is omitted. Complexity: O(1).
pub fn ws_build_url(scheme: Str, host: Str, port: Int, path: Str) -> Str {
  var result = scheme + "://" + host;
  var default_port = ws_default_port(scheme);
  if port > 0 && port != default_port {
    result = result + ":" + port.to_str();
  }
  var p = path;
  if p.len() == 0 {
    p = "/";
  }
  if p.byte_at(0) != 47 {
    p = "/" + p;
  }
  result + p
}

// ws_is_ws_url returns true if url starts with ws://.
// Complexity: O(n). Pure.
pub fn ws_is_ws_url(url: Str) -> Bool {
  let len = url.len();
  if len < 5 {
    return false;
  }
  string.str_slice(url, 0, 5) == "ws://"
}

// ws_is_wss_url returns true if url starts with wss://.
// Complexity: O(n). Pure.
pub fn ws_is_wss_url(url: Str) -> Bool {
  let len = url.len();
  if len < 6 {
    return false;
  }
  string.str_slice(url, 0, 6) == "wss://"
}
