// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_dbg
use xiom.net.address;
use xiom.io;
fn main() -> Int {
  var a1 = address.address_parse("example.com:8080");
  match a1 {
    None => { io.println("none"); return 1; }
    Some(a) => {
      io.println("host=[" + a.host + "] port=" + a.port + " family=[" + a.family + "]");
      return 0;
    }
  }
}
