// p_read_file_lines_crlf.xi -- probe lock: file byte fidelity + CRLF lines
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// ORBITDB defect relay 2026-10-08 (row 2): on CRLF files, read_file_lines
// used to return lines still carrying the trailing '\r' ("10\r"), so
// consumers parsing integers silently dropped records. The line fix strips
// one trailing CR per line. Root cause of the CRLF files: io.write_file /
// io.append_file / io.write_file_bytes opened in TEXT mode, so on Windows
// fwrite silently turned every LF into CRLF (and write_file_bytes was not
// byte-exact). All three now open binary ("wb"/"ab"), making content
// byte-exact on every platform. This probe locks both halves: byte-exact
// write/append roundtrips and CR-free line reads (with and without a
// trailing newline). Returns 0 when everything holds.

module p_read_file_lines_crlf

use xiom.io;

fn main() -> Int {
  let path = "__p_read_file_lines_crlf.txt";

  // 1. write_file must be byte-exact (no LF -> CRLF translation).
  match io.write_file(path, "a\nb") {
    Ok(_) => {},
    Err(_) => { return 1; },
  };
  let raw = io.read_file_bytes(path);
  match raw {
    Ok(rb) => {
      if rb.len() != 3 { return 2; }
      let b1 = rb[1];
      if b1 != (10 as UInt8) { return 3; }
    },
    Err(_) => { return 4; },
  };

  // 2. append_file must be byte-exact too.
  match io.append_file(path, "\n") {
    Ok(_) => {},
    Err(_) => { return 5; },
  };
  let raw2 = io.read_file_bytes(path);
  match raw2 {
    Ok(rb2) => {
      if rb2.len() != 4 { return 6; }
      let b3 = rb2[3];
      if b3 != (10 as UInt8) { return 7; }
    },
    Err(_) => { return 8; },
  };

  // 3. exact CRLF content -> read_file_lines returns clean lines.
  var crlf = Vec[UInt8].new();
  crlf.push(49 as UInt8);
  crlf.push(48 as UInt8);
  crlf.push(13 as UInt8);
  crlf.push(10 as UInt8);
  crlf.push(50 as UInt8);
  crlf.push(48 as UInt8);
  crlf.push(13 as UInt8);
  crlf.push(10 as UInt8);
  crlf.push(51 as UInt8);
  crlf.push(48 as UInt8);
  match io.write_file_bytes(path, &crlf) {
    Ok(_) => {},
    Err(_) => { return 9; },
  };
  let lines = io.read_file_lines(path);
  match lines {
    Ok(ls) => {
      if ls.len() < 3 { return 10; }
      let l0 = ls[0];
      if l0 != "10" { return 11; }
      let l1 = ls[1];
      if l1 != "20" { return 12; }
      let l2 = ls[2];
      if l2 != "30" { return 13; }
    },
    Err(_) => { return 14; },
  };

  // 4. LF content with a trailing newline stays clean.
  match io.write_file(path, "a\nb\n") {
    Ok(_) => {},
    Err(_) => { return 15; },
  };
  let lines2 = io.read_file_lines(path);
  match lines2 {
    Ok(ls2) => {
      let a = ls2[0];
      if a != "a" { return 16; }
      let b = ls2[1];
      if b != "b" { return 17; }
    },
    Err(_) => { return 18; },
  };

  io.remove_file(path);
  return 0;
}
