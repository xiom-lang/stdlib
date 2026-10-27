// p_http_parse_alloc.xi -- server_parse_request allocation gate
// (REL-20261027-1955-pulse-2).
//
// The request parser used to copy the whole head into a Vec, copy it again
// into a Str, then allocate a slice per request-line field and two per
// header (slice + lowercase). On the current compilers those allocations
// are retained, so a 50k-parse loop peaked at ~454 MB (~8.9 KB/iter). The
// span-parse version parses straight from the input buffer and allocates
// once per returned field and once per header name/value.
//
// This probe checks semantics first, then (on Linux) measures the retained
// resident-set growth over 50k parses and requires <= 1280 B/iteration.
// Measured on the v0.64.8/v0.65.2 compilers: Windows 857 B/iter (the
// platform PULSE measures), WSL/glibc ~1138 B/iter (allocator overhead);
// the pre-fix parser was ~8954 B/iter on Windows. The 1280 B bound keeps
// headroom for glibc while still failing the old behaviour by ~7x.
// Other platforms skip the measurement (no /proc); the probe is still a
// semantics gate there.
//
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_http_parse_alloc

use xiom.net.server;
use xiom.string.slice;
use xiom.os;

extern "C" {
  fn fopen(path: *UInt8, mode: *UInt8) -> *UInt8;
  fn fgets(buf: *UInt8, size: Int32, file: *UInt8) -> *UInt8;
  fn fclose(file: *UInt8) -> Int32;
}

const ITERS: Int = 50000;
const MAX_BYTES_PER_ITER: Int = 1280;

// _rss_bytes returns the current resident set size in bytes on Linux
// (/proc/self/statm field 2 times the page size), or -1 elsewhere. It uses
// stdio because /proc files report size 0 to stat/read_file.
fn _rss_bytes() -> Int {
  if os.platform() != "linux" { return -1; }
  let f: *UInt8;
  var line: [128]UInt8;
  unsafe {
    f = fopen("/proc/self/statm".c_str(), "r".c_str());
    if f == 0 { return -1; }
    let got = fgets(&line[0], 128 as Int32, f);
    let _ = fclose(f);
    if got == 0 { return -1; }
  }
  // Fields: "size resident shared text lib data dt". Skip the first
  // number, then read the resident-page count.
  var i = 0;
  while i < 128 && line[i] != 0u8 && line[i] != 32u8 { i = i + 1; }
  if i >= 127 || line[i] == 0u8 { return -1; }
  i = i + 1;
  var pages = 0;
  var digits = 0;
  while i < 128 && line[i] >= 48u8 && line[i] <= 57u8 {
    pages = pages * 10 + ((line[i] - 48) as Int);
    digits = digits + 1;
    i = i + 1;
  }
  if digits == 0 { return -1; }
  return pages * os.page_size();
}

fn main() -> Int {
  let head = "GET /health?x=1 HTTP/1.1\r\nHost: example.com\r\nAccept: */*\r\nUser-Agent: pulse\r\nContent-Length: 0\r\n\r\n";
  var req = slice.str_bytes(head);

  // Semantics: the span parser must return the same fields as before.
  match server.server_parse_request(&req) {
    Some(r) => {
      if r.method != "GET" { return 1; }
      if r.target != "/health?x=1" { return 2; }
      if r.version != "HTTP/1.1" { return 3; }
      if r.headers.len() != 4 { return 4; }
      if r.headers[0].0 != "host" { return 5; }
      if r.headers[0].1 != "example.com" { return 6; }
      if r.headers[1].0 != "accept" { return 7; }
      if r.headers[1].1 != "*/*" { return 8; }
      if r.headers[2].0 != "user-agent" { return 9; }
      if r.headers[2].1 != "pulse" { return 10; }
      if r.headers[3].0 != "content-length" { return 11; }
      if r.headers[3].1 != "0" { return 12; }
      if r.body_len != 0 { return 13; }
      if r.body_start != req.len() { return 14; }
    },
    None => { return 15; },
  }

  // Warm up the allocator and the parse path.
  var acc = 0;
  var w = 0;
  while w < 1000 {
    match server.server_parse_request(&req) {
      Some(rw) => { acc = acc + rw.method.len(); },
      None => { return 16; },
    }
    w = w + 1;
  }

  let before = _rss_bytes();
  if before < 0 { return 0; }  // measurement unsupported on this platform

  var i = 0;
  while i < ITERS {
    match server.server_parse_request(&req) {
      Some(r) => {
        acc = acc + r.method.len() + r.target.len() + r.headers.len() + r.body_len;
      },
      None => { return 17; },
    }
    i = i + 1;
  }

  let after = _rss_bytes();
  if after < 0 { return 0; }
  let delta = after - before;
  if delta <= 0 { return 0; }  // freed per iteration (no retention signal)
  let per_iter = delta / ITERS;
  if per_iter > MAX_BYTES_PER_ITER { return 18; }
  if acc < 0 { return 19; }
  return 0;
}
