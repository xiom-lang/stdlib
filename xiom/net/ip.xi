// XIOM - Networking: IP Addresses
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.net.ip

// Depends on: xiom.net + xiom.string

// ============================================================================
// IPv4/IPv6 parsing, formatting, classification, masking and subnet tests.
// IPv4 handling delegates to xiom.net.ip4 (different names -- safe); IPv6
// handling delegates to xiom.net.ip6 for validation and expansion and keeps
// the 16-bit-group helpers local. All functions are pure and never touch the
// network stack.
// ============================================================================

use xiom.string;
use xiom.net.ip4;
use xiom.net.ip6;

// type IpAddr - an IP address enum: V4 holding four octets, V6 holding eight
// 16-bit parts.
pub type IpAddr = enum {
  V4(octets: Vec[UInt8]),
  V6(parts: Vec[UInt16]),
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

// hex_digit_value returns the numeric value of a hex digit byte, or -1.
fn hex_digit_value(b: UInt8) -> Int {
  let c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  -1
}

// parse_hex_group parses one 1..4-digit hex group into an Int, or None.
fn parse_hex_group(seg: Str) -> Option[Int] {
  let len = seg.len();
  if len == 0 || len > 4 {
    return None;
  }
  var value = 0;
  var i = 0;
  while i < len {
    let v = hex_digit_value(seg.byte_at(i));
    if v < 0 {
      return None;
    }
    value = value * 16 + v;
    i = i + 1;
  }
  Some(value)
}

// parse_groups parses a colon-separated run of hex groups; a marker of -1
// signals an invalid group.
fn parse_groups(s: Str) -> Vec[Int] {
  var result: Vec[Int] = Vec[Int]::new();
  if s.len() == 0 {
    return result;
  }
  let parts = split(s, ":");
  var i = 0;
  while i < parts.len() {
    let v = parse_hex_group(parts[i]);
    if v.is_none {
      result.push(-1);
      return result;
    }
    let vv = v.value;
    result.push(vv);
    i = i + 1;
  }
  result
}

// has_bad_group returns true if any parsed group marker is -1.
fn has_bad_group(g: &Vec[Int]) -> Bool {
  var i = 0;
  while i < g.len() {
    let v = g[i];
    if v == -1 {
      return true;
    }
    i = i + 1;
  }
  false
}

// hex_char returns the lowercase hex byte for a nibble (0-15).
fn hex_char(nib: Int) -> UInt8 {
  if nib < 10 {
    return (48 + nib) as UInt8;
  }
  (87 + nib) as UInt8
}

// hex4 formats a 16-bit group as lowercase hex without leading zeros
// (0 -> "0").
fn hex4(group: Int) -> Str {
  if group == 0 {
    return "0";
  }
  var buf: Vec[UInt8] = Vec[UInt8]::new();
  var started = false;
  var shift = 12;
  while shift >= 0 {
    let nib = (group >> shift) & 0xF;
    if nib != 0 || started {
      started = true;
      buf.push(hex_char(nib));
    }
    shift = shift - 4;
  }
  let s = Str::from_utf8(buf);
  s
}

// push_hex16 appends a 16-bit group as two big-endian bytes.
fn push_hex16(dst: &mut Vec[UInt8], group: Int) {
  dst.push(((group >> 8) & 0xFF) as UInt8);
  dst.push((group & 0xFF) as UInt8);
}

/// Parse a dotted-quad IPv4 string into four octets.
/// Parameters: s -- the address string.
/// Returns: Some(four octets) for a valid address, None otherwise.
/// Complexity: O(n). Pure.
pub fn ipv4_parse(s: Str) -> Option[Vec[UInt8]] {
  let r = ip4.ip4_parse(s);
  match r {
    Ok(b) => Some(b);
    Err(_) => None;
  }
}

/// Format four octets as a dotted-quad IPv4 string.
/// Parameters: octets -- at least four octets (only the first four are used).
/// Returns: the "a.b.c.d" representation, or "" for an undersized vector.
/// Complexity: O(1). Pure.
pub fn ipv4_to_string(octets: &Vec[UInt8]) -> Str {
  if octets.len() < 4 {
    return "";
  }
  let r = ip4.ip4_to_str(octets);
  match r {
    Ok(s) => s;
    Err(_) => "";
  }
}

/// Parse an IPv6 string (full form or single "::" compression) into eight
/// 16-bit groups.
/// Parameters: s -- the address string.
/// Returns: Some(eight groups) for a valid address, None otherwise.
/// Complexity: O(n). Pure.
pub fn ipv6_parse(s: Str) -> Option[Vec[UInt16]] {
  let r = ip6.ip6_parse(s);
  if r.is_err {
    return None;
  };
  let b = r.value;
  var groups = Vec[UInt16].new();
  var i = 0;
  while i + 1 < b.len() {
    let hi = b[i] as Int;
    let lo = b[i + 1] as Int;
    groups.push(((hi << 8) | lo) as UInt16);
    i = i + 2;
  };
  return Some(groups);
}

// (local IPv6 parser removed 2026-09-16: ipv6_parse/ipv6_to_string delegate
// to xiom.net.ip6; parity proven in p_netip_parity)


/// Format eight 16-bit parts as a full-form IPv6 string (no "::" compression,
/// leading zeros elided).
/// Parameters: parts -- exactly eight 16-bit groups.
/// Returns: the colon-separated string, or "" for a vector of the wrong size.
/// Complexity: O(8). Pure.
pub fn ipv6_to_string(parts: &Vec[UInt16]) -> Str {
  if parts.len() != 8 {
    return "";
  }
  var b = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    let g = parts[i] as Int;
    b.push(((g >> 8) & 0xFF) as UInt8);
    b.push((g & 0xFF) as UInt8);
    i = i + 1;
  };
  let r = ip6.ip6_to_str(&b);
  match r {
    Ok(s) => { return s; },
    Err(_) => { return ""; },
  }
}

