// XIOM -- IPv4 Address Helpers (xiom.net.ip4)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure IPv4 address parsing, formatting, and classification helpers.
// No network I/O; all functions operate on strings and byte vectors.

module xiom.net.ip4

use xiom.string;

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

// parse_octet parses a single decimal octet segment (0-255), or None.
fn parse_octet(seg: Str) -> Option[Int] {
  let len = seg.len();
  if len == 0 || len > 3 {
    return None;
  }
  var value = 0;
  var i = 0;
  while i < len {
    let b = seg.byte_at(i);
    if b < 48 || b > 57 {
      return None;
    }
    value = value * 10 + (b as Int - 48);
    i = i + 1;
  }
  if value > 255 {
    return None;
  }
  Some(value)
}

/// ip4_parse parses a dotted-quad IPv4 string into four octets.
/// Invalid input (wrong segment count, non-numeric, or out-of-range
/// octets) returns Err. Complexity: O(n). Pure.
pub fn ip4_parse(s: Str) -> Result[Vec[UInt8], Str] {
  let len = s.len();
  if len < 7 || len > 15 {
    return Err("invalid IPv4 address: bad length");
  }
  let parts = split(s, ".");
  if parts.len() != 4 {
    return Err("invalid IPv4 address: expected 4 octets");
  }
  var result: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < 4 {
    let num = parse_octet(parts[i]);
    if num.is_none {
      return Err("invalid IPv4 address: bad octet");
    }
    result.push(num.value as UInt8);
    i = i + 1;
  }
  Ok(result)
}

/// ip4_validate returns true if s is a valid dotted-quad IPv4 address.
/// Complexity: O(n). Pure.
pub fn ip4_validate(s: Str) -> Bool {
  let parsed = ip4_parse(s);
  parsed.is_ok
}

/// ip4_to_str formats four octets as a dotted-quad string.
/// Returns Err if octets.len() is not 4. Complexity: O(1). Pure.
pub fn ip4_to_str(octets: &Vec[UInt8]) -> Result[Str, Str] {
  if octets.len() != 4 {
    return Err("invalid IPv4 address: expected 4 octets");
  }
  var result = "";
  var i = 0;
  while i < 4 {
    if i > 0 {
      result = result + ".";
    }
    let o = octets[i] as Int;
    result = result + o.to_str();
    i = i + 1;
  }
  Ok(result)
}

/// ip4_octets splits a dotted-quad IPv4 string into its four numeric
/// octets as Int. Invalid input returns an empty vector. Pure.
pub fn ip4_octets(s: Str) -> Vec[Int] {
  var result: Vec[Int] = Vec[Int]::new();
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => {
      var i = 0;
      while i < 4 {
        result.push(bytes[i] as Int);
        i = i + 1;
      }
    }
    Err(_) => {}
  }
  result
}

// octet_of parses the n-th octet of a valid IPv4 string (0-based),
// or None if invalid. Internal helper.
fn octet_of(s: Str, n: Int) -> Option[Int] {
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => Some(bytes[n] as Int);
    Err(_) => None;
  }
}

/// ip4_is_loopback returns true for 127.0.0.0/8.
/// Complexity: O(n). Pure.
pub fn ip4_is_loopback(s: Str) -> Bool {
  let first = octet_of(s, 0);
  match first {
    Some(v) => v == 127;
    None => false;
  }
}

/// ip4_is_private returns true for RFC 1918 ranges
/// (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16).
/// Complexity: O(n). Pure.
pub fn ip4_is_private(s: Str) -> Bool {
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => {
      let a = bytes[0] as Int;
      let b = bytes[1] as Int;
      if a == 10 { return true; }
      if a == 172 && b >= 16 && b <= 31 { return true; }
      if a == 192 && b == 168 { return true; }
      false
    }
    Err(_) => false;
  }
}

/// ip4_is_link_local returns true for 169.254.0.0/16.
/// Complexity: O(n). Pure.
pub fn ip4_is_link_local(s: Str) -> Bool {
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => {
      let a = bytes[0] as Int;
      let b = bytes[1] as Int;
      a == 169 && b == 254
    }
    Err(_) => false;
  }
}

/// ip4_is_multicast returns true for 224.0.0.0/4.
/// Complexity: O(n). Pure.
pub fn ip4_is_multicast(s: Str) -> Bool {
  let first = octet_of(s, 0);
  match first {
    Some(v) => v >= 224 && v <= 239;
    None => false;
  }
}

/// ip4_is_unspecified returns true for 0.0.0.0.
/// Complexity: O(n). Pure.
pub fn ip4_is_unspecified(s: Str) -> Bool {
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => {
      var all_zero = true;
      var i = 0;
      while i < 4 {
        if bytes[i] != 0 as UInt8 {
          all_zero = false;
        }
        i = i + 1;
      }
      all_zero
    }
    Err(_) => false;
  }
}

/// ip4_is_broadcast returns true for 255.255.255.255.
/// Complexity: O(n). Pure.
pub fn ip4_is_broadcast(s: Str) -> Bool {
  let parsed = ip4_parse(s);
  match parsed {
    Ok(bytes) => {
      var all_one = true;
      var i = 0;
      while i < 4 {
        if bytes[i] != 255 as UInt8 {
          all_one = false;
        }
        i = i + 1;
      }
      all_one
    }
    Err(_) => false;
  }
}
