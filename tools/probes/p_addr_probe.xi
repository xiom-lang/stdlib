// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_probe
use xiom.net.address;
use xiom.io;
fn main() -> Int {
  var a1 = address.address_parse("example.com:8080");
  match a1 {
    None => { io.println("none"); return 1; }
    Some(a) => {
      if a.host != "example.com" { io.println("host"); return 2; }
      if a.port != 8080 { io.println("port"); return 3; }
      if a.family != "hostname" { io.println("family"); return 4; }
    }
  }
  io.println("addr-OK");
  return 0;
}
