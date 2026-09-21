// p_netip_parity.xi -- parity: net.ip v6 legs + net.net.is_valid_ipv4 vs
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// the canonical net.ip4/net.ip6. Uses named-local binding (R25).
module p_netip_parity
use xiom.net.ip as netip;
use xiom.net.ip4 as net4;
use xiom.net.ip6 as net6;
use xiom.net.net;
use xiom.convert;
use xiom.io;

fn groups_to_bytes(parts: &Vec[UInt16]) -> Vec[UInt8] {
  var b = Vec[UInt8].new();
  var i = 0;
  while i < parts.len() {
    let g = parts[i] as Int;
    b.push(((g >> 8) & 0xFF) as UInt8);
    b.push((g & 0xFF) as UInt8);
    i = i + 1;
  };
  b
}

fn bytes_to_groups(b: &Vec[UInt8]) -> Vec[UInt16] {
  var g = Vec[UInt16].new();
  var i = 0;
  while i + 1 < b.len() {
    let hi = b[i] as Int;
    let lo = b[i + 1] as Int;
    g.push(((hi << 8) | lo) as UInt16);
    i = i + 2;
  };
  g
}

fn cmp_v6(s: Str) -> Int {
  let a = netip.ipv6_parse(s);
  let c = net6.ip6_parse(s);
  if a.is_some != c.is_ok {
    io.println("netip v6 shape DIFF [" + s + "]");
    return 1;
  };
  if a.is_some {
    let ag = a.value;
    match c {
      Ok(cb) => {
        let cg = bytes_to_groups(&cb);
        if ag.len() != cg.len() { io.println("netip v6 len DIFF [" + s + "]"); return 2; };
        var i = 0;
        while i < ag.len() {
          if ag[i] != cg[i] { io.println("netip v6 group DIFF [" + s + "]"); return 3; };
          i = i + 1;
        };
      },
      Err(_) => { return 4; }
    };
  };
  0
}

fn btag(v: Bool) -> Str {
  if v { return "true"; };
  "false"
}

fn cmp_v4valid(s: Str) -> Int {
  let a = net.is_valid_ipv4(s);
  let c = net4.ip4_validate(s);
  if a != c {
    io.println("net.net v4 DIFF [" + s + "] net=" + btag(a) + " ip4=" + btag(c));
    return 1;
  };
  0
}

fn main() -> Int {
  var bad = 0;
  bad = bad + cmp_v6("::");
  bad = bad + cmp_v6("::1");
  bad = bad + cmp_v6("1::");
  bad = bad + cmp_v6("2001:db8::1");
  bad = bad + cmp_v6("2001:0db8:0000:0000:0000:0000:0000:0001");
  bad = bad + cmp_v6("1::2::3");
  bad = bad + cmp_v6("12345::");
  bad = bad + cmp_v6("1:2:3:4:5:6:7");
  bad = bad + cmp_v6("1:2:3:4:5:6:7:8:9");
  bad = bad + cmp_v6("::ffff:1.2.3.4");
  bad = bad + cmp_v6("g::1");
  bad = bad + cmp_v6("");

  bad = bad + cmp_v4valid("1.2.3.4");
  bad = bad + cmp_v4valid("0.0.0.0");
  bad = bad + cmp_v4valid("255.255.255.255");
  bad = bad + cmp_v4valid("256.1.1.1");
  bad = bad + cmp_v4valid("01.2.3.4");
  bad = bad + cmp_v4valid("1.2.3");
  bad = bad + cmp_v4valid("1.2.3.4.5");
  bad = bad + cmp_v4valid("");
  bad = bad + cmp_v4valid("a.b.c.d");

  // ipv6_to_string parity vs canonical formatting through bytes.
  var parts = Vec[UInt16].new();
  parts.push(0x2001); parts.push(0x0db8); parts.push(0); parts.push(0);
  parts.push(0); parts.push(0); parts.push(0); parts.push(1);
  let asv = netip.ipv6_to_string(&parts);
  match net6.ip6_to_str(&groups_to_bytes(&parts)) {
    Ok(cs) => {
      if asv != cs { io.println("netip v6str DIFF netip=" + asv + " ip6=" + cs); bad = bad + 1; };
    },
    Err(_) => { io.println("netip v6str canonical Err"); bad = bad + 1; }
  };
  var short = Vec[UInt16].new();
  short.push(1);
  if netip.ipv6_to_string(&short) != "" { io.println("netip v6str short"); bad = bad + 1; };

  var parts2 = Vec[UInt16].new();
  parts2.push(0); parts2.push(1); parts2.push(0xFFFF); parts2.push(0x00FF);
  parts2.push(0x000F); parts2.push(0x0100); parts2.push(0xABCD); parts2.push(0x1234);
  let asv2 = netip.ipv6_to_string(&parts2);
  match net6.ip6_to_str(&groups_to_bytes(&parts2)) {
    Ok(cs) => {
      if asv2 != cs { io.println("netip v6str2 DIFF netip=" + asv2 + " ip6=" + cs); bad = bad + 1; };
    },
    Err(_) => { io.println("netip v6str2 canonical Err"); bad = bad + 1; }
  };

  io.println("P_NETIP_PARITY mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  0
}
