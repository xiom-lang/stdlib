// p_dns_debug.xi -- print dns vs net4 octets for one valid address.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_dns_debug
use xiom.net.dns;
use xiom.net.ip4 as net4;
use xiom.net.ip6 as net6;
use xiom.convert;
use xiom.io;

fn d(s: Str) -> Str {
  "[" + s + "]"
}

fn main() -> Int {
  let o = dns.dns_parse_ipv4("1.2.3.4");
  match o {
    Some(b) => {
      io.println("dns len=" + convert.int_to_string(b.len()));
      var i = 0;
      while i < b.len() {
        io.println("dns b[" + convert.int_to_string(i) + "]=" + convert.int_to_string(b[i] as Int));
        i = i + 1;
      };
    },
    None => { io.println("dns None"); }
  };
  match net4.ip4_parse("1.2.3.4") {
    Ok(b) => {
      io.println("net len=" + convert.int_to_string(b.len()));
      var i = 0;
      while i < b.len() {
        io.println("net b[" + convert.int_to_string(i) + "]=" + convert.int_to_string(b[i] as Int));
        i = i + 1;
      };
    },
    Err(e) => { io.println("net Err " + e); }
  };
  io.flush_stdout();
  0
}