/// Parse an IPv4 or IPv6 string into an IpAddr.
/// Parameters: s -- the address string.
/// Returns: Some(IpAddr) for a valid address, None otherwise.
/// Complexity: O(n). Pure.
pub fn ip_parse(s: Str) -> Option[IpAddr] {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => Some(IpAddr.V4(b));
      None => None;
    }
  } else {
    let v6 = ipv6_parse(s);
    match v6 {
      Some(p) => Some(IpAddr.V6(p));
      None => None;
    }
  }
}

/// Returns true for loopback addresses (127.0.0.0/8, ::1).
/// Parameters: s -- the address string.
/// Returns: true when the address parses and is loopback.
/// Complexity: O(n). Pure.
pub fn ip_is_loopback(s: Str) -> Bool {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => {
        let o = b[0] as Int;
        return o == 127;
      }
      None => return false;
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      if p.len() != 8 {
        return false;
      }
      var i = 0;
      while i < 7 {
        let g = p[i] as Int;
        if g != 0 {
          return false;
        }
        i = i + 1;
      }
      let last = p[7] as Int;
      return last == 1;
    }
    None => false;
  }
}

/// Returns true for private-use ranges (10/8, 172.16/12, 192.168/16,
/// fc00::/7).
/// Parameters: s -- the address string.
/// Returns: true when the address parses and is private-use.
/// Complexity: O(n). Pure.
pub fn ip_is_private(s: Str) -> Bool {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => {
        let a = b[0] as Int;
        let bb = b[1] as Int;
        if a == 10 { return true; }
        if a == 172 && bb >= 16 && bb <= 31 { return true; }
        if a == 192 && bb == 168 { return true; }
        return false;
      }
      None => return false;
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      let b0 = p[0] as Int;
      return (b0 & 0xFE00) == 0xFC00;
    }
    None => false;
  }
}

