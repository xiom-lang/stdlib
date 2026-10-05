// p_pulse_shapes.xi -- Pulse hardening wave: TcpStream.write_all,
// server_parse_request, hmac_sha256_hex
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the three new Pulse-relay surfaces: write_all over a real
// loopback with a payload larger than the 64 KiB staging buffer (chunking
// plus partial sends), server_parse_request over crafted request bytes
// (headers, Content-Length and body span; malformed/empty None paths), and
// hmac_sha256_hex against RFC 4231 test case 1. Returns 0 when every case
// holds. `Vec.new()` temporaries passed as `&Vec` are bound first.

module p_pulse_shapes

use xiom.net;
use xiom.net.server;
use xiom.crypto;
use xiom.string.slice;

fn _bytes(s: Str) -> Vec[UInt8] {
  return slice.str_bytes(s);
}

fn main() -> Int {
  // ---- hmac_sha256_hex (RFC 4231 case 1)
  var key = Vec[UInt8].new();
  var i = 0;
  while i < 20 {
    key.push(11u8);
    i = i + 1;
  }
  var data = _bytes("Hi There");
  let hex = crypto.hmac_sha256_hex(&key, &data);
  if hex.len() != 64 { return 1; }
  if hex != "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7" { return 2; }
  if crypto.hmac_sha256(&key, &data).len() != 32 { return 3; }

  // ---- server_parse_request: head + body
  let req = _bytes("POST /submit?q=1 HTTP/1.1\r\nHost: example\r\nContent-Length: 5\r\n\r\nhello");
  match server.server_parse_request(&req) {
    Some(r) => {
      if r.method != "POST" { return 4; }
      if r.target != "/submit?q=1" { return 5; }
      if r.version != "HTTP/1.1" { return 6; }
      if r.headers.len() != 2 { return 7; }
      if r.headers[0].0 != "host" { return 8; }
      if r.headers[0].1 != "example" { return 9; }
      if r.headers[1].0 != "content-length" { return 10; }
      if r.body_len != 5 { return 11; }
      if r.body_start < 0 { return 12; }
      if r.body_start + r.body_len > req.len() { return 13; }
      if req[r.body_start] != 104u8 { return 14; }
      if req[r.body_start + 4] != 111u8 { return 15; }
    },
    None => { return 16; },
  }

  // ---- server_parse_request: no body, no Content-Length
  let req2 = _bytes("GET / HTTP/1.1\r\nHost: a\r\n\r\n");
  match server.server_parse_request(&req2) {
    Some(r2) => {
      if r2.method != "GET" { return 17; }
      if r2.body_len != 0 { return 18; }
      if r2.headers.len() != 1 { return 19; }
    },
    None => { return 20; },
  }

  // ---- server_parse_request: malformed (no terminator) and empty
  var bad = Vec[UInt8].new();
  bad.push(71u8);
  bad.push(69u8);
  bad.push(84u8);
  match server.server_parse_request(&bad) {
    Some(_) => { return 21; },
    None => { },
  }
  var empty = Vec[UInt8].new();

  // ---- server_parse_request: colon-less header and bad Content-Length
  let req3 = _bytes("GET / HTTP/1.1\r\nBadHeader\r\n\r\n");
  match server.server_parse_request(&req3) {
    Some(_) => { return 34; },
    None => { },
  }
  let req4 = _bytes("POST / HTTP/1.1\r\nContent-Length: nope\r\n\r\n");
  match server.server_parse_request(&req4) {
    Some(_) => { return 35; },
    None => { },
  }
  let req5 = _bytes("POST / HTTP/1.1\r\nContent-Length: -3\r\n\r\n");
  match server.server_parse_request(&req5) {
    Some(_) => { return 36; },
    None => { },
  }
  match server.server_parse_request(&empty) {
    Some(_) => { return 22; },
    None => { },
  }

  // ---- TcpStream.write_all loopback: 100000 bytes (> one chunk)
  match net.tcp_listen("127.0.0.1", 39462) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39462) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              var payload = Vec[UInt8].new();
              var k = 0;
              while k < 100000 {
                payload.push((k % 251) as UInt8);
                k = k + 1;
              }
              match c.clone().write_all(&payload) {
                Ok(total) => { if total != 100000 { return 23; } }
                Err(_) => { return 24; }
              }
              var got = Vec[UInt8].new();
              while got.len() < 100000 {
                match s.clone().read(&mut got) {
                  Ok(0) => { break; }
                  Ok(_) => { },
                  Err(_) => { return 25; },
                }
              }
              if got.len() != 100000 { return 26; }
              if got[0] != 0u8 { return 27; }
              if got[99999] != ((99999 % 251) as UInt8) { return 28; }
              if got[65536] != ((65536 % 251) as UInt8) { return 29; }
              s.close();
              c.close();
              return 0;
            },
            Err(_) => { return 30; },
          }
        },
        Err(_) => { return 31; },
      }
    },
    Err(_) => { return 32; },
  }
  return 33;
}
