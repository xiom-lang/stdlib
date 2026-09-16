// p_ip_parity.xi -- dedup parity probe: xiom.convert.ip validators/parser vs
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// the canonical xiom.net.ip4 / xiom.net.ip6 implementations.
module p_ip_parity
use xiom.convert.ip as cvt;
use xiom.net.ip4 as net4;
use xiom.net.ip6 as net6;
use xiom.convert;
use xiom.io;

fn b(v: Bool) -> Str {
  if v { return "true"; };
  "false"
}

fn v4case(s: Str) -> Int {
  let a = b(cvt.is_valid_ipv4(s));
  let c = b(net4.ip4_validate(s));
  if a == c {
    io.println("v4 [" + s + "] == " + a);
    return 0;
  };
  io.println("v4 [" + s + "] DIFF cvt=" + a + " net=" + c);
  1;
}

fn v6case(s: Str) -> Int {
  let a = b(cvt.is_valid_ipv6(s));
  let c = b(net6.ip6_validate(s));
  if a == c {
    io.println("v6 [" + s + "] == " + a);
    return 0;
  };
  io.println("v6 [" + s + "] DIFF cvt=" + a + " net=" + c);
  1;
}

fn main() -> Int {
  var bad = 0;
  bad = bad + v4case("1.2.3.4");
  bad = bad + v4case("0.0.0.0");
  bad = bad + v4case("255.255.255.255");
  bad = bad + v4case("256.1.1.1");
  bad = bad + v4case("01.2.3.4");
  bad = bad + v4case("1.2.3");
  bad = bad + v4case("1.2.3.4.5");
  bad = bad + v4case("1.2.3.");
  bad = bad + v4case("");
  bad = bad + v4case("a.b.c.d");
  bad = bad + v4case(" 1.2.3.4");
  bad = bad + v4case("+1.2.3.4");
  bad = bad + v4case("999.999.999.999");

  bad = bad + v6case("::");
  bad = bad + v6case("::1");
  bad = bad + v6case("1::");
  bad = bad + v6case("2001:db8::1");
  bad = bad + v6case("2001:0db8:0000:0000:0000:0000:0000:0001");
  bad = bad + v6case("1::2::3");
  bad = bad + v6case("12345::");
  bad = bad + v6case("1:2:3:4:5:6:7");
  bad = bad + v6case("1:2:3:4:5:6:7:8:9");
  bad = bad + v6case("::ffff:1.2.3.4");
  bad = bad + v6case("1.2.3.4");
  bad = bad + v6case("g::1");
  bad = bad + v6case("2001:DB8::1");
  bad = bad + v6case("fe80::1%eth0");
  bad = bad + v6case("");

  io.println("P_IP_PARITY mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  0
}
