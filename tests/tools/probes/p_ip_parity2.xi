// p_ip_parity2.xi -- output parity for string_to_ipv4 vs ip4_parse.
module p_ip_parity2
use xiom.convert.ip as cvt;
use xiom.net.ip4 as net4;
use xiom.convert;
use xiom.io;

fn opt_tag(ok: Bool) -> Str {
  if ok { return "Some"; };
  "None"
}

fn cmpv4(s: Str) -> Int {
  var a = cvt.string_to_ipv4(s);
  var c = net4.ip4_parse(s);
  let aok = a.is_some;
  let cok = c.is_ok;
  if aok != cok {
    io.println("shape DIFF [" + s + "] cvt=" + opt_tag(aok) + " net=" + opt_tag(cok));
    return 1;
  };
  if aok {
    let ab = a.value;
    match c {
      Ok(cb) => {
        if ab.len() != cb.len() {
          io.println("len DIFF [" + s + "]");
          return 2;
        };
        var i = 0;
        while i < ab.len() {
          if ab[i] != cb[i] {
            io.println("byte DIFF [" + s + "] at " + convert.int_to_string(i));
            return 3;
          };
          i = i + 1;
        };
      },
      Err(_) => { return 4; }
    };
  };
  0
}

fn main() -> Int {
  var bad = 0;
  bad = bad + cmpv4("1.2.3.4");
  bad = bad + cmpv4("0.0.0.0");
  bad = bad + cmpv4("255.255.255.255");
  bad = bad + cmpv4("127.0.0.1");
  bad = bad + cmpv4("256.1.1.1");
  bad = bad + cmpv4("01.2.3.4");
  bad = bad + cmpv4("1.2.3");
  bad = bad + cmpv4("");
  bad = bad + cmpv4("a.b.c.d");

  io.println("P_IP_PARITY2 mismatches=" + convert.int_to_string(bad));
  io.flush_stdout();
  0
}
