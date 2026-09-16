// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_rep2
use xiom.io;
use xiom.string;
use xiom.net.ip;
use xiom.net.address;

type Rec = { family: Str; host: Str; port: Int; }

fn classify(host: Str) -> Str {
  var v4 = ip.ipv4_parse(host);
  if v4.is_some { return "ipv4"; }
  var v6 = ip.ipv6_parse(host);
  if v6.is_some { return "ipv6"; }
  "hostname"
}

fn main() -> Int {
  var host = "example.com";
  var fam = classify(host);
  io.println("after-classify host=[" + host + "] fam=[" + fam + "]");
  var r = Rec{ family: fam; host: host; port: 8080; };
  io.println("rec host=[" + r.host + "] port=" + r.port + " fam=[" + r.family + "]");
  return 0;
}
