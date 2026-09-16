// p_opt_tmp_lifetime.xi -- does a Vec payload read from a temporary Option
// survive an intervening allocation?
module p_opt_tmp_lifetime
use xiom.net.dns;
use xiom.net.ip4 as net4;
use xiom.convert;
use xiom.io;

fn main() -> Int {
  let ab = dns.dns_parse_ipv4("1.2.3.4").value;
  // Intervening allocations with DIFFERENT content.
  var j1 = net4.ip4_parse("255.255.255.255");
  var j2 = net4.ip4_parse("9.9.9.9");
  var j3 = Vec[UInt8].new();
  j3.push(200);
  io.println("after allocs: len=" + convert.int_to_string(ab.len()));
  var i = 0;
  while i < ab.len() {
    io.println("ab[" + convert.int_to_string(i) + "]=" + convert.int_to_string(ab[i] as Int));
    i = i + 1;
  };
  // Control: same read without intervening allocation.
  let cd = dns.dns_parse_ipv4("1.2.3.4").value;
  io.println("control: len=" + convert.int_to_string(cd.len()));
  i = 0;
  while i < cd.len() {
    io.println("cd[" + convert.int_to_string(i) + "]=" + convert.int_to_string(cd[i] as Int));
    i = i + 1;
  };
  io.flush_stdout();
  0
}