/// Returns true for link-local ranges (169.254/16, fe80::/10).
/// Parameters: s -- the address string.
/// Returns: true when the address parses and is link-local.
/// Complexity: O(n). Pure.
pub fn ip_is_link_local(s: Str) -> Bool {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => {
        let a = b[0] as Int;
        let bb = b[1] as Int;
        return a == 169 && bb == 254;
      }
      None => return false;
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      let b0 = p[0] as Int;
      return (b0 & 0xFFC0) == 0xFE80;
    }
    None => false;
  }
}

/// Returns true for multicast ranges (224.0.0.0/4, ff00::/8).
/// Parameters: s -- the address string.
/// Returns: true when the address parses and is multicast.
/// Complexity: O(n). Pure.
pub fn ip_is_multicast(s: Str) -> Bool {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => {
        let o = b[0] as Int;
        return o >= 224 && o <= 239;
      }
      None => return false;
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      let b0 = p[0] as Int;
      return (b0 & 0xFF00) == 0xFF00;
    }
    None => false;
  }
}

/// Returns true for the all-zero address (0.0.0.0, ::).
/// Parameters: s -- the address string.
/// Returns: true when the address parses and is all zero.
/// Complexity: O(n). Pure.
pub fn ip_is_unspecified(s: Str) -> Bool {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    match v4 {
      Some(b) => {
        var i = 0;
        while i < 4 {
          let o = b[i] as Int;
          if o != 0 {
            return false;
          }
          i = i + 1;
        }
        return true;
      }
      None => return false;
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      var i = 0;
      while i < 8 {
        let g = p[i] as Int;
        if g != 0 {
          return false;
        }
        i = i + 1;
      }
      true
    }
    None => false;
  }
}

// ipv4_mask_octet returns the masked octet given the number of leading mask
// bits in 0..8.
fn ipv4_mask_octet(byte_val: Int, bits: Int) -> Int {
  var mask = 0;
  var i = 0;
  while i < 8 {
    if i < bits {
      mask = mask | (1 << (7 - i));
    }
    i = i + 1;
  }
  (byte_val & mask) & 0xFF
}

/// Apply a CIDR prefix mask to an address and return the masked address
/// string.
/// Parameters: s -- the address string; prefix -- the prefix length (0..32 for
///          IPv4, 0..128 for IPv6).
/// Returns: the masked address, or "" for invalid input or an out-of-range
///          prefix.
/// Complexity: O(n). Pure.
pub fn ip_masked(s: Str, prefix: Int) -> Str {
  if prefix < 0 {
    return "";
  }
  let v4 = ipv4_parse(s);
  if v4.is_some {
    if prefix > 32 {
      return "";
    }
    match v4 {
      Some(b) => {
        var result = "";
        var i = 0;
        while i < 4 {
          if i > 0 {
            result = result + ".";
          }
          let bits = prefix - i * 8;
          var bits_v = bits;
          if bits_v < 0 { bits_v = 0; }
          if bits_v > 8 { bits_v = 8; }
          let o = b[i] as Int;
          let m = ipv4_mask_octet(o, bits_v);
          result = result + m.to_str();
          i = i + 1;
        }
        return result;
      }
      None => return "";
    }
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      if prefix > 128 {
        return "";
      }
      var result = "";
      var i = 0;
      while i < 8 {
        if i > 0 {
          result = result + ":";
        }
        let bits = prefix - i * 16;
        var bits_v = bits;
        if bits_v < 0 { bits_v = 0; }
        if bits_v > 16 { bits_v = 16; }
        let g = p[i] as Int;
        let m = ipv6_mask_group(g, bits_v);
        result = result + hex4(m);
        i = i + 1;
      }
      result
    }
    None => "";
  }
}

// ipv6_mask_group returns the masked 16-bit group given leading mask bits in
// 0..16.
fn ipv6_mask_group(group: Int, bits: Int) -> Int {
  var mask = 0;
  var i = 0;
  while i < 16 {
    if i < bits {
      mask = mask | (1 << (15 - i));
    }
    i = i + 1;
  }
  group & mask
}

