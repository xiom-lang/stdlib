// p_wave57_probe_ir.xi -- context-dependent invalid LLVM IR (alloca dominance)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Open finding 2026-10-02 (compiler v0.61.3 and v0.62.2 dev): this is the
// pre-fix prefix of tools/probes/p_wave57_shapes.xi through the ip4 section
// (uncovered-fn KATs for xiom.net.address/ip4) followed by a match on a
// Str-returning call (xiom.net.ip.ipv6_to_string). It fails at the clang
// stage: "error: invalid LLVM IR input: Instruction does not dominate all
// uses!". The trigger is context-dependent; bisecting the wave-57 probe was
// NON-monotonic (section-boundary prefixes through address+ip4 fail, through
// address only pass), so this file pins the smallest reliable failing shape.
// The wave-57 probe was rewritten to compare the Str result directly (no
// Result-style match). Expected: a checker diagnostic for the ill-typed
// match, otherwise valid IR; never a clang IR error. Compile-only repro.
//
// Original wave-57 probe prefix follows (header comments trimmed).
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
  var parts8 = Vec[UInt16].new();
  var pi = 0;
  while pi < 8 { parts8.push(0); pi = pi + 1; }
  match ip.ipv6_to_string(&parts8) {
    Ok(s) => { if !(s == "x") { return 72; } },
    Err(_) => { return 73; },
  }
  return 0;
}
