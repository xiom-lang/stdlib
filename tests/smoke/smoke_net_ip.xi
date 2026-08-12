// XIOM stdlib smoke test — xiom.net.ip4 + xiom.net.ip6
// IPv4/IPv6 validation, parsing, formatting, and classification.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_ip

use xiom.net.ip4;
use xiom.net.ip6;
use xiom.io;

// v4_roundtrip checks parse then to_str through a by-value helper to
// sidestep the compiler's borrowed match-bound Vec corruption.
fn v4_roundtrip(b: Vec[UInt8]) -> Bool {
  if b.len() != 4 {
    return false;
  }
  if b[0] != 192 || b[1] != 168 || b[2] != 1 || b[3] != 1 {
    return false;
  }
  var fresh: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < 4 {
    fresh.push(b[i]);
    i = i + 1;
  }
  let s = ip4.ip4_to_str(&fresh);
  match s {
    Ok(str) => str == "192.168.1.1";
    Err(_) => false;
  }
}

fn v6_roundtrip(b: Vec[UInt8]) -> Bool {
  if b.len() != 16 {
    return false;
  }
  var fresh: Vec[UInt8] = Vec[UInt8]::new();
  var i = 0;
  while i < 16 {
    fresh.push(b[i]);
    i = i + 1;
  }
  let s = ip6.ip6_to_str(&fresh);
  match s {
    Ok(_) => true;
    Err(_) => false;
  }
}

fn main() -> Int {
  // --- ip4_parse valid + parts ---
  let r1 = ip4.ip4_parse("192.168.1.1");
  match r1 {
    Ok(b) => {
      if !v4_roundtrip(b) {
        io.println("ip4-parse");
        return 1;
      }
    }
    Err(_) => {
      io.println("ip4-parse");
      return 1;
    }
  }

  // --- ip4_parse invalid (octet > 255) ---
  let r2 = ip4.ip4_parse("999.1.1.1");
  if r2.is_ok {
    io.println("ip4-invalid");
    return 2;
  }
  let r3 = ip4.ip4_parse("1.2.3");
  if r3.is_ok {
    io.println("ip4-parts");
    return 3;
  }

  // --- ip4_validate ---
  if ip4.ip4_validate("10.0.0.1") != true {
    io.println("ip4-valid");
    return 4;
  }
  if ip4.ip4_validate("10.0.0.999") != false {
    io.println("ip4-invalid2");
    return 5;
  }

  // --- classification ---
  if ip4.ip4_is_loopback("127.0.0.1") != true {
    io.println("ip4-loopback");
    return 6;
  }
  if ip4.ip4_is_private("192.168.1.1") != true {
    io.println("ip4-private");
    return 7;
  }
  if ip4.ip4_is_private("8.8.8.8") != false {
    io.println("ip4-private2");
    return 8;
  }
  if ip4.ip4_is_multicast("224.0.0.1") != true {
    io.println("ip4-mcast");
    return 9;
  }
  if ip4.ip4_is_unspecified("0.0.0.0") != true {
    io.println("ip4-unspec");
    return 10;
  }

  // --- ip6_parse + round-trip ---
  let r6 = ip6.ip6_parse("2001:db8::1");
  match r6 {
    Ok(b) => {
      if !v6_roundtrip(b) {
        io.println("ip6-parse");
        return 11;
      }
    }
    Err(_) => {
      io.println("ip6-parse");
      return 11;
    }
  }
  let r7 = ip6.ip6_parse("::1");
  match r7 {
    Ok(b) => {
      if b.len() != 16 {
        io.println("ip6-len");
        return 12;
      }
      if b[15] != 1 {
        io.println("ip6-b15");
        return 12;
      }
    }
    Err(_) => {
      io.println("ip6-len");
      return 12;
    }
  }

  // --- ip6 validation ---
  if ip6.ip6_validate("fe80::1") != true {
    io.println("ip6-valid");
    return 13;
  }
  if ip6.ip6_validate("2001:db8:::1") != false {
    io.println("ip6-invalid");
    return 14;
  }

  // --- ip6 classification ---
  if ip6.ip6_is_loopback("::1") != true {
    io.println("ip6-loopback");
    return 15;
  }
  if ip6.ip6_is_unspecified("::") != true {
    io.println("ip6-unspec");
    return 16;
  }
  if ip6.ip6_is_multicast("ff02::1") != true {
    io.println("ip6-mcast");
    return 17;
  }
  if ip6.ip6_is_link_local("fe80::1") != true {
    io.println("ip6-linklocal");
    return 18;
  }

  io.println("OK");
  return 0;
}
