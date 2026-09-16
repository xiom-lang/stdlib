// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_addr_dbg2
use xiom.net.address;
use xiom.io;
fn main() -> Int {
  io.println("host=[" + address.address_host("example.com:8080") + "]");
  io.println("port=" + address.address_port("example.com:8080"));
  return 0;
}
