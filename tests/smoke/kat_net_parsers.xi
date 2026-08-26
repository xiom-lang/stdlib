// kat_net_parsers.xi -- URL / percent / query / IPv4 known-answer tests
// RFC 3986 example semantics plus IPv4 special ranges (RFC 1918 / 5735
// classes). Pure parsers -- the highest-value fuzz surface in net.
module kat_net_parsers
use xiom.net.url;
use xiom.net.ip4;
use xiom.io;

fn main() -> Int {
  // ---- url_parse with every component populated ----
  match url.url_parse("https://user:pass@example.com:8080/path/x?q=1&r=2#frag") {
    Ok(p) => {
      if p.scheme != "https" { io.println("url scheme"); return 1; }
      if p.host != "example.com" { io.println("url host"); return 2; }
      if p.port != 8080 { io.println("url port"); return 3; }
      if p.path != "/path/x" { io.println("url path"); return 4; }
      if p.query != "q=1&r=2" { io.println("url query"); return 5; }
      if p.fragment != "frag" { io.println("url frag"); return 6; }
    }
    Err(e) => { io.println("url parse err " + e); return 7; }
  }

  // relative url with no scheme/port
  match url.url_parse("example.com/x") {
    Ok(p) => {
      if p.host != "example.com" { io.println("rel host"); return 8; }
      if p.path != "/x" { io.println("rel path"); return 9; }
    }
    Err(e) => { io.println("rel parse err " + e); return 10; }
  }

  // ---- percent encode/decode ----
  match url.url_decode_component("a%20b%2Fc%3A") {
    Ok(d) => { if d != "a b/c:" { io.println("pct dec"); return 11; } }
    Err(e) => { io.println("pct dec err " + e); return 12; }
  }
  match url.url_encode_component("a b/c:") {
    Ok(enc) => {
      if enc != "a%20b%2Fc%3A" { io.println("pct enc " + enc); return 13; }
    }
    Err(e) => { io.println("pct enc err " + e); return 14; }
  }
  // malformed percent escape rejected
  match url.url_decode_component("a%2") {
    Ok(_) => { io.println("pct bad accepted"); return 15; }
    Err(_) => {}
  }

  // ---- query parse/build ----
  var q = url.url_query_parse("q=1&r=two&flag");
  if q.len() != 3 { io.println("qp len"); return 16; }
  if q[0].0 != "q" || q[0].1 != "1" { io.println("qp q"); return 17; }
  if q[1].0 != "r" || q[1].1 != "two" { io.println("qp r"); return 18; }
  if q[2].0 != "flag" { io.println("qp flag"); return 19; }
  var built = url.url_query_build(q);
  if built != "q=1&r=two&flag=" { io.println("qb " + built); return 20; }

  // ---- IPv4 parse/validate/special ranges ----
  match ip4.ip4_parse("192.168.1.1") {
    Ok(o) => {
      if o.len() != 4 { io.println("ip4 len"); return 21; }
      if o[0] != 192u8 || o[1] != 168u8 || o[2] != 1u8 || o[3] != 1u8 {
        io.println("ip4 octets"); return 22;
      }
    }
    Err(e) => { io.println("ip4 parse err " + e); return 23; }
  }
  if !ip4.ip4_validate("0.0.0.0") { io.println("ip4 v0"); return 24; }
  if ip4.ip4_validate("256.1.1.1") { io.println("ip4 v256"); return 25; }
  if ip4.ip4_validate("1.2.3") { io.println("ip4 v3oct"); return 26; }
  if ip4.ip4_validate("1.2.3.4.5") { io.println("ip4 v5oct"); return 27; }
  if !ip4.ip4_is_private("10.0.0.1") { io.println("ip4 priv10"); return 28; }
  if !ip4.ip4_is_private("192.168.1.1") { io.println("ip4 priv192"); return 29; }
  if ip4.ip4_is_private("8.8.8.8") { io.println("ip4 priv88"); return 30; }
  if !ip4.ip4_is_loopback("127.0.0.1") { io.println("ip4 loop"); return 31; }
  // RFC 6890: the ENTIRE 127.0.0.0/8 block is loopback
  if !ip4.ip4_is_loopback("127.1.2.3") { io.println("ip4 loop8"); return 32; }

  io.println("OK");
  return 0;
}
