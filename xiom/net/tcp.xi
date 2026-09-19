// XIOM -- TCP Helpers (xiom.net.tcp)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure TCP endpoint formatting and validation helpers. No network I/O.

module xiom.net.tcp

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

/// tcp_validate_port returns true if p is a valid TCP port (1-65535).
/// Complexity: O(1). Pure.
pub fn tcp_validate_port(p: Int) -> Bool {
  p > 0 && p <= 65535
}

/// tcp_is_valid_port is an alias for tcp_validate_port.
/// Complexity: O(1). Pure.
pub fn tcp_is_valid_port(p: Int) -> Bool {
  tcp_validate_port(p)
}

/// tcp_parse_endpoint splits a "host:port" string into (host, port).
/// Returns None if no colon or a malformed port is present. The host may
/// be empty (an empty host string is rejected). Complexity: O(n). Pure.
pub fn tcp_parse_endpoint(s: Str) -> Option[(Str, Int)] {
  let colon = idx_of(s, ":");
  if colon <= 0 {
    return None;
  }
  let host = string.str_slice(s, 0, colon);
  if host.len() == 0 {
    return None;
  }
  let port_str = string.str_slice(s, colon + 1, s.len());
  if port_str.len() == 0 {
    return None;
  }
  var i = 0;
  while i < port_str.len() {
    let b = port_str.byte_at(i);
    if b < 48 || b > 57 {
      return None;
    }
    i = i + 1;
  }
  let port = str_to_int(port_str);
  if !tcp_validate_port(port) {
    return None;
  }
  Some((host, port))
}

/// tcp_format_endpoint builds a "host:port" string.
/// Complexity: O(1). Pure.
pub fn tcp_format_endpoint(host: Str, port: Int) -> Str {
  host + ":" + port.to_str()
}
