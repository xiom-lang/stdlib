// XIOM - Network: Address Parsing
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.net.address

// Depends on: xiom.net

// ============================================================================
// Network address parsing and validation helpers for host:port strings.
// Supports bare hosts, "host:port", bracketed IPv6 ("[::1]:8080") and raw
// IPv6. Family classification delegates to xiom.net.ip (different names —
// safe). All functions are pure.
// ============================================================================

use xiom.string;
use xiom.net.ip;

// struct Address { family: Str; host: Str; port: Int }
//   family is "ipv4", "ipv6" or "hostname"; port 0 means "no explicit port".
pub type Address = {
  family: Str;
  host: Str;
  port: Int;
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

// parse_port parses the digits after the last ':' of an authority, or 0 when
// there is no port.
fn parse_port(s: Str) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 {
      return -1;
    }
    result = result * 10 + (b as Int - 48);
    if result > 65535 {
      return -1;
    }
    i = i + 1;
  }
  result
}

// split_host_port splits an authority into (host, port). A port of -1 means
// "present but invalid"; 0 means "absent".
fn split_host_port(s: Str) -> (Str, Int) {
  let len = s.len();
  if len == 0 {
    return ("", 0);
  }
  if s.byte_at(0) == 91 {
    // Bracketed IPv6 literal: [::1] or [::1]:8080
    let close = idx_of(s, "]");
    if close < 0 {
      return ("", -1);
    }
    let host = string.str_slice(s, 1, close);
    if close + 1 == len {
      return (host, 0);
    }
    if s.byte_at(close + 1) == 58 {
      let pstr = string.str_slice(s, close + 2, len);
      let p = parse_port(pstr);
      if p < 0 {
        return (host, -1);
      }
      return (host, p);
    }
    return ("", -1);
  }
  var colons: Int = 0;
  var i: Int = 0;
  while i < len {
    if s.byte_at(i) == 58 {
      colons = colons + 1;
    }
    i = i + 1;
  }
  if colons > 1 {
    // Raw IPv6 literal without brackets: no port is carried.
    return (s, 0);
  }
  if colons == 1 {
    let c = idx_of(s, ":");
    let host = string.str_slice(s, 0, c);
    let pstr = string.str_slice(s, c + 1, len);
    if host.len() == 0 {
      return ("", -1);
    }
    let p = parse_port(pstr);
    if p < 0 {
      return (host, -1);
    }
    return (host, p);
  }
  (s, 0)
}

// classify returns the address family for a host string.
fn classify(host: Str) -> Str {
  let v4 = ip.ipv4_parse(host);
  if v4.is_some {
    return "ipv4";
  }
  let v6 = ip.ipv6_parse(host);
  if v6.is_some {
    return "ipv6";
  }
  "hostname"
}

/// Parse a host:port address string into an Address.
/// Parameters: s — the address string ("example.com:8080", "127.0.0.1",
///          "[::1]:53", "example.com").
/// Returns: Some(Address) when the string is well-formed (non-empty host and
///          a valid port if present), None otherwise.
/// Complexity: O(n). Pure.
pub fn address_parse(s: Str) -> Option[Address] {
  if s.len() == 0 {
    return None;
  }
  let parts = split_host_port(s);
  let host = parts.0;
  let port = parts.1;
  if host.len() == 0 || port < 0 {
    return None;
  }
  let fam = classify(host);
  Some(Address{ family: fam; host: host; port: port; })
}

/// Extract the host part of an address string.
/// Parameters: s — the address string.
/// Returns: the host (without brackets for IPv6 literals), or "" when the
///          string is not a valid address.
/// Complexity: O(n). Pure.
pub fn address_host(s: Str) -> Str {
  let parsed = address_parse(s);
  match parsed {
    Some(a) => a.host;
    None => "";
  }
}

/// Extract the port part of an address string.
/// Parameters: s — the address string.
/// Returns: the port number (0 when absent), or 0 for an invalid address.
/// Complexity: O(n). Pure.
pub fn address_port(s: Str) -> Int {
  let parsed = address_parse(s);
  match parsed {
    Some(a) => a.port;
    None => 0;
  }
}

/// Test if the host part of an address string is an IPv4 address.
/// Parameters: s — the address string.
/// Returns: true when the string parses and its host is dotted-quad IPv4.
/// Complexity: O(n). Pure.
pub fn address_is_ipv4(s: Str) -> Bool {
  let parsed = address_parse(s);
  match parsed {
    Some(a) => a.family == "ipv4";
    None => false;
  }
}

/// Test if the host part of an address string is an IPv6 address.
/// Parameters: s — the address string.
/// Returns: true when the string parses and its host is an IPv6 literal.
/// Complexity: O(n). Pure.
pub fn address_is_ipv6(s: Str) -> Bool {
  let parsed = address_parse(s);
  match parsed {
    Some(a) => a.family == "ipv6";
    None => false;
  }
}

/// Test if the address string is well-formed.
/// Parameters: s — the address string.
/// Returns: true when parsing succeeds with a non-empty host and a valid port
///          (0..65535) if one is present.
/// Complexity: O(n). Pure.
pub fn address_is_valid(s: Str) -> Bool {
  let parsed = address_parse(s);
  parsed.is_some
}
