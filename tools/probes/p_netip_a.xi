// p_netip_a.xi -- only the delegated ipv6_parse.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_netip_a
use xiom.net.ip as netip;
use xiom.io;

fn main() -> Int {
  let r = netip.ipv6_parse("2001:db8::1");
  if !r.is_some { io.println("none"); return 1; };
  io.println("A ok");
  io.flush_stdout();
  0
}
