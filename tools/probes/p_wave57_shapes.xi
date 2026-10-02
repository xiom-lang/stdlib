// p_wave57_shapes.xi -- wave 57 shape validation: xiom.net address family
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-57 clauses on xiom.net.{address,ip4,ip6,ip,url}
// (46 pub fns). Includes the two fix-first witnesses: ipv4_to_string must
// use the first four octets per its doc (currently ""), and url_join's
// "//" reference branch must normalize per its doc. Payloads are read
// through match; presence checks use is_some/is_ok only. Returns 0 when
// every case holds.

module p_wave57_shapes

use xiom.net.address;
use xiom.net.ip4;
use xiom.net.ip6;
use xiom.net.ip;
use xiom.net.url;

fn main() -> Int {
  // ---- address
  match address.address_parse("example.com:8080") {
    Some(a) => {
      if !(a.host == "example.com") { return 1; }
      if a.port != 8080 { return 2; }
      if !(a.family == "hostname") { return 3; }
    },
    None => { return 4; },
  }
  match address.address_parse("[::1]:53") {
    Some(a) => {
      if !(a.host == "::1") { return 5; }
      if a.port != 53 { return 6; }
      if !(a.family == "ipv6") { return 7; }
    },
    None => { return 8; },
  }
  if address.address_parse("").is_some { return 9; }
  if address.address_parse(":80").is_some { return 10; }
  if !(address.address_host("[2001:db8::1]:443") == "2001:db8::1") { return 11; }
  if !(address.address_host("") == "") { return 12; }
  if !address.address_is_ipv4("10.0.0.1:80") { return 13; }
  if !address.address_is_ipv6("[::1]") { return 14; }
  if address.address_is_ipv4("1.2.3.4.5") { return 15; }
  if !address.address_is_valid("host:") { return 16; }
  if address.address_is_valid("host:99999") { return 17; }
  if address.address_port("example.com:99999") != 0 { return 18; }
  if address.address_port("example.com:80") != 80 { return 19; }

  // ---- ip4
  match ip4.ip4_parse("1.2.3.4") {
    Ok(v) => {
      if v.len() != 4 { return 20; }
      if v[0] != (1 as UInt8) { return 21; }
    },
    Err(_) => { return 22; },
  }
  if ip4.ip4_parse("1.2.3").is_ok { return 23; }
  match ip4.ip4_parse("255.255.255.255") {
    Ok(v) => {
      if v[3] != (255 as UInt8) { return 24; }
    },
    Err(_) => { return 25; },
  }
  if ip4.ip4_validate("") { return 26; }
  if !ip4.ip4_validate("127.0.0.1") { return 27; }
  var four = Vec[UInt8].new();
  four.push(1);
  four.push(2);
  four.push(3);
  four.push(4);
  match ip4.ip4_to_str(&four) {
    Ok(s) => {
      if !(s == "1.2.3.4") { return 28; }
    },
    Err(_) => { return 29; },
  }
  var three = Vec[UInt8].new();
  three.push(1);
  three.push(2);
  three.push(3);
  if ip4.ip4_to_str(&three).is_ok { return 30; }
  var octs4 = ip4.ip4_octets("192.168.0.1");
  if octs4.len() != 4 { return 31; }
  if octs4[0] != 192 { return 32; }
  if ip4.ip4_octets("bad").len() != 0 { return 33; }
  if !ip4.ip4_is_loopback("127.0.0.1") { return 34; }
  if ip4.ip4_is_loopback("128.0.0.1") { return 35; }
  if !ip4.ip4_is_private("172.31.255.255") { return 36; }
  if ip4.ip4_is_private("172.32.0.0") { return 37; }
  if !ip4.ip4_is_link_local("169.254.1.1") { return 38; }
  if !ip4.ip4_is_multicast("239.255.255.255") { return 39; }
  if ip4.ip4_is_multicast("240.0.0.1") { return 40; }
  if !ip4.ip4_is_unspecified("0.0.0.0") { return 41; }
  if !ip4.ip4_is_broadcast("255.255.255.255") { return 42; }
  if ip4.ip4_is_broadcast("255.255.255.254") { return 43; }

  // ---- ip6
  match ip6.ip6_parse("::1") {
    Ok(b) => {
      if b.len() != 16 { return 44; }
      if b[15] != (1 as UInt8) { return 45; }
    },
    Err(_) => { return 46; },
  }
  match ip6.ip6_parse("2001:db8::1") {
    Ok(b) => {
      if b[0] != (0x20 as UInt8) { return 47; }
      if b[1] != (0x01 as UInt8) { return 48; }
    },
    Err(_) => { return 49; },
  }
  if ip6.ip6_parse("1::2::3").is_ok { return 50; }
  if ip6.ip6_parse(":").is_ok { return 51; }
  if !ip6.ip6_validate("::") { return 52; }
  if ip6.ip6_validate("gggg::") { return 53; }
  var sixteen = Vec[UInt8].new();
  var zi = 0;
  while zi < 16 { sixteen.push(0); zi = zi + 1; }
  match ip6.ip6_to_str(&sixteen) {
    Ok(s) => {
      if !(s == "0:0:0:0:0:0:0:0") { return 54; }
    },
    Err(_) => { return 55; },
  }
  if ip6.ip6_to_str(&three).is_ok { return 56; }
  match ip6.ip6_expand("::1") {
    Ok(s) => {
      if !(s == "0000:0000:0000:0000:0000:0000:0000:0001") { return 57; }
    },
    Err(_) => { return 58; },
  }
  if !ip6.ip6_is_loopback("::1") { return 59; }
  if ip6.ip6_is_loopback("::2") { return 60; }
  if !ip6.ip6_is_unspecified("::") { return 61; }
  if !ip6.ip6_is_multicast("ff02::1") { return 62; }
  if !ip6.ip6_is_link_local("fe80::1") { return 63; }
  if ip6.ip6_is_link_local("fec0::1") { return 64; }

  // ---- ip (address-family facade)
  match ip.ipv4_parse("1.2.3.4") {
    Some(b) => {
      if b.len() != 4 { return 65; }
    },
    None => { return 66; },
  }
  if ip.ipv4_parse("1.2.3").is_some { return 67; }
  // fix-first F1: doc says only the first four octets are used
  var five = Vec[UInt8].new();
  five.push(1);
  five.push(2);
  five.push(3);
  five.push(4);
  five.push(5);
  if !(ip.ipv4_to_string(&five) == "1.2.3.4") { return 68; }
  match ip.ipv6_parse("::1") {
    Some(g) => {
      if g.len() != 8 { return 69; }
      if g[7] != (1 as UInt16) { return 70; }
    },
    None => { return 71; },
  }
  var parts8 = Vec[UInt16].new();
  var pi = 0;
  while pi < 8 { parts8.push(0); pi = pi + 1; }
  // ipv6_to_string returns Str; the Result-style match shape hits the
  // p_wave57_probe_ir.xi compiler finding, so compare directly.
  if !(ip.ipv6_to_string(&parts8) == "0:0:0:0:0:0:0:0") { return 72; }
  if !ip.ip_parse("1.2.3.4").is_some { return 74; }
  if !ip.ip_parse("::1").is_some { return 75; }
  if ip.ip_parse("x").is_some { return 76; }
  if !ip.ip_is_loopback("127.0.0.1") { return 77; }
  if !ip.ip_is_loopback("::1") { return 78; }
  if ip.ip_is_loopback("::2") { return 79; }
  if !ip.ip_is_private("10.0.0.1") { return 80; }
  if !ip.ip_is_private("fc00::") { return 81; }
  if ip.ip_is_private("fe00::") { return 82; }
  if !ip.ip_is_link_local("169.254.1.1") { return 83; }
  if !ip.ip_is_link_local("fe80::") { return 84; }
  if ip.ip_is_link_local("fec0::") { return 85; }
  if !ip.ip_is_multicast("224.0.0.1") { return 86; }
  if !ip.ip_is_multicast("ff02::1") { return 87; }
  if ip.ip_is_multicast("223.255.255.255") { return 88; }
  if !ip.ip_is_unspecified("0.0.0.0") { return 89; }
  if !ip.ip_is_unspecified("::") { return 90; }
  if ip.ip_is_unspecified("0.0.0.1") { return 91; }
  if !(ip.ip_masked("192.168.1.130", 24) == "192.168.1.0") { return 92; }
  if !(ip.ip_masked("2001:db8::1", 32) == "2001:db8:0:0:0:0:0:0") { return 93; }
  if !(ip.ip_masked("1.2.3.4", 33) == "") { return 94; }
  if !ip.ip_in_subnet("192.168.1.5", "192.168.1.0/24") { return 95; }
  if ip.ip_in_subnet("10.0.0.1", "192.168.0.0/16") { return 96; }
  if ip.ip_in_subnet("1.2.3.4", "1.2.3.0") { return 97; }
  if !(ip.ip_expand("1.2.3.4") == "1.2.3.4") { return 98; }
  // ip_expand returns Str (v4 unchanged / padded v6); compare directly.
  if !(ip.ip_expand("::1").len() == 39) { return 99; }
  if !(ip.ip_compress("2001:0db8:0000:0000:0000:0000:0000:0001") == "2001:db8::1") { return 101; }
  if !(ip.ip_compress("::") == "::") { return 102; }
  var octs = ip.ip_octets("1.2.3.4");
  if octs.len() != 4 { return 103; }
  if octs[0] != 1 { return 104; }
  if ip.ip_octets("").len() != 0 { return 105; }

  // ---- url
  match url.url_parse("http://user:pass@example.com:8080/a?b=c#d") {
    Ok(u) => {
      if !(u.scheme == "http") { return 106; }
      if !(u.host == "example.com") { return 107; }
      if u.port != 8080 { return 108; }
      if !(u.path == "/a") { return 109; }
      if !(u.query == "b=c") { return 110; }
      if !(u.fragment == "d") { return 111; }
    },
    Err(_) => { return 112; },
  }
  if url.url_parse("http:///x").is_ok { return 113; }
  if url.url_parse("").is_ok { return 114; }
  match url.url_decode_component("a%20b") {
    Ok(s) => {
      if !(s == "a b") { return 115; }
    },
    Err(_) => { return 116; },
  }
  match url.url_decode_component("a+b") {
    Ok(s) => {
      if !(s == "a+b") { return 117; }
    },
    Err(_) => { return 118; },
  }
  if url.url_decode_component("%2").is_ok { return 119; }
  if url.url_decode_component("%zz").is_ok { return 120; }
  match url.url_decode_component("") {
    Ok(s) => {
      if !(s == "") { return 121; }
    },
    Err(_) => { return 122; },
  }
  match url.url_encode_component("a b") {
    Ok(s) => {
      if !(s == "a%20b") { return 123; }
    },
    Err(_) => { return 124; },
  }
  var qp = url.url_query_parse("a=1&b=2");
  if qp.len() != 2 { return 125; }
  if !(qp[0].0 == "a") { return 126; }
  if url.url_query_parse("").len() != 0 { return 127; }
  if !(url.url_query_build(qp) == "a=1&b=2") { return 128; }
  var empty_pairs = Vec[(Str, Str)].new();
  if !(url.url_query_build(empty_pairs) == "") { return 129; }
  match url.url_normalize("HTTP://Example.COM:80/a/./b/../c") {
    Ok(s) => {
      if !(s == "http://example.com/a/c") { return 130; }
    },
    Err(_) => { return 131; },
  }
  if !url.url_is_absolute("http://x") { return 132; }
  if url.url_is_absolute("/p") { return 133; }
  if url.url_is_absolute("") { return 134; }
  if !url.url_is_absolute(":") { return 135; }
  match url.url_join("http://a/b/c", "../d") {
    Ok(s) => {
      if !(s == "http://a/d") { return 136; }
    },
    Err(_) => { return 137; },
  }
  match url.url_join("http://a", "https://b") {
    Ok(s) => {
      if !(s == "https://b") { return 138; }
    },
    Err(_) => { return 139; },
  }
  // fix-first F2: the "//" reference resolves through normalization per doc
  match url.url_join("http://a", "//Example.COM/x/./y") {
    Ok(s) => {
      if !(s == "http://example.com/x/y") { return 140; }
    },
    Err(_) => { return 141; },
  }
  return 0;
}
