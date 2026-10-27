// p_wave298_sse_wire.xi -- SSE wire encoders + server-side writers
// (REL-20261015-2202-pulse item 7).
//
// Locks the server half of SSE: event/comment/heartbeat encoding, the
// round-trip through sse_parse_event, CR/LF injection rejection, and a real
// loopback write through sse_write_event + sse_heartbeat.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave298_sse_wire

use xiom.net;
use xiom.net.sse;

fn main() -> Int {
  // ---- event round trip: id, event, multi-line data, retry
  let e = sse.SseEvent{ id: "7"; event: "update"; data: "line1\nline2"; retry: 3000; };
  match sse.sse_encode_event(e) {
    Ok(w) => {
      if w.len() == 0 { return 1; }
      if w.starts_with("id: 7\n") != true { return 2; }
      if w.ends_with("\n\n") != true { return 3; }
      match sse.sse_parse_event(w) {
        Ok(p) => {
          if p.id != "7" { return 4; }
          if p.event != "update" { return 5; }
          if p.data != "line1\nline2" { return 6; }
          if p.retry != 3000 { return 7; }
        },
        Err(_) => { return 8; },
      }
    },
    Err(_) => { return 9; },
  }

  // ---- empty data is still a complete event
  let e2 = sse.SseEvent{ id: ""; event: "message"; data: ""; retry: 0; };
  match sse.sse_encode_event(e2) {
    Ok(w2) => {
      match sse.sse_parse_event(w2) {
        Ok(p2) => {
          if p2.data != "" { return 10; }
          if p2.event != "message" { return 11; }
        },
        Err(_) => { return 12; },
      }
    },
    Err(_) => { return 13; },
  }

  // ---- injection rejection
  let bad_id = sse.SseEvent{ id: "a\rb"; event: ""; data: ""; retry: 0; };
  if sse.sse_encode_event(bad_id).is_ok { return 14; }
  let bad_event = sse.SseEvent{ id: ""; event: "a\nb"; data: ""; retry: 0; };
  if sse.sse_encode_event(bad_event).is_ok { return 15; }
  let bad_data = sse.SseEvent{ id: ""; event: ""; data: "a\rb"; retry: 0; };
  if sse.sse_encode_event(bad_data).is_ok { return 16; }
  let bad_retry = sse.SseEvent{ id: ""; event: ""; data: ""; retry: -1; };
  if sse.sse_encode_event(bad_retry).is_ok { return 17; }

  // ---- comments + heartbeat
  if sse.sse_encode_heartbeat() != ": ping\n\n" { return 18; }
  match sse.sse_encode_comment("ready\nstill here") {
    Ok(c) => {
      if c != ": ready\n: still here\n\n" { return 19; }
      match sse.sse_parse_event(c) {
        Ok(pc) => {
          if pc.data != "" { return 20; }
        },
        Err(_) => { return 21; },
      }
    },
    Err(_) => { return 22; },
  }
  if sse.sse_encode_comment("bad\rtext").is_ok { return 23; }

  // ---- loopback: write through the server helpers and parse the bytes
  match net.tcp_listen("127.0.0.1", 39463) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39463) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              let ev = sse.SseEvent{ id: "42"; event: "tick"; data: "a\nb"; retry: 0; };
              var sent = 0;
              match sse.sse_write_event(&s, ev) {
                Ok(n) => { sent = sent + n; },
                Err(_) => { return 24; },
              }
              match sse.sse_heartbeat(&s) {
                Ok(n) => {
                  if n != 8 { return 25; }
                  sent = sent + n;
                },
                Err(_) => { return 26; },
              }
              let _ = s.close();
              var got = Vec[UInt8].new();
              var open = true;
              while open {
                match c.clone().read(&mut got) {
                  Ok(0) => { open = false; },
                  Ok(_) => { },
                  Err(_) => { return 27; },
                }
              }
              if got.len() == 0 { return 28; }
              if got.len() != sent { return 29; }
              let text = Str::from_utf8(got);
              match sse.sse_parse_event(text) {
                Ok(pe) => {
                  if pe.id != "42" { return 30; }
                  if pe.event != "tick" { return 31; }
                  if pe.data != "a\nb" { return 32; }
                },
                Err(_) => { return 33; },
              }
              let _ = c.close();
              return 0;
            },
            Err(_) => { return 34; },
          }
        },
        Err(_) => { return 35; },
      }
    },
    Err(_) => { return 36; },
  }
}
