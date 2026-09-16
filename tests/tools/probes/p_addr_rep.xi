module p_addr_rep
use xiom.io;
use xiom.string;
use xiom.convert;

fn idx_of(hay: Str, needle: Str) -> Int {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return 0; }
  if nlen > hlen { return -1; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return i;
    }
    i = i + 1;
  }
  -1
}

fn parse_port(s: Str) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  let len = s.len();
  while i < len {
    let b = s.byte_at(i);
    if b < 48 || b > 57 { return -1; }
    result = result * 10 + (b as Int - 48);
    if result > 65535 { return -1; }
    i = i + 1;
  }
  result
}

fn split_host_port(s: Str) -> (Str, Int) {
  let len = s.len();
  if len == 0 { return ("", 0); }
  if s.byte_at(0) == 91 {
    let close = idx_of(s, "]");
    if close < 0 { return ("", -1); }
    let host = string.str_slice(s, 1, close);
    if close + 1 == len { return (host, 0); }
    if s.byte_at(close + 1) == 58 {
      let pstr = string.str_slice(s, close + 2, len);
      let p = parse_port(pstr);
      if p < 0 { return (host, -1); }
      return (host, p);
    }
    return ("", -1);
  }
  var colons: Int = 0;
  var i: Int = 0;
  while i < len {
    if s.byte_at(i) == 58 { colons = colons + 1; }
    i = i + 1;
  }
  if colons == 1 {
    let c = idx_of(s, ":");
    let host = string.str_slice(s, 0, c);
    let pstr = string.str_slice(s, c + 1, len);
    if host.len() == 0 { return ("", -1); }
    let p = parse_port(pstr);
    if p < 0 { return (host, -1); }
    return (host, p);
  }
  (s, 0)
}

fn main() -> Int {
  var parts = split_host_port("example.com:8080");
  io.println("host=[" + parts.0 + "] port=" + parts.1);
  return 0;
}
