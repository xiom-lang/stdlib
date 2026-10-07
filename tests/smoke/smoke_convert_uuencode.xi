// Smoke: UU/XX encoding roundtrips (locks the trailing-space fix)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks xiom.convert.uuencode: trailing spaces are significant UU data
// (value 0 encodes as ' '), so `_trim` must strip only CR/LF. Regression
// cover: one-byte payloads (final group ends in zero bytes -> trailing
// spaces), 45-byte single-line, multi-line > 45 bytes, and XX parity.

module smoke_convert_uuencode

use xiom.convert.uuencode as cuu;

fn _pattern(n: Int, seed: Int) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < n {
    v.push(((i * 7 + seed) % 251) as UInt8);
    i = i + 1;
  }
  return v;
}

fn _roundtrip(data: &Vec[UInt8]) -> Int {
  let enc = cuu.uuencode(data);
  match cuu.uudecode(enc) {
    Ok(v) => {
      if v.len() != data.len() { return 1; }
      var i = 0;
      while i < data.len() {
        if v[i] != data[i] { return 2; }
        i = i + 1;
      }
      return 0;
    },
    Err(_) => { return 3; },
  }
}

fn main() -> Int {
  // ---- empty paths
  var be = Vec[UInt8].new();
  if cuu.uuencode(&be) != "" { return 1; }
  if !cuu.uudecode("").is_ok { return 2; }
  if cuu.uuencode_line(&be) != " " { return 3; }

  // ---- one byte (final group is all zero -> trailing spaces in the line)
  var b1 = Vec[UInt8].new();
  b1.push(65u8);
  let r1 = _roundtrip(&b1);
  if r1 != 0 { return 10 + r1; }

  // ---- three bytes
  var b3 = Vec[UInt8].new();
  b3.push(65u8);
  b3.push(66u8);
  b3.push(67u8);
  let r3 = _roundtrip(&b3);
  if r3 != 0 { return 20 + r3; }

  // ---- 45 bytes (single full line)
  var d45 = _pattern(45, 1);
  let r45 = _roundtrip(&d45);
  if r45 != 0 { return 30 + r45; }

  // ---- 100 bytes (three lines)
  var d100 = _pattern(100, 7);
  let r100 = _roundtrip(&d100);
  if r100 != 0 { return 40 + r100; }

  // ---- xxencode parity
  let xenc = cuu.xxencode(&d100);
  match cuu.xxdecode(xenc) {
    Ok(xv) => { if xv.len() != 100 { return 51; } }
    Err(_) => { return 52; },
  }

  return 0;
}
