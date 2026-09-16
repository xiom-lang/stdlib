module p_addr_bc
use xiom.net.address;
use xiom.convert;
use xiom.io;
fn main() -> Int {
  let a1 = address.address_parse("example.com:8080");
  match a1 {
    None => { return 1; }
    Some(a) => { if a.host != "example.com" { io.println("host"); return 2; } }
  }
  io.println("C-OK");
  return 0;
}