/// Test whether ip falls inside a CIDR subnet ("192.168.1.0/24" or
/// "2001:db8::/32").
/// Parameters: ip -- the address string; subnet -- "address/prefix".
/// Returns: true when the masked addresses are equal.
/// Complexity: O(n). Pure.
pub fn ip_in_subnet(ip: Str, subnet: Str) -> Bool {
  let slash = idx_of(subnet, "/");
  if slash < 0 {
    return false;
  }
  let addr = string.str_slice(subnet, 0, slash);
  let pstr = string.str_slice(subnet, slash + 1, subnet.len());
  if pstr.len() == 0 {
    return false;
  }
  var prefix: Int = 0;
  var pi = 0;
  while pi < pstr.len() {
    let b = pstr.byte_at(pi);
    if b < 48 || b > 57 {
      return false;
    }
    prefix = prefix * 10 + (b as Int - 48);
    pi = pi + 1;
  }
  let masked_ip = ip_masked(ip, prefix);
  let masked_sub = ip_masked(addr, prefix);
  if masked_ip.len() == 0 || masked_sub.len() == 0 {
    return false;
  }
  masked_ip == masked_sub
}

/// Expand an IPv6 string to the full eight-part form with zero padding.
/// Parameters: s -- the address string.
/// Returns: the "0000:0000:...:0000" form, or "" for invalid input. IPv4
///          input is returned unchanged.
/// Complexity: O(n). Pure.
pub fn ip_expand(s: Str) -> Str {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    return s;
  }
  let r = ip6.ip6_expand(s);
  match r {
    Ok(e) => e;
    Err(_) => "";
  }
}

/// Compress an IPv6 string using "::" and leading-zero elision.
/// Parameters: s -- the address string.
/// Returns: the canonical compressed form, or "" for invalid input. IPv4
///          input is returned unchanged.
/// Complexity: O(n). Pure.
pub fn ip_compress(s: Str) -> Str {
  let v4 = ipv4_parse(s);
  if v4.is_some {
    return s;
  }
  let v6 = ipv6_parse(s);
  match v6 {
    Some(p) => {
      var fresh6 = Vec[UInt16].new();
      var k = 0;
      while k < p.len() {
        fresh6.push(p[k]);
        k = k + 1;
      }
      _v6_compress(fresh6)
    }
    None => "";
  }
}

// Canonical IPv6 text with longest-zero-run "::" compression and lowercase
// hex without leading zeros. Builds the string directly (no intermediate
// Vec[Str], which corrupts under string concatenation). Takes the groups by
// value so module-returned vectors never re-enter a &Vec parameter.
fn _v6_compress(groups: Vec[UInt16]) -> Str {
  var best_start = -1;
  var best_len = 0;
  var i: Int = 0;
  while i < groups.len() {
    let g = groups[i] as Int;
    if g == 0 {
      var j = i;
      while j < groups.len() {
        let gj = groups[j] as Int;
        if gj != 0 {
          break;
        }
        j = j + 1;
      }
      let run = j - i;
      if run > best_len && run >= 2 {
        best_len = run;
        best_start = i;
      }
      i = j;
    } else {
      i = i + 1;
    }
  }
  var result = "";
  var k: Int = 0;
  while k < groups.len() {
    if k == best_start {
      result = result + "::";
      k = k + best_len;
    } else {
      let gv = groups[k] as Int;
      if result.len() > 0 {
        let ends_colon = string.str_ends_with(result, ":");
        if !ends_colon {
          result = result + ":";
        }
      }
      result = result + hex4(gv);
      k = k + 1;
    }
  }
  result
}

/// Split an IPv4 string into its numeric octets.
/// Parameters: s -- the address string.
/// Returns: four octets for a valid address, an empty vector otherwise.
/// Complexity: O(n). Pure.
pub fn ip_octets(s: Str) -> Vec[Int] {
  let result = ip4.ip4_octets(s);
  result
}
