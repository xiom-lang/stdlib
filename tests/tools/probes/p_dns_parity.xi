// p_dns_parity.xi -- dedup parity: xiom.net.dns ip helpers vs canonical
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// xiom.net.ip4 / xiom.net.ip6.
module p_dns_parity
use xiom.net.dns;
use xiom.net.ip4 as net4;
use xiom.net.ip6 as net6;
use xiom.convert;
use xiom.io;

fn opt4_tag(o: Option[Vec[UInt8]]) -> Str {
  if o.is_some { return "Some:" + convert.int_to_string(o.value.len()); };
  "None"
}

fn res4_tag(r: Result[Vec[UInt8], Str]) -> Str {
  match r {
    Ok(b) => { return "Ok:" + convert.int_to_string(b.len()); },
    Err(_) => { return "Err"; },
  }
}

fn cmp_v4(s: Str) -> Int {
  let a = dns.dns_parse_ipv4(s);
  let c = net4.ip4_parse(s);
  let aok = a.is_some;
  let cok = c.is_ok;
  if aok != cok {
    io.println("dns v4 shape DIFF [" + s + "] dns=" + opt4_tag(a) + " net=" + res4_tag(c));
    return 1;
  };
  if aok {
    let ab = a.value;
    match c {
      Ok(cb) => {
        var i = 0;
        while i < ab.len() {
          if ab[i] != cb[i] { io.println("dns v4 byte DIFF [" + s + "]"); return 2; };
          i = i + 1;
        };
      },
      Err(_) => { return 3; }
    };
  };
  0
}

fn tag(ok: Bool) -> Str {
  if ok { return "Some"; };
  "None"
}

fn cmp_v6(s: Str) -> Int {
  let a = dns.dns_parse_ipv6(s);
  let c = net6.ip6_parse(s);
  let aok = a.is_some;
  let cok = c.is_ok;
  if aok != cok {
    io.println("dns v6 shape DIFF [" + s + "] dns=" + tag(aok));
    return 1;
  };
  if aok {
    let ab = a.value;
    match c {
      Ok(cb) => {
        if ab.len() != cb.len() { io.println("dns v6 len DIFF [" + s + "]"); return 2; };
        var i = 0;
        while i < ab.len() {
          if ab[i] != cb[i] { io.println("dns v6 byte DIFF [" + s + "]"); return 3; };
          i = i + 1;
        };
      },
      Err(_) => { return 4; }
    };
  };
  0
}

fn cmp_v4str(n: Int) -> Int {
  var b = Vec[UInt8].new();
  var i = 0;
  while i < n { b.push((i * 17 + 3) as UInt8); i = i + 1; };
  let a = dns.dns_ipv4_to_str(&b);
  let c = net4.ip4_to_str(&b);
  if a.is_some != c.is_ok {
    io.println("dns v4str shape DIFF n=" + convert.int_to_string(n));
    return 1;
  };
  if a.is_some {
    let asv = a.value;
    match c {
      Ok(cs) => { if asv != cs { io.println("dns v4str DIFF n=" + convert.int_to_string(n) + " dns=" + asv + " net=" + cs); return 2; }; },
      Err(_) => { return 3; }
    };
  };
  0
}

fn cmp_v6str(n: Int) -> Int {
  var b = Vec[UInt8].new();
  var i = 0;
  while i < n { b.push((i * 13 + 5) as UInt8); i = i + 1; };
  let a = dns.dns_ipv6_to_str(&b);
  let c = net6.ip6_to_str(&b);
  if a.is_some != c.is_ok {
    io.println("dns v6str shape DIFF n=" + convert.int_to_string(n));
    return 1;
  };
  if a.is_some {
    let asv = a.value;
    match c {
      Ok(cs) => { if asv != cs { io.println("dns v6str DIFF n=" + convert.int_to_string(n) + " dns=" + asv + " net=" + cs); return 2; }; },
      Err(_) => { return 3; }
    };
  };
  0
}

fn main() -> Int {
  var bad = 0;
  bad = bad + cmp_v4str(0);
  bad = bad + cmp_v4str(3);
  bad = bad + cmp_v4str(4);
  bad = bad + cmp_v4str(5);
  bad = bad + cmp_v6str(0);
  bad = bad + cmp_v6str(15);
  bad = bad + cmp_v6str(16);
  bad = bad + cmp_v6str(17);
  bad = bad + cmp_v4("1.2.3.4");
  bad = bad + cmp_v4("0.0.0.0");
  bad = bad + cmp_v4("255.255.255.255");
  bad = bad + cmp_v4("256.1.1.1");
  bad = bad + cmp_v4("01.2.3.4");
  bad = bad + cmp_v4("1.2.3");
  bad = bad + cmp_v4("1.2.3.4.5");
  bad = bad + cmp_v4("");
  bad = bad + cmp_v4("a.b.c.d");

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

  io.println("P_DNS_PARITY mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  0
}
