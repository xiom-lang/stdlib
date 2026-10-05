// p_pin0631_shapes.xi -- v0.63.1 pin locks: monotonic Instant + lz4 bare leaf
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the stdlib-side changes of the v0.63.1 pin wave:
//   - xiom.time.Instant.now()/elapsed() read the runtime monotonic clock
//     (second resolution), not the wall-clock time(0) path; SystemTime stays
//     epoch wall clock; instant_* arithmetic wrappers are unchanged.
//   - the exact colliding lz4 shape (`use xiom.compress; use
//     xiom.compress.lz4;` + bare lz4_compress) resolves to the Vec-returning
//     module function, with lz4_compress_checked as the Result wrapper.
// Returns 0 when every case holds.

module p_pin0631_shapes

use xiom.time;
use xiom.time.instant;
use xiom.compress;
use xiom.compress.lz4;
use xiom.compress.gzip;

fn _seq(n: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(i as UInt8);
    i = i + 1;
  }
  return v;
}

fn main() -> Int {
  // ---- Instant is monotonic-backed (seconds), not epoch wall clock
  let i1 = time.Instant.now();
  if i1.t < 0 { return 1; }
  if i1.t >= 1000000000 { return 2; }
  let i2 = time.Instant.now();
  if i2.t < i1.t { return 3; }
  let elapsed = i1.elapsed();
  if elapsed.secs < 0 { return 4; }
  let iw = instant.instant_now();
  if iw.t >= 1000000000 { return 5; }

  // ---- SystemTime stays epoch wall clock
  let wall = time.SystemTime.now();
  if wall.secs < 1000000000 { return 6; }

  // ---- instant_* arithmetic wrappers unchanged
  let a = instant.instant_from_millis(5000);
  let b = instant.instant_from_millis(3000);
  if instant.instant_duration_since(a, b).secs != 2 { return 7; }
  if instant.instant_to_millis(a) != 5000 { return 8; }
  if instant.instant_compare(a, b) != 1 { return 9; }

  // ---- lz4 bare leaf resolves to the Vec-returning module function
  let data = _seq(16000);
  let frame = lz4_compress(&data);
  if frame.len() < 11 { return 10; }
  let checked = lz4_compress_checked(&data);
  if !checked.is_ok { return 11; }
  match lz4.lz4_decompress(&frame) {
    Ok(v) => { if v.len() != data.len() { return 12; } }
    Err(_) => { return 12; }
  }

  // ---- gzip file wrappers: the io Err path that regressed on v0.63.1
  // (io.write_file_bytes' retired Err-payload clause was lowered as
  // str_len(IOError)); both must compile and return Err on an empty path.
  let gzr = gzip.gzip_compress_file("");
  if !gzr.is_err { return 13; }
  let gzr2 = gzip.gzip_decompress_file("");
  if !gzr2.is_err { return 14; }

  return 0;
}
