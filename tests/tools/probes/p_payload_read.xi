// p_payload_read.xi -- R24 minimal repro: `.value` payload reads.
// A) named Option[Vec] local  -> correct
// B) temporary call-result Option[Vec].value -> CORRUPT (data bytes zero)
// C) temporary Option[Int].value -> correct
// D) named Option[Int] local -> correct
// E) match-bound Vec payload -> correct
// Workaround: bind the Option to a named local first, or use match.
module p_payload_read
use xiom.net.dns;
use xiom.net.ip4 as net4;
use xiom.char;
use xiom.convert;
use xiom.io;

fn main() -> Int {
  // A) named local, Vec payload
  var oa = dns.dns_parse_ipv4("1.2.3.4");
  let va = oa.value;
  io.println("A named-len=" + convert.int_to_string(va.len()) + " b0=" + convert.int_to_string(va[0] as Int));

  // B) temporary call result, Vec payload
  let vb = dns.dns_parse_ipv4("1.2.3.4").value;
  io.println("B tmp-len=" + convert.int_to_string(vb.len()) + " b0=" + convert.int_to_string(vb[0] as Int));

  // C) temporary call result, Int payload (char.to_digit)
  let vc = char.to_digit('7', 10).value;
  io.println("C tmp-int=" + convert.int_to_string(vc));

  // D) named local, Int payload
  var od = char.to_digit('8', 10);
  let vd = od.value;
  io.println("D named-int=" + convert.int_to_string(vd));

  // E) match-bound payload (known-good control)
  match dns.dns_parse_ipv4("5.6.7.8") {
    Some(ve) => { io.println("E match-len=" + convert.int_to_string(ve.len()) + " b0=" + convert.int_to_string(ve[0] as Int)); },
    None => { io.println("E None"); }
  };

  io.flush_stdout();
  0
}
