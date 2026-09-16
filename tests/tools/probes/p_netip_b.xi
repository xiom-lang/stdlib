// p_netip_b.xi -- only the delegated ipv6_to_string.
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_netip_b
use xiom.net.ip as netip;
use xiom.io;

fn main() -> Int {
  var parts = Vec[UInt16].new();
  parts.push(0x2001); parts.push(0x0db8); parts.push(0); parts.push(0);
  parts.push(0); parts.push(0); parts.push(0); parts.push(1);
  let s = netip.ipv6_to_string(&parts);
  io.println("B s=" + s);
  io.flush_stdout();
  0
}
