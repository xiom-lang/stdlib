// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_ba
use xiom.net.address;
use xiom.net.ip;
use xiom.io;
fn main() -> Int {
  let a1 = address.address_parse("example.com:8080");
  match a1 {
    None => { return 1; }
    Some(a) => { if a.host != "example.com" { io.println("host"); return 2; } }
  }
  io.println("A-OK");
  return 0;
}
