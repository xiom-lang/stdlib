// XIOM stdlib smoke test -- xiom.net.address + xiom.net.ip + xiom.net.header
// Address host:port parsing, IPv4/IPv6 helpers, and HTTP header lists.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_address

use xiom.net.address;
use xiom.net.ip;
use xiom.net.header;
use xiom.io;

fn main() -> Int {
  // --- address: parse host:port ---
  let a1 = address.address_parse("example.com:8080");
  match a1 {
    None => {
      io.println("addr-parse");
      return 1;
    }
    Some(a) => {
      if a.host != "example.com" {
        io.println("addr-host");
        return 2;
      }
      if a.port != 8080 {
        io.println("addr-port");
        return 3;
      }
      if a.family != "hostname" {
        io.println("addr-family");
        return 4;
      }
    }
  }
  let a2 = address.address_parse("[::1]:53");
  match a2 {
    None => {
      io.println("addr-v6");
      return 5;
    }
    Some(a) => {
      if a.host != "::1" {
        io.println("addr-v6-host");
        return 6;
      }
      if a.port != 53 {
        io.println("addr-v6-port");
        return 7;
      }
    }
  }
  if address.address_host("127.0.0.1:80") != "127.0.0.1" {
    io.println("addr-host2");
    return 8;
  }
  if address.address_port("127.0.0.1:80") != 80 {
    io.println("addr-port2");
    return 9;
  }
  if !address.address_is_ipv4("1.2.3.4:80") {
    io.println("addr-v4");
    return 10;
  }
  if !address.address_is_ipv6("[fe80::1]:80") {
    io.println("addr-v62");
    return 11;
  }
  if address.address_is_valid("") {
    io.println("addr-invalid");
    return 12;
  }
  if !address.address_is_valid("example.com:443") {
    io.println("addr-valid");
    return 13;
  }

  // --- ip: ipv4 parse / format ---
  let v4 = ip.ipv4_parse("192.168.1.1");
  match v4 {
    None => {
      io.println("ip-v4-parse");
      return 14;
    }
    Some(b) => {
      if b.len() != 4 {
        io.println("ip-v4-len");
        return 15;
      }
      if b[0] != 192 || b[3] != 1 {
        io.println("ip-v4-octets");
        return 16;
      }
      var fresh: Vec[UInt8] = Vec[UInt8].new();
      var i = 0;
      while i < 4 {
        fresh.push(b[i]);
        i = i + 1;
      }
      if ip.ipv4_to_string(&fresh) != "192.168.1.1" {
        io.println("ip-v4-str");
        return 17;
      }
    }
  }
  if ip.ipv4_parse("999.1.1.1").is_some {
    io.println("ip-v4-invalid");
    return 18;
  }

  // --- ip: ipv6 parse / format ---
  let v6 = ip.ipv6_parse("2001:db8::1");
  match v6 {
    None => {
      io.println("ip-v6-parse");
      return 19;
    }
    Some(p) => {
      if p.len() != 8 {
        io.println("ip-v6-len");
        return 20;
      }
      var g0 = p[0] as Int;
      var g7 = p[7] as Int;
      if g0 != 0x2001 || g7 != 1 {
        io.println("ip-v6-groups");
        return 21;
      }
      var fresh6: Vec[UInt16] = Vec[UInt16].new();
      var k = 0;
      while k < 8 {
        fresh6.push(p[k]);
        k = k + 1;
      }
      let s6 = ip.ipv6_to_string(&fresh6);
      if s6 != "2001:db8:0:0:0:0:0:1" {
        io.println("ip-v6-str=" + s6);
        return 22;
      }
    }
  }

  // --- ip: ip_parse ---
  if !ip.ip_parse("10.0.0.1").is_some {
    io.println("ip-parse-v4");
    return 23;
  }
  if !ip.ip_parse("::1").is_some {
    io.println("ip-parse-v6");
    return 24;
  }
  if ip.ip_parse("not-an-ip").is_some {
    io.println("ip-parse-invalid");
    return 25;
  }

  // --- ip: classification ---
  if !ip.ip_is_loopback("127.0.0.1") || !ip.ip_is_loopback("::1") {
    io.println("ip-loopback");
    return 26;
  }
  if !ip.ip_is_private("10.0.0.1") || !ip.ip_is_private("192.168.1.1") {
    io.println("ip-private");
    return 27;
  }
  if ip.ip_is_private("8.8.8.8") {
    io.println("ip-private2");
    return 28;
  }
  if !ip.ip_is_link_local("169.254.1.1") || !ip.ip_is_link_local("fe80::1") {
    io.println("ip-linklocal");
    return 29;
  }
  if !ip.ip_is_multicast("224.0.0.1") || !ip.ip_is_multicast("ff02::1") {
    io.println("ip-mcast");
    return 30;
  }
  if !ip.ip_is_unspecified("0.0.0.0") || !ip.ip_is_unspecified("::") {
    io.println("ip-unspec");
    return 31;
  }

  // --- ip: masking and subnet ---
  if ip.ip_masked("192.168.1.99", 24) != "192.168.1.0" {
    io.println("ip-mask");
    return 32;
  }
  if ip.ip_masked("192.168.1.99", 16) != "192.168.0.0" {
    io.println("ip-mask2");
    return 33;
  }
  if !ip.ip_in_subnet("192.168.1.55", "192.168.1.0/24") {
    io.println("ip-subnet");
    return 34;
  }
  if ip.ip_in_subnet("192.168.2.55", "192.168.1.0/24") {
    io.println("ip-subnet2");
    return 35;
  }
  if !ip.ip_in_subnet("2001:db8::5", "2001:db8::/32") {
    io.println("ip-subnet6");
    return 36;
  }

  // --- ip: compress / expand / octets ---
  if ip.ip_compress("2001:db8:0:0:0:0:0:1") != "2001:db8::1" {
    io.println("ip-compress");
    return 37;
  }
  if ip.ip_compress("::1") != "::1" {
    io.println("ip-compress2");
    return 38;
  }
  let exp = ip.ip_expand("::1");
  if exp != "0000:0000:0000:0000:0000:0000:0000:0001" {
    io.println("ip-expand");
    return 39;
  }
  let oct = ip.ip_octets("10.0.0.7");
  if oct.len() != 4 {
    io.println("ip-octets-len");
    return 40;
  }
  let o0 = oct[0];
  let o3 = oct[3];
  if o0 != 10 || o3 != 7 {
    io.println("ip-octets");
    return 41;
  }

  // --- header: parse line ---
  let h = header.header_parse_line("Host: example.com");
  match h {
    None => {
      io.println("hdr-parse");
      return 42;
    }
    Some(p) => {
      if p.0 != "Host" {
        io.println("hdr-name");
        return 43;
      }
      if p.1 != "example.com" {
        io.println("hdr-value");
        return 44;
      }
    }
  }
  if header.header_parse_line("no-colon").is_some {
    io.println("hdr-invalid");
    return 45;
  }

  // --- header: list operations ---
  var headers: Vec[(Str, Str)] = Vec[(Str, Str)].new();
  headers.push(("Host", "example.com"));
  headers.push(("Content-Type", "text/plain"));
  {
    let got = header.header_get(&headers, "host");
    match got {
      None => {
        io.println("hdr-get");
        return 46;
      }
      Some(v) => {
        if v != "example.com" {
          io.println("hdr-get-value");
          return 47;
        }
      }
    }
    if !header.header_contains(&headers, "content-type") {
      io.println("hdr-contains");
      return 48;
    }
  }
  header.header_set(&mut headers, "Host", "example.org");
  {
    let got2 = header.header_get(&headers, "HOST");
    match got2 {
      None => {
        io.println("hdr-set");
        return 49;
      }
      Some(v) => {
        if v != "example.org" {
          io.println("hdr-set-value");
          return 50;
        }
      }
    }
  }
  {
    if !header.header_remove(&mut headers, "host") {
      io.println("hdr-remove");
      return 51;
    }
    if header.header_contains(&headers, "Host") {
      io.println("hdr-remove2");
      return 52;
    }
  }
  let serialized = header.header_serialize(&headers);
  if serialized != "Content-Type: text/plain\r\n" {
    io.println("hdr-serialize");
    return 53;
  }

  io.println("OK");
  return 0;
}
