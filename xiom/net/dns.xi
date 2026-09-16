// XIOM -- DNS Record Utilities (xiom.net.dns)
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Pure DNS record-string utilities: IP address presentation parsing,
// hostname validation, and zone-file record line parsing. No wire protocol.

module xiom.net.dns

use xiom.string;
use xiom.net.ip4 as net4;
use xiom.net.ip6 as net6;

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

fn hex_digit_value(b: UInt8) -> Int {
  let c = b as Int;
  if c >= 48 && c <= 57 { return c - 48; }
  if c >= 97 && c <= 102 { return c - 87; }
  if c >= 65 && c <= 70 { return c - 55; }
  -1
}

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

// parse_groups splits a hex-group string on ':' and validates each group.
// A group value of -1 signals an invalid group.
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
    result.push(v.value);
    i = i + 1;
  }
  result
}

fn has_bad_group(g: &Vec[Int]) -> Bool {
  var i = 0;
  while i < g.len() {
    if g[i] == -1 {
      return true;
    }
    i = i + 1;
  }
  false
}

fn push_hex16(dst: &mut Vec[UInt8], group: Int) {
  dst.push(((group >> 8) & 0xFF) as UInt8);
  dst.push((group & 0xFF) as UInt8);
}

fn hex_char(nib: Int) -> UInt8 {
  if nib < 10 {
    return (48 + nib) as UInt8;
  }
  (87 + nib) as UInt8
}

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
  Str::from_utf8(buf)
}

fn is_ws(b: UInt8) -> Bool {
  b == 32 || b == 9
}

fn split_whitespace(s: Str) -> Vec[Str] {
  var result: Vec[Str] = Vec[Str]::new();
  let len = s.len();
  var i = 0;
  while i < len {
    while i < len && is_ws(s.byte_at(i)) {
      i = i + 1;
    }
    if i < len {
      var start = i;
      while i < len && !is_ws(s.byte_at(i)) {
        i = i + 1;
      }
      result.push(string.str_slice(s, start, i));
    }
  }
  result
}

// dns_parse_ipv4 parses "a.b.c.d" into 4 bytes, or None on invalid input.
// Delegates to the canonical xiom.net.ip4 (dedup wave, 2026-09-16; parity
// proven in p_dns_parity). The Option/Result translation binds the parsed
// value to a named local first (R28 workaround: `.value` on a temporary
// aggregate payload is corrupt).
pub fn dns_parse_ipv4(s: Str) -> Option[Vec[UInt8]] {
  let r = net4.ip4_parse(s);
  match r {
    Ok(b) => { return Some(b); },
    Err(_) => { return None; },
  }
}

// dns_ipv4_to_str formats 4 bytes as "a.b.c.d", or None if the length is
// not 4. Delegates to the canonical xiom.net.ip4.
pub fn dns_ipv4_to_str(octets: &Vec[UInt8]) -> Option[Str] {
  let r = net4.ip4_to_str(octets);
  match r {
    Ok(s) => { return Some(s); },
    Err(_) => { return None; },
  }
}

// dns_parse_ipv6 parses a full-form IPv6 address (8 hex groups) or a
// compressed form with a single "::" into 16 bytes. Returns None on
// invalid input. Delegates to the canonical xiom.net.ip6 (parity proven in
// p_dns_parity).
pub fn dns_parse_ipv6(s: Str) -> Option[Vec[UInt8]] {
  let r = net6.ip6_parse(s);
  match r {
    Ok(b) => { return Some(b); },
    Err(_) => { return None; },
  }
}

// dns_ipv6_to_str formats 16 bytes as a full-form IPv6 address (8 groups,
// no "::" compression). Delegates to the canonical xiom.net.ip6 (same
// full-form convention; parity proven in p_dns_parity).
pub fn dns_ipv6_to_str(bytes: &Vec[UInt8]) -> Option[Str] {
  let r = net6.ip6_to_str(bytes);
  match r {
    Ok(s) => { return Some(s); },
    Err(_) => { return None; },
  }
}

// dns_parse_record_line parses a presentation-format zone record line
// such as "example.com. 3600 IN A 93.184.216.34" into (name, type, rdata).
pub fn dns_parse_record_line(line: Str) -> Option[(Str, Str, Str)] {
  let tokens = split_whitespace(line);
  if tokens.len() < 4 {
    return None;
  }
  let name = tokens[0];
  let rtype = tokens[3];
  var rdata = "";
  var i = 4;
  while i < tokens.len() {
    if i > 4 {
      rdata = rdata + " ";
    }
    rdata = rdata + tokens[i];
    i = i + 1;
  }
  Some((name, rtype, rdata))
}

// dns_is_valid_hostname validates a hostname: labels of [A-Za-z0-9-] with
// no leading/trailing hyphen, 1-63 chars each, total length <= 253, at
// least one label, and no empty labels. A single trailing dot is allowed.
pub fn dns_is_valid_hostname(name: Str) -> Bool {
  let len = name.len();
  if len == 0 || len > 253 {
    return false;
  }
  var s = name;
  if s.byte_at(len - 1) == 46 {
    s = string.str_slice(name, 0, len - 1);
  }
  if s.len() == 0 {
    return false;
  }
  let labels = split(s, ".");
  var i = 0;
  while i < labels.len() {
    let lbl = labels[i];
    let llen = lbl.len();
    if llen == 0 || llen > 63 {
      return false;
    }
    if string.byte_at(lbl, 0) == 45 || string.byte_at(lbl, llen - 1) == 45 {
      return false;
    }
    var j = 0;
    while j < llen {
      let b = string.byte_at(lbl, j);
      if !((b >= 48 && b <= 57) || (b >= 65 && b <= 90) || (b >= 97 && b <= 122) || b == 45) {
        return false;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  true
}

// dns_reverse_ipv4 formats 4 bytes as the in-addr.arpa reverse name,
// or None if the length is not 4.
pub fn dns_reverse_ipv4(octets: &Vec[UInt8]) -> Option[Str] {
  if octets.len() != 4 {
    return None;
  }
  var result = "";
  var i = 3;
  while i >= 0 {
    if i < 3 {
      result = result + ".";
    }
    let o = octets[i] as Int;
    result = result + o.to_str();
    i = i - 1;
  }
  result = result + ".in-addr.arpa";
  Some(result)
}

// dns_well_known_port maps a well-known service name to its default port,
// or None for unknown services.
pub fn dns_well_known_port(service: Str) -> Option[Int] {
  if service == "http" { return Some(80); }
  if service == "https" { return Some(443); }
  if service == "ftp" { return Some(21); }
  if service == "ssh" { return Some(22); }
  if service == "telnet" { return Some(23); }
  if service == "smtp" { return Some(25); }
  if service == "dns" { return Some(53); }
  if service == "dhcp" { return Some(67); }
  if service == "ntp" { return Some(123); }
  if service == "pop3" { return Some(110); }
  if service == "imap" { return Some(143); }
  if service == "snmp" { return Some(161); }
  if service == "ldap" { return Some(389); }
  if service == "irc" { return Some(6667); }
  None
}
