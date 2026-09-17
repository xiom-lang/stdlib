// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_rep3
use xiom.io;
use xiom.string;
use xiom.net.ip;

type Rec = { family: Str; host: Str; port: Int; }

fn idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle { return i; }
    i = i + 1;
  }
  -1
}

fn classify(host: Str) -> Str {
  var v4 = ip.ipv4_parse(host);
  if v4.is_some { return "ipv4"; }
  "hostname"
}

fn split_host_port(s: Str) -> (Str, Int) {
  let len = s.len();
  var colons: Int = 0;
  var i: Int = 0;
  while i < len {
    if s.byte_at(i) == 58 { colons = colons + 1; }
    i = i + 1;
  }
  if colons == 1 {
    let c = idx_of(s, ":");
    let host = string.str_slice(s, 0, c);
    let pstr = string.str_slice(s, c + 1, len);
    if host.len() == 0 { return ("", -1); }
    let p = parse_port(pstr);
    if p < 0 { return (host, -1); }
    return (host, p);
  }
  (s, 0)
}

fn parse_port(s: Str) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  while i < s.len() {
    let b = s.byte_at(i);
    if b < 48 || b > 57 { return -1; }
    result = result * 10 + (b as Int - 48);
    if result > 65535 { return -1; }
    i = i + 1;
  }
  result
}

fn address_parse(s: Str) -> Option[Rec] {
  if s.len() == 0 { return None; }
  let parts = split_host_port(s);
  let host = parts.0;
  let port = parts.1;
  if host.len() == 0 || port < 0 { return None; }
  let fam = classify(host);
  Some(Rec{ family: fam; host: host; port: port; })
}

fn main() -> Int {
  var a = address_parse("example.com:8080");
  match a {
    None => { io.println("none"); return 1; }
    Some(r) => { io.println("host=[" + r.host + "] port=" + r.port + " fam=[" + r.family + "]"); }
  }
  return 0;
}
