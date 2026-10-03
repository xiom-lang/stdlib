// p_wave63_shapes.xi -- wave 63 shape validation: xiom.net batch 6 + hash family
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-63 clauses on xiom.net (15), xiom.net.server (6),
// xiom.net.jwt (9) and the hash family (adler/checksum/crc/fnv/jenkins/
// murmur/superfast, 22). No live socket or DNS I/O: network entry points use
// early-error paths only (empty/malformed URLs, port guards, synthetic -1
// handles); tcp_connect_str and dns_lookup stay compile-checked only.
// 123 checks; returns 0 when every case holds.

module p_wave63_shapes

use xiom.net;
use xiom.net.TcpStream;
use xiom.net.UdpSocket;
use xiom.net.server;
use xiom.net.jwt;
use xiom.hash.adler;
use xiom.hash.checksum;
use xiom.hash.crc;
use xiom.hash.fnv;
use xiom.hash.jenkins;
use xiom.hash.murmur;
use xiom.hash.superfast;
use xiom.io;
use xiom.string;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn main() -> Int {
  var empty = _bytes("");
  var a = _bytes("a");
  var ab = _bytes("ab");
  var hello = _bytes("hello");
  var world = _bytes("world");
  var hello_world = _bytes("helloworld");
  var nums = _bytes("123456789");

  // ---- net.xi: URL parsing (pure)
  if net.parse_url("").is_ok { return 1; }
  match net.parse_url("http://example.com:8080/p?q=1#f") {
    Ok(p) => {
      if !(p.scheme == "http") { return 2; }
      if !(p.host == "example.com") { return 3; }
      if p.port != 8080 { return 4; }
      if !(p.path == "/p") { return 5; }
      if !(p.query == "q=1") { return 6; }
      if !(p.fragment == "f") { return 7; }
    },
    Err(_) => { return 8; },
  }
  match net.parse_url("https://example.com") {
    Ok(p2) => {
      if !(p2.path == "/") { return 9; }
      if !(p2.scheme == "https") { return 10; }
    },
    Err(_) => { return 11; },
  }
  if net.url_parse_scheme("").is_some { return 12; }
  if net.url_parse_host("").is_some { return 13; }
  if net.url_parse_path("").is_some { return 14; }
  if net.url_parse_port("").is_some { return 15; }
  match net.url_parse_scheme("https://example.com/x") {
    Some(s) => { if !(s == "https") { return 16; } },
    None => { return 17; },
  }
  match net.url_parse_host("https://example.com/x") {
    Some(h) => { if !(h == "example.com") { return 18; } },
    None => { return 19; },
  }
  match net.url_parse_path("https://example.com/x") {
    Some(pp) => { if !(pp == "/x") { return 20; } },
    None => { return 21; },
  }
  match net.url_parse_port("https://example.com:8443/x") {
    Some(po) => { if po != 8443 { return 22; } },
    None => { return 23; },
  }
  if net.url_parse_port("https://example.com/x").is_some { return 24; }

  // ---- net.xi: early-error network paths (no I/O)
  if !net.http_post("", "x").is_err { return 25; }
  if !net.http_post("http://", "x").is_err { return 26; }
  if !net.http_post_str("", "x").is_err { return 27; }
  if !net.http_get_str("http://").is_err { return 28; }
  if net.http_status("http://").is_some { return 29; }

  // ---- net.xi: validation + handles
  if net.is_valid_ipv4("") { return 30; }
  if !net.is_valid_ipv4("192.168.1.1") { return 31; }
  if net.is_valid_ipv4("999.1.1.1") { return 32; }
  if !net.udp_bind("127.0.0.1", 0).is_err { return 33; }
  if !net.udp_bind("127.0.0.1", 70000).is_err { return 34; }
  let ts = TcpStream{ fd: -1; };
  if !ts.close().is_ok { return 35; }
  let us = UdpSocket{ fd: -1; };
  if !us.close().is_ok { return 36; }

  // ---- server (pure)
  if server.server_default_port() != 80 { return 37; }
  if server.server_parse_request_line("").is_some { return 38; }
  if server.server_parse_request_line("GET").is_some { return 39; }
  if server.server_parse_request_line("GET ").is_some { return 40; }
  if server.server_parse_request_line("GET  HTTP/1.1").is_some { return 41; }
  match server.server_parse_request_line("GET /path HTTP/1.1") {
    Some(t) => {
      if !(t.0 == "GET") { return 42; }
      if !(t.1 == "/path") { return 43; }
      if !(t.2 == "HTTP/1.1") { return 44; }
    },
    None => { return 45; },
  }
  if !(server.server_status_text(200) == "OK") { return 46; }
  if !(server.server_status_text(404) == "Not Found") { return 47; }
  if !(server.server_status_text(500) == "Internal Server Error") { return 48; }
  if !(server.server_status_text(599) == "Unknown") { return 49; }
  if !(server.server_build_status_line(200) == "HTTP/1.1 200 OK") { return 50; }
  if !(server.server_build_status_line(404) == "HTTP/1.1 404 Not Found") { return 51; }
  let exp_resp = server.server_build_status_line(200) + "\r\n" + "Content-Type: text/plain\r\n" + "Content-Length: 5\r\n" + "Connection: close\r\n" + "\r\n" + "hello";
  if !(server.server_build_response(200, "hello") == exp_resp) { return 52; }
  let exp_hdrs = server.server_build_status_line(200) + "\r\n" + "X-A: 1\r\n" + "Content-Length: 2\r\n" + "\r\n" + "hi";
  var hdrs = Vec[(Str, Str)].new();
  hdrs.push(("X-A", "1"));
  if !(server.server_build_response_headers(200, &hdrs, "hi") == exp_hdrs) { return 53; }

  // ---- jwt (pure)
  let hb = jwt.jwt_base64url_encode(&hello);
  if !(hb == "aGVsbG8") { return 54; }
  if !(jwt.jwt_base64url_encode(&empty) == "") { return 55; }
  match jwt.jwt_base64url_decode("aGVsbG8") {
    Ok(b) => { if b.len() != 5 { return 56; } },
    Err(_) => { return 57; },
  }
  match jwt.jwt_base64url_decode("") {
    Ok(b0) => { if b0.len() != 0 { return 58; } },
    Err(_) => { return 59; },
  }
  if jwt.jwt_base64url_decode("!!!").is_ok { return 60; }
  if !jwt.jwt_alg_supported("HS256") { return 61; }
  if !jwt.jwt_alg_supported("none") { return 62; }
  if jwt.jwt_alg_supported("RS256") { return 63; }
  if jwt.jwt_alg_supported("") { return 64; }
  if !jwt.jwt_encode("{}", "{}", "k", "RS256").is_err { return 65; }
  if !jwt.jwt_encode("{}", "{}", "k", "none").is_ok { return 66; }
  if !jwt.jwt_sign_b64("a", "b", "k", "RS256").is_err { return 67; }
  if !jwt.jwt_sign_b64("a", "b", "", "none").is_ok { return 68; }
  if jwt.jwt_decode("").is_ok { return 69; }
  if jwt.jwt_decode("a.b").is_ok { return 70; }
  if jwt.jwt_decode("a..c").is_ok { return 71; }
  if !jwt.jwt_decode("a.b.").is_ok { return 72; }
  if !jwt.jwt_decode("a.b.c").is_ok { return 73; }
  let header = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
  let payload = "{\"sub\":\"123\",\"exp\":1000}";
  match jwt.jwt_encode(header, payload, "secret", "HS256") {
    Ok(tok) => {
      if !jwt.jwt_verify(tok, "secret") { return 74; }
      if jwt.jwt_verify(tok, "wrong") { return 75; }
      if !jwt.jwt_expired(tok, 2000) { return 76; }
      if jwt.jwt_expired(tok, 500) { return 77; }
      match jwt.jwt_claims(tok) {
        Ok(c) => { if !(c == payload) { return 78; } },
        Err(_) => { return 79; },
      }
    },
    Err(_) => { return 80; },
  }
  if jwt.jwt_verify("", "") { return 81; }
  if jwt.jwt_verify("a.b.c", "") { return 82; }
  if jwt.jwt_expired("a.b", 1) { return 83; }
  if jwt.jwt_claims("a.b").is_ok { return 84; }

  // ---- hash: adler
  if adler.adler32(&empty) != 1 as UInt32 { return 85; }
  if adler.adler32_str("Wikipedia") != 0x11E60398 as UInt32 { return 86; }
  var wiki = _bytes("Wikipedia");
  if adler.adler32(&wiki) != 0x11E60398 as UInt32 { return 87; }
  let combo1 = adler.adler32(&hello);
  let combo2 = adler.adler32(&world);
  let combo3 = adler.adler32_combine(combo1, combo2, 5);
  let combo4 = adler.adler32(&hello_world);
  if combo3 != combo4 { return 88; }
  // Inline unsigned call compares misread high-bit values (see
  // known_failures/p_uint32_high_bit_compare.xi); bind first.
  let combo_neg = adler.adler32_combine(combo1, combo2, 0 - 1);
  if combo_neg != 0xFFFFFFFF as UInt32 { return 89; }

  // ---- hash: checksum
  if checksum.checksum_bsd(&empty) != 0 as UInt32 { return 90; }
  if checksum.checksum_sysv(&empty) != 0 as UInt32 { return 91; }
  if checksum.checksum_internet(&empty) != 0xFFFF as UInt32 { return 92; }
  if checksum.checksum_fletcher16(&empty) != 0 as UInt16 { return 93; }
  if checksum.checksum_bsd(&a) != 0x61 as UInt32 { return 94; }
  if checksum.checksum_sysv(&a) != 0x8030 as UInt32 { return 95; }
  if checksum.checksum_internet(&ab) != 0x9E9D as UInt32 { return 96; }
  var abcde = _bytes("abcde");
  let f16 = checksum.checksum_fletcher16(&abcde);
  if f16 != 0xC8F0 as UInt16 { return 97; }

  // ---- hash: crc (bind inline unsigned call compares; see return 89 note)
  let crc64e0 = crc.crc64_ecma(&empty);
  if crc64e0 != 0 as UInt64 { return 98; }
  let crc64e1 = crc.crc64_ecma(&nums);
  if crc64e1 != 0x995DC9BBDF1939FA as UInt64 { return 99; }
  let crc64w0 = crc.crc64_we(&empty);
  if crc64w0 != 0 as UInt64 { return 100; }
  let crc64w1 = crc.crc64_we(&nums);
  if crc64w1 != 0x62EC59E3F1A4F00A as UInt64 { return 101; }
  let crc32c0 = crc.crc32c(&empty);
  if crc32c0 != 0 as UInt32 { return 102; }
  let crc32c1 = crc.crc32c(&nums);
  if crc32c1 != 0xE3069283 as UInt32 { return 103; }
  let crc16e = crc.crc16_ccitt(&empty);
  if crc16e != 0xFFFF as UInt32 { return 104; }
  let crc16n = crc.crc16_ccitt(&nums);
  if crc16n != 0x29B1 as UInt32 { return 105; }
  let crc_adler0 = crc.adler32(&empty);
  if crc_adler0 != 1 as UInt32 { return 106; }

  // ---- hash: fnv
  let f64e = fnv.fnv1a64(&empty);
  if f64e != 0xCBF29CE484222325 as UInt64 { return 107; }
  let f64a = fnv.fnv1a64(&a);
  if f64a != 0xAF63DC4C8601EC8C as UInt64 { return 108; }
  var o128: UInt128 = 0x6C62272E07BB014262B821756295C58D as UInt128;
  let f1e = fnv.fnv1_128(&empty);
  if f1e != o128 { return 109; }
  let fae = fnv.fnv1a_128(&empty);
  if fae != o128 { return 110; }
  var seed64: UInt128 = 0xCBF29CE484222325 as UInt128;
  let fse = fnv.fnv1a_128_seed(&empty, seed64);
  if fse != seed64 { return 111; }
  let fsh = fnv.fnv1a_128_seed(&hello, seed64);
  let fsw = fnv.fnv1a_128_seed(&world, seed64);
  if fsh == fsw { return 112; }

  // ---- hash: jenkins
  let j1 = jenkins.jenkins_lookup3(&empty, 0 as UInt32);
  if j1.len() != 2 { return 113; }
  let j2 = jenkins.jenkins_lookup3(&hello, 0 as UInt32);
  if j2.len() != 2 { return 114; }
  let j3 = jenkins.jenkins_lookup3(&hello, 0 as UInt32);
  if j3[0] != j2[0] || j3[1] != j2[1] { return 115; }

  // ---- hash: murmur
  let m1 = murmur.murmur3_128(&empty, 0 as UInt32);
  if m1.len() != 2 { return 116; }
  let m2 = murmur.murmur3_128(&hello, 0 as UInt32);
  if m2.len() != 2 { return 117; }
  var mseed: UInt64 = 42 as UInt64;
  let m2e = murmur.murmur2_64(&empty, mseed);
  let m2e2 = murmur.murmur2_64(&empty, mseed);
  if m2e != m2e2 { return 118; }
  let m2h = murmur.murmur2_64(&hello, 0 as UInt64);
  let m2w = murmur.murmur2_64(&world, 0 as UInt64);
  if m2h == m2w { return 119; }

  // ---- hash: superfast
  if superfast.superfast32(&empty) != 0 { return 120; }
  if superfast.superfast32(&a) != 0x1266f960 { return 121; }
  var abc = _bytes("abc");
  if superfast.superfast32(&abc) != 0xd7be8b0f { return 122; }

  // adler32's b counter wraps to 0 after 65521 zero bytes, so the result is
  // 1 again (the empty-only clause must NOT claim a non-empty lower bound).
  var zeros = Vec[UInt8].new();
  var zi = 0;
  while zi < 65521 {
    zeros.push(0 as UInt8);
    zi = zi + 1;
  }
  let adler_wrap = adler.adler32(&zeros);
  if adler_wrap != 1 as UInt32 { return 123; }

  return 0;
}
