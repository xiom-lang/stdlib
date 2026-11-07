// XIOM stdlib smoke -- strict HTTP/1.1 framing (request-smuggling class).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Regression corpus for REL-20261107-1032-pulse and REL-20261106-1716-pulse:
// duplicate/conflicting/overflowing Content-Length, BWS before the colon,
// TE.TE and TE+CL, NUL/CTL in the head, extra request-line tokens and
// obs-fold are rejected; the body remains binary-safe.

module smoke_net_framing_strict
use xiom.net.server;
use xiom.string;
use xiom.string.slice;
use xiom.io;

fn none_of(s: Str) -> Bool {
  let b = slice.str_bytes(s);
  match server.server_parse_request(&b) {
    Some(_) => false,
    None => true,
  }
}

fn main() -> Int {
  // Valid baselines.
  let good = slice.str_bytes("GET / HTTP/1.1\r\nHost: t\r\n\r\n");
  match server.server_parse_request(&good) {
    Some(r) => {
      if r.method != "GET" { return 1; }
      if r.target != "/" { return 2; }
      if r.version != "HTTP/1.1" { return 3; }
      if r.body_len != 0 { return 4; }
      if r.body_start + r.body_len != good.len() { return 5; }
    },
    None => { return 6; },
  };

  let with_body = slice.str_bytes("POST /x HTTP/1.1\r\nHost: t\r\nContent-Length: 7\r\n\r\n1234567");
  match server.server_parse_request(&with_body) {
    Some(r) => {
      if r.body_len != 7 { return 7; }
      if r.body_start + r.body_len != with_body.len() { return 8; }
    },
    None => { return 9; },
  };

  // Body binary safety: NUL in the body is fine once the head is valid.
  var binary_body = slice.str_bytes("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: 3\r\n\r\n");
  binary_body.push(65u8);
  binary_body.push(0u8);
  binary_body.push(66u8);
  match server.server_parse_request(&binary_body) {
    Some(r) => {
      if r.body_len != 3 { return 10; }
      if r.body_start + r.body_len != binary_body.len() { return 11; }
    },
    None => { return 12; },
  };

  // Exactly one TE, exactly chunked, is accepted.
  if none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\n\r\n") { return 13; }
  if none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: Chunked\r\n\r\n") { return 14; }
  // OWS around the value is allowed and trimmed.
  if none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length:  7  \r\n\r\n1234567") { return 15; }

  // Duplicate / conflicting / malformed Content-Length.
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: 7\r\nContent-Length: 7\r\n\r\n1234567") { return 20; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: 7\r\nContent-Length: 8\r\n\r\n1234567") { return 21; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: 999999999999999999999\r\n\r\n") { return 22; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: +0\r\n\r\n") { return 23; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length: -1\r\n\r\n") { return 24; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length:\r\n\r\n") { return 25; }

  // BWS before the colon / whitespace in the field name.
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nContent-Length : 7\r\n\r\n1234567") { return 30; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding : chunked\r\n\r\n") { return 31; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nX-Test : v\r\n\r\n") { return 32; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nX\t-Test: v\r\n\r\n") { return 33; }

  // TE.TE / non-chunked TE / TE+CL.
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\nTransfer-Encoding: identity\r\n\r\n") { return 40; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: identity\r\n\r\n") { return 41; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked, identity\r\n\r\n") { return 42; }
  if !none_of("POST / HTTP/1.1\r\nHost: t\r\nTransfer-Encoding: chunked\r\nContent-Length: 7\r\n\r\n1234567") { return 43; }

  // NUL/CTL in the request head (REL-20261106-1716-pulse).
  if !none_of("PO\u{0000}ST /x HTTP/1.1\r\nHost: t\r\n\r\n") { return 50; }
  if !none_of("\u{0000}OST /x HTTP/1.1\r\nHost: t\r\n\r\n") { return 51; }
  if !none_of("GET /x\u{0000} HTTP/1.1\r\nHost: t\r\n\r\n") { return 52; }
  if !none_of("GET / HTTP/1.1\r\nHo\u{0000}st: t\r\n\r\n") { return 53; }
  if !none_of("GET / HTTP/1.1\r\nX: a\u{0000}b\r\n\r\n") { return 54; }
  if !none_of("GET / HTTP/1.1\r\nX: a\nb\r\n\r\n") { return 55; }

  // Extra request-line token / wrong version / obs-fold.
  if !none_of("GET / HTTP/1.1 EXTRA\r\nHost: t\r\n\r\n") { return 60; }
  if !none_of("GET / HTTP/2.0\r\nHost: t\r\n\r\n") { return 61; }
  if !none_of("GET / HTTP/1.1\r\nHost: t\r\n X: y\r\n\r\n") { return 62; }

  io.println("OK");
  return 0;
}

