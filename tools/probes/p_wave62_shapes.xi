// p_wave62_shapes.xi -- wave 62 shape validation: xiom.net batch 5
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-62 clauses on xiom.net.{sse, websocket, ws, dns,
// multipart} (41 pub fns). No socket/DNS I/O: network entry points use
// early-error paths with synthetic connection structs (open:false/fd:-1);
// ws_close/ws_ping/ws_pong are compile-only (unconditional sends, not
// called). Returns 0 when every case holds.

module p_wave62_shapes

use xiom.net.sse;
use xiom.net.websocket;
use xiom.net.ws;
use xiom.net.dns;
use xiom.net.multipart;
use xiom.net.sse.SseEvent;
use xiom.net.websocket.WsFrame;
use xiom.net.websocket.WsConnection;
use xiom.net.multipart.Part;

fn main() -> Int {
  // ---- sse
  if sse.sse_parse_event("").is_ok { return 1; }
  match sse.sse_parse_event("data: hi\n\n") {
    Ok(e) => {
      if !(e.data == "hi") { return 2; }
      if sse.sse_event_id(e).is_some { return 3; }
      if !(sse.sse_event_data(e) == "hi") { return 4; }
    },
    Err(_) => { return 5; },
  }
  match sse.sse_parse_event("id: 42\ndata: a\ndata: b\n\n") {
    Ok(e2) => {
      if !sse.sse_event_id(e2).is_some { return 6; }
      if !(sse.sse_event_data(e2) == "a\nb") { return 7; }
    },
    Err(_) => { return 8; },
  }
  if !sse.sse_connect("").is_err { return 9; }
  if !sse.sse_connect_headers("", Vec[(Str, Str)].new()).is_err { return 10; }
  // sse_read_event / sse_read_events / sse_close take an SseConnection;
  // there is no public constructor, so they stay compile-checked only.

  // ---- websocket pure
  if !(websocket.ws_handshake_request("h", "", "k").len() == 117) { return 13; }
  if !(websocket.ws_accept_key("dGhlIHNhbXBsZSBub25jZQ==") == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=") { return 14; }
  if websocket.ws_accept_key("abc").len() != 28 { return 15; }
  if websocket.ws_handshake_verify("", "k") { return 16; }
  if websocket.ws_handshake_verify("HTTP/1.1 404 X\r\n", "k") { return 17; }
  let okkey = websocket.ws_accept_key("dGhlIHNhbXBsZSBub25jZQ==");
  let canonical = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nSec-WebSocket-Accept: " + okkey + "\r\n\r\n";
  if !websocket.ws_handshake_verify(canonical, "dGhlIHNhbXBsZSBub25jZQ==") { return 18; }
  var small_payload = Vec[UInt8].new();
  small_payload.push(104);
  small_payload.push(105);
  let enc = websocket.ws_frame_encode(1, &small_payload, false);
  if !(enc.len() == 4) { return 19; }
  if !(enc[0] == (0x81 as UInt8)) { return 20; }
  var frame = Vec[UInt8].new();
  frame.push(0x81);
  frame.push(0x02);
  frame.push(0x68);
  frame.push(0x69);
  match websocket.ws_frame_decode(&frame) {
    Ok(f) => {
      if !f.fin { return 21; }
      if f.opcode != 1 { return 22; }
      if f.masked { return 23; }
      if f.payload.len() != 2 { return 24; }
    },
    Err(_) => { return 25; },
  }
  if websocket.ws_frame_decode(&Vec[UInt8].new()).is_ok { return 26; }
  if websocket.ws_random_key().len() != 24 { return 27; }
  if websocket.ws_parse_url("").is_ok { return 28; }
  if websocket.ws_parse_url("noscheme").is_ok { return 29; }
  if !websocket.ws_parse_url("ws://ex.com:8080/chat?q=1#f").is_ok { return 30; }
  if !websocket.ws_connect("").is_err { return 31; }
  if !websocket.ws_connect("noscheme").is_err { return 32; }
  var wconn = WsConnection{ fd: -1; key: ""; open: false; };
  if !websocket.ws_send(&wconn, "x").is_err { return 33; }
  if !websocket.ws_send_binary(&wconn, Vec[UInt8].new()).is_err { return 34; }
  if !websocket.ws_recv(&wconn).is_err { return 35; }

  // ---- ws (pure twin)
  if ws.ws_default_port("wss") != 443 { return 36; }
  if ws.ws_default_port("ws") != 80 { return 37; }
  if !ws.ws_parse_url("ws://h/x").is_ok { return 38; }
  if ws.ws_parse_url("http://h").is_ok { return 39; }
  if !(ws.ws_build_url("ws", "example.com", 80, "/x") == "ws://example.com/x") { return 40; }
  if !(ws.ws_build_url("wss", "h", 443, "") == "wss://h/") { return 41; }
  if !ws.ws_is_ws_url("ws://x") { return 42; }
  if ws.ws_is_wss_url("ws://x") { return 43; }
  if ws.ws_is_ws_url("") { return 44; }

  // ---- dns (pure)
  if !dns.dns_parse_ipv4("192.168.0.1").is_some { return 45; }
  if dns.dns_parse_ipv4("").is_some { return 46; }
  if dns.dns_parse_ipv4("1.2.3").is_some { return 47; }
  var four = Vec[UInt8].new();
  four.push(192);
  four.push(168);
  four.push(0);
  four.push(1);
  if !dns.dns_ipv4_to_str(&four).is_some { return 48; }
  if dns.dns_ipv4_to_str(&Vec[UInt8].new()).is_some { return 49; }
  if !dns.dns_parse_ipv6("::").is_some { return 50; }
  if dns.dns_parse_ipv6("").is_some { return 51; }
  var six = Vec[UInt8].new();
  var zi = 0;
  while zi < 16 { six.push(0); zi = zi + 1; }
  if !dns.dns_ipv6_to_str(&six).is_some { return 52; }
  if dns.dns_ipv6_to_str(&four).is_some { return 53; }
  if !dns.dns_parse_record_line("example.com. 3600 IN A 93.184.216.34").is_some { return 54; }
  if dns.dns_parse_record_line("").is_some { return 55; }
  if !dns.dns_is_valid_hostname("example.com") { return 56; }
  if dns.dns_is_valid_hostname("") { return 57; }
  var rev = Vec[UInt8].new();
  rev.push(8);
  rev.push(8);
  rev.push(4);
  rev.push(4);
  if !dns.dns_reverse_ipv4(&rev).is_some { return 58; }
  if dns.dns_reverse_ipv4(&Vec[UInt8].new()).is_some { return 59; }
  if !dns.dns_well_known_port("http").is_some { return 60; }
  if dns.dns_well_known_port("").is_some { return 61; }

  // ---- multipart (pure)
  let p1 = multipart.multipart_part("f", "v");
  if !(p1.name == "f") { return 62; }
  if p1.filename.len() != 0 { return 63; }
  var mdata = Vec[UInt8].new();
  mdata.push(1);
  mdata.push(2);
  let p2 = multipart.multipart_part_file("g", "a.txt", "text/plain", &mdata);
  if !(p2.filename == "a.txt" && p2.content_type == "text/plain") { return 64; }
  if p2.data.len() != 2 { return 65; }
  let empty_parts = Vec[Part].new();
  if multipart.multipart_build(&empty_parts, "b").len() != 7 { return 66; }
  if !(multipart.multipart_content_type("bnd") == "multipart/form-data; boundary=bnd") { return 67; }
  if multipart.multipart_parse(&Vec[UInt8].new(), "b").is_ok { return 68; }
  if !(multipart.multipart_boundary_new().len() > 16) { return 69; }
  var parts = Vec[Part].new();
  parts.push(p1);
  parts.push(p2);
  let body = multipart.multipart_build(&parts, "bnd");
  match multipart.multipart_parse(&body, "bnd") {
    Ok(out) => {
      if out.len() != 2 { return 70; }
      // Part field reads of multipart_parse results are corrupt on both
      // pins (see known_failures/p_multipart_parse_name.xi); presence-only.
    },
    Err(_) => { return 73; },
  }
  return 0;
}
