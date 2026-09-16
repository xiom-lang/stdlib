// p_netip_min.xi -- minimal compile check for the delegated v6 legs.
module p_netip_min
use xiom.net.ip as netip;
use xiom.net.ip6 as net6;
use xiom.io;

fn main() -> Int {
  let r = netip.ipv6_parse("2001:db8::1");
  if !r.is_some { io.println("parse none"); return 1; };
  let g = r.value;
  if g.len() != 8 { io.println("len"); return 2; };
  var parts = Vec[UInt16].new();
  parts.push(0x2001); parts.push(0x0db8); parts.push(0); parts.push(0);
  parts.push(0); parts.push(0); parts.push(0); parts.push(1);
  let s = netip.ipv6_to_string(&parts);
  io.println("s=" + s);
  match net6.ip6_to_str(&Vec[UInt8].new()) {
    Ok(_) => { io.println("odd ok"); },
    Err(_) => { io.println("expected err"); }
  };
  io.flush_stdout();
  0
}
