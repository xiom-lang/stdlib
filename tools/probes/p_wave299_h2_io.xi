// p_wave299_h2_io.xi -- HTTP/2 frame I/O over a stream
// (completes the h2 usable transport on top of the pure primitives).
//
// Covers: fragmented HEADERS + CONTINUATION write/read/join, SETTINGS and
// PING ACK writers, EOF handling, max_payload enforcement, empty header
// blocks, and rejecting a non-HEADERS first frame in the joiner.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_wave299_h2_io

use xiom.net;
use xiom.net.h2;
use xiom.net.h2_io;

fn _pattern(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  v.reserve(n);
  var i = 0;
  while i < n {
    v.push((i % 251) as UInt8);
    i = i + 1;
  }
  v
}

fn _same(a: &Vec[UInt8], b: &Vec[UInt8]) -> Bool {
  if a.len() != b.len() { return false; }
  var i = 0;
  while i < a.len() {
    if a[i] != b[i] { return false; }
    i = i + 1;
  }
  true
}

// mode1: fragmented HEADERS + CONTINUATION, SETTINGS/PING ACKs, EOF.
fn mode1() -> Int {
  let block = _pattern(40001);
  match net.tcp_listen("127.0.0.1", 39464) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39464) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              match h2_io.h2_write_header_block(&s, 1, &block, true, 16384) {
                Ok(n) => { if n < 40001 { return 1; } },
                Err(_) => { return 2; },
              }
              match h2_io.h2_write_settings_ack(&s) {
                Ok(n) => { if n != 9 { return 3; } },
                Err(_) => { return 4; },
              }
              var ping = Vec[UInt8].new();
              var p = 0;
              while p < 8 {
                ping.push((p + 65) as UInt8);
                p = p + 1;
              }
              match h2_io.h2_write_ping_ack(&s, &ping) {
                Ok(n) => { if n != 17 { return 5; } },
                Err(_) => { return 6; },
              }
              let _ = s.close();

              var r = h2_io.h2_reader_new(c, 16384);
              match h2_io.h2_reader_read_frame(&mut r) {
                Err(_) => { return 7; },
                Ok(f) => {
                  if f.0.frame_type != h2.H2_FRAME_HEADERS { return 8; }
                  if f.0.stream_id != 1 { return 9; }
                  if (f.0.flags & h2.H2_FLAG_END_STREAM) == 0 { return 10; }
                  if (f.0.flags & h2.H2_FLAG_END_HEADERS) != 0 { return 11; }
                  if f.0.length != 16384 { return 12; }
                  match h2_io.h2_join_header_block(&mut r, f, 1048576) {
                    Err(_) => { return 13; },
                    Ok(joined) => {
                      if joined.len() != 40001 { return 14; }
                      if !_same(&joined, &block) { return 15; }
                    },
                  }
                  match h2_io.h2_reader_read_frame(&mut r) {
                    Err(_) => { return 16; },
                    Ok(sf) => {
                      if sf.0.frame_type != h2.H2_FRAME_SETTINGS { return 17; }
                      if (sf.0.flags & h2.H2_FLAG_ACK) == 0 { return 18; }
                      if sf.0.stream_id != 0 { return 19; }
                      if sf.1.len() != 0 { return 20; }
                    },
                  }
                  match h2_io.h2_reader_read_frame(&mut r) {
                    Err(_) => { return 21; },
                    Ok(pf) => {
                      if pf.0.frame_type != h2.H2_FRAME_PING { return 22; }
                      if (pf.0.flags & h2.H2_FLAG_ACK) == 0 { return 23; }
                      if !_same(&pf.1, &ping) { return 24; }
                    },
                  }
                  match h2_io.h2_reader_read_frame(&mut r) {
                    Ok(_) => { return 25; },
                    Err(_) => { },
                  }
                  h2_io.h2_reader_close(&mut r);
                  return 0;
                },
              }
            },
            Err(_) => { return 26; },
          }
        },
        Err(_) => { return 27; },
      }
    },
    Err(_) => { return 28; },
  }
}

