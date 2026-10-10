// p_wave104_shapes.xi -- wave 104 shape validation: Instant millisecond
// resolution + buffered-stdin normalization.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-104 fixes:
//   (a) Instant carries milliseconds: elapsed()/duration_since() report
//       real millisecond deltas, to/from millis round-trips, add/sub and
//       sleep_until use the same monotonic clock (benchmark-2,
//       REL-20261010-1554-benchmark-2);
//   (b) buf_reader_new(0) resolves stdin to the real FILE* instead of
//       casting 0 to a stream (benchmark-3, C-PIPE fix), so a piped-stdin
//       line can be read and never crashes; the FILE* constructor path
//       still reads real files.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave104_shapes

use xiom.time;
use xiom.time.instant;
use xiom.io as io;
use xiom.io.buffer as buffer;
use xiom.io.fs as fs;

extern "C" {
  fn fclose(file: *UInt8) -> Int32;
}

fn main() -> Int {
  // ---- Instant millisecond resolution (benchmark-2)
  let a = time.Instant.now();
  time.sleep_ms(400);
  let e = a.elapsed();
  let ems = e.as_millis();
  if ems < 300 { return 1; }
  let b = time.Instant.now();
  let d = b.duration_since(a);
  let dms = d.as_millis();
  if dms < 300 { return 2; }
  let c = instant.instant_from_millis(1500);
  let cm = instant.instant_to_millis(c);
  if cm != 1500 { return 3; }
  let added = a.add(time.Duration.from_millis(50));
  let ad = added.duration_since(a);
  if ad.as_millis() != 50 { return 4; }
  let subbed = added.sub(time.Duration.from_millis(50));
  let sd = subbed.duration_since(a);
  if sd.as_millis() != 0 { return 5; }
  let until = time.Instant.now().add(time.Duration.from_millis(250));
  time.sleep_until(until);
  let after = time.Instant.now();
  if after.t < until.t - 30 { return 6; }

  // ---- buf_reader_new(0): stdin resolves, empty piped input is safe
  var br0 = buffer.buf_reader_new(0);
  let l0 = buffer.br_read_line(&mut br0);
  if l0.is_ok != true { return 7; }

  // ---- buf_reader over a FILE* still reads real files
  let td = fs.fs_temp_dir();
  if td.len() == 0 { return 8; }
  let path = td + "/p_wave104_buf.txt";
  let wb = fs.fs_write_text(path, "wave104\nsecond\n");
  if wb.is_err { return 9; }
  var file: *UInt8 = fs.fopen(path, "r");
  var fdi: Int;
  unsafe { fdi = file as Int; }
  if fdi == 0 { return 10; }
  var br = buffer.buf_reader_new(fdi);
  let l1 = buffer.br_read_line(&mut br);
  match l1 {
    Ok(s) => { if s != "wave104" { return 11; } },
    Err(_) => { return 11; }
  }
  let l2 = buffer.br_read_line(&mut br);
  match l2 {
    Ok(s) => { if s != "second" { return 12; } },
    Err(_) => { return 12; }
  }
  unsafe { let _ = fclose(file); }
  let rm = fs.fs_remove(path);
  if rm.is_err { return 13; }

  return 0;
}
