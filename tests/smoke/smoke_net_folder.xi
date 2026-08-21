// XIOM stdlib smoke test -- xiom.net.url, xiom.net.dns, xiom.net.proto
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_net_folder
use xiom.net.url;
use xiom.net.dns;
use xiom.net.proto;
use xiom.io;
use xiom.string;

fn contains(hay: Str, needle: Str) -> Bool {
  let hlen = hay.len();
  let nlen = needle.len();
  if nlen == 0 { return true; }
  if nlen > hlen { return false; }
  var i = 0;
  while i <= hlen - nlen {
    if string.str_slice(hay, i, i + nlen) == needle {
      return true;
    }
    i = i + 1;
  }
  false
}

fn starts_with(s: Str, prefix: Str) -> Bool {
  let plen = prefix.len();
  if plen > s.len() { return false; }
  string.str_slice(s, 0, plen) == prefix
}

fn main() -> Int {
  // --- url_parse ---
  let up = url.url_parse("https://user:pass@example.com:8080/a/b?x=1&y=2#frag");
  match up {
    Ok(p) => {
      if p.scheme != "https" { return 1; }
      if p.host != "example.com" { return 1; }
      if p.port != 8080 { return 1; }
      if p.path != "/a/b" { return 1; }
      if p.query != "x=1&y=2" { return 1; }
      if p.fragment != "frag" { return 1; }
    }
    Err(_) => { return 1; }
  }

  // --- url encode/decode ---
  let enc = url.url_encode_component("a b&c=d");
  match enc {
    Ok(s) => { if s != "a%20b%26c%3Dd" { io.println("enc-bad: [" + s + "]"); return 2; } }
    Err(e) => { io.println("enc-err: [" + e + "]"); return 2; }
  }
  let dec = url.url_decode_component("a%20b%26c%3Dd");
  match dec {
    Ok(s) => { if s != "a b&c=d" { io.println("dec-bad: [" + s + "]"); return 2; } }
    Err(e) => { io.println("dec-err: [" + e + "]"); return 2; }
  }

  // --- url_query_parse ---
  let pairs = url.url_query_parse("a=1&b=hello+world");
  if pairs.len() != 2 { return 3; }
  let (k0, v0) = pairs[0];
  if k0 != "a" { return 3; }
  if v0 != "1" { return 3; }
  let (k1, v1) = pairs[1];
  if k1 != "b" { return 3; }
  if v1 != "hello world" { return 3; }

  // --- url_query_build round-trip ---
  var build_input: Vec[(Str, Str)] = Vec[(Str, Str)]::new();
  build_input.push(("a", "1"));
  build_input.push(("b", "hello world"));
  let built = url.url_query_build(build_input);
  if built != "a=1&b=hello%20world" { return 4; }
  let reparsed = url.url_query_parse(built);
  if reparsed.len() != 2 { return 4; }
  let (r1k, r1v) = reparsed[1];
  if r1k != "b" { return 4; }
  if r1v != "hello world" { return 4; }

  // --- url_normalize ---
  let norm = url.url_normalize("HTTP://EXAMPLE.com:80/a/./b/../c");
  match norm {
    Ok(s) => { if s != "http://example.com/a/c" { return 5; } }
    Err(_) => { return 5; }
  }

  // --- url_join ---
  let joined = url.url_join("http://a.com/x/y", "../z");
  match joined {
    Ok(s) => { if s != "http://a.com/z" { return 6; } }
    Err(_) => { return 6; }
  }

  // --- url_is_absolute ---
  if url.url_is_absolute("https://x.com/a") != true { return 7; }
  if url.url_is_absolute("/a/b") != false { return 7; }

  // --- dns_parse_ipv4 + round-trip ---
  let v4 = dns.dns_parse_ipv4("192.168.1.1");
  match v4 {
    Some(bytes) => {
      if bytes.len() != 4 { return 8; }
      if bytes[0] != 192 { return 8; }
      if bytes[1] != 168 { return 8; }
      if bytes[2] != 1 { return 8; }
      if bytes[3] != 1 { return 8; }
      let v4s = dns.dns_ipv4_to_str(&bytes);
      match v4s {
        Some(s) => { if s != "192.168.1.1" { return 8; } }
        None => { return 8; }
      }
    }
    None => { return 8; }
  }

  // --- dns_parse_ipv6 ---
  let v6 = dns.dns_parse_ipv6("::1");
  match v6 {
    Some(b) => {
      if b.len() != 16 { return 9; }
      if b[15] != 1 { return 9; }
    }
    None => { return 9; }
  }
  let v6b = dns.dns_parse_ipv6("2001:db8::1");
  match v6b {
    Some(b) => { if b.len() != 16 { return 9; } }
    None => { return 9; }
  }

  // --- dns_is_valid_hostname ---
  if dns.dns_is_valid_hostname("example.com") != true { return 10; }
  if dns.dns_is_valid_hostname("-bad.com") != false { return 10; }

  // --- dns_reverse_ipv4 ---
  var rev_in: Vec[UInt8] = Vec[UInt8]::new();
  rev_in.push(192);
  rev_in.push(168);
  rev_in.push(1);
  rev_in.push(1);
  let rev = dns.dns_reverse_ipv4(&rev_in);
  match rev {
    Some(s) => { if s != "1.1.168.192.in-addr.arpa" { return 11; } }
    None => { return 11; }
  }

  // --- dns_parse_record_line ---
  let rec = dns.dns_parse_record_line("example.com. 3600 IN A 93.184.216.34");
  match rec {
    Some(r) => {
      if r.0 != "example.com." { return 12; }
      if r.1 != "A" { return 12; }
      if r.2 != "93.184.216.34" { return 12; }
    }
    None => { return 12; }
  }

  // --- dns_well_known_port ---
  let wp = dns.dns_well_known_port("https");
  match wp {
    Some(p) => { if p != 443 { return 13; } }
    None => { return 13; }
  }

  // --- jsonrpc ---
  let req = proto.jsonrpc_request(1, "sum", "[1,2]");
  if contains(req, "\"jsonrpc\":\"2.0\"") != true { return 14; }
  if contains(req, "\"method\":\"sum\"") != true { return 14; }

  // --- sse ---
  if proto.sse_format_data("hi") != "data: hi\n\n" { return 15; }

  // --- http headers ---
  let hdrs = proto.http_header_parse("Content-Type: text/plain\nX-A: 1\n");
  let ct = proto.http_header_get(hdrs, "content-type");
  match ct {
    Some(s) => { if s != "text/plain" { return 16; } }
    None => { return 16; }
  }

  // --- basic auth ---
  let auth = proto.basic_auth_header("user", "pass");
  if starts_with(auth, "Basic ") != true { return 17; }

  // --- status text ---
  if proto.http_status_text(404) != "Not Found" { return 18; }

  return 0;
}