// mode2: a frame above max_payload is rejected before the payload is read.
fn mode2() -> Int {
  let big = _pattern(20000);
  match net.tcp_listen("127.0.0.1", 39465) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39465) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              match h2_io.h2_write_frame(&s, h2.H2_FRAME_HEADERS, h2.H2_FLAG_END_HEADERS, 3, &big) {
                Ok(_) => { },
                Err(_) => { return 31; },
              }
              let _ = s.close();
              var r = h2_io.h2_reader_new(c, 16384);
              match h2_io.h2_reader_read_frame(&mut r) {
                Ok(_) => { return 32; },
                Err(_) => { },
              }
              h2_io.h2_reader_close(&mut r);
              return 0;
            },
            Err(_) => { return 33; },
          }
        },
        Err(_) => { return 34; },
      }
    },
    Err(_) => { return 35; },
  }
}

// mode3: an empty header block is one HEADERS with END_HEADERS and no
// CONTINUATION; the joiner returns an empty block.
fn mode3() -> Int {
  match net.tcp_listen("127.0.0.1", 39466) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39466) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              var empty = Vec[UInt8].new();
              match h2_io.h2_write_header_block(&s, 5, &empty, false, 16384) {
                Ok(n) => { if n != 9 { return 41; } },
                Err(_) => { return 42; },
              }
              let _ = s.close();
              var r = h2_io.h2_reader_new(c, 16384);
              match h2_io.h2_reader_read_frame(&mut r) {
                Err(_) => { return 43; },
                Ok(f) => {
                  if f.0.frame_type != h2.H2_FRAME_HEADERS { return 44; }
                  if (f.0.flags & h2.H2_FLAG_END_HEADERS) == 0 { return 45; }
                  if f.1.len() != 0 { return 46; }
                  match h2_io.h2_join_header_block(&mut r, f, 1048576) {
                    Err(_) => { return 47; },
                    Ok(out) => { if out.len() != 0 { return 48; } },
                  }
                },
              }
              h2_io.h2_reader_close(&mut r);
              return 0;
            },
            Err(_) => { return 49; },
          }
        },
        Err(_) => { return 50; },
      }
    },
    Err(_) => { return 51; },
  }
}

// mode4: the joiner rejects a non-HEADERS first frame.
fn mode4() -> Int {
  match net.tcp_listen("127.0.0.1", 39467) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39467) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              var one = Vec[UInt8].new();
              one.push(120u8);
              match h2_io.h2_write_frame(&s, h2.H2_FRAME_DATA, 0, 7, &one) {
                Ok(_) => { },
                Err(_) => { return 61; },
              }
              let _ = s.close();
              var r = h2_io.h2_reader_new(c, 16384);
              match h2_io.h2_reader_read_frame(&mut r) {
                Err(_) => { return 62; },
                Ok(f) => {
                  if f.0.frame_type != h2.H2_FRAME_DATA { return 63; }
                  match h2_io.h2_join_header_block(&mut r, f, 1048576) {
                    Ok(_) => { return 64; },
                    Err(_) => { },
                  }
                },
              }
              h2_io.h2_reader_close(&mut r);
              return 0;
            },
            Err(_) => { return 65; },
          }
        },
        Err(_) => { return 66; },
      }
    },
    Err(_) => { return 67; },
  }
}

fn main() -> Int {
  // Writer range check (no socket needed).
  var empty = Vec[UInt8].new();
  match net.tcp_listen("127.0.0.1", 39468) {
    Ok(l) => {
      match net.tcp_connect("127.0.0.1", 39468) {
        Ok(c) => {
          match l.accept() {
            Ok(pair) => {
              let s = pair.0;
              match h2_io.h2_write_header_block(&s, -1, &empty, false, 16384) {
                Ok(_) => { return 71; },
                Err(_) => { },
              }
              let _ = s.close();
              let _ = c.close();
            },
            Err(_) => { return 72; },
          }
        },
        Err(_) => { return 73; },
      }
    },
    Err(_) => { return 74; },
  }

  let m1 = mode1();
  if m1 != 0 { return m1; }
  let m2 = mode2();
  if m2 != 0 { return m2; }
  let m3 = mode3();
  if m3 != 0 { return m3; }
  let m4 = mode4();
  if m4 != 0 { return m4; }
  return 0;
}
