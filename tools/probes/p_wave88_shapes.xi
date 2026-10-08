// p_wave88_shapes.xi -- wave 88 shape validation: serialize batch 1
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-88 clause guards: the endian append-length @pre claims
// and the read OOB-identity guards (LE/BE u16-u64, i64, f64), the varint
// size/zero pins and decode empty-Err guards, the zigzag exact mirrors, the
// uvarint pins, the slice empty identities and the csv empty/append bands.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave88_shapes

use xiom.serialize.endian as endian;
use xiom.serialize.varint as varint;
use xiom.serialize.csv as csv;

fn main() -> Int {
  // ---- endian writes: append lengths (+ content sanity)
  var w16 = Vec[UInt8].new();
  endian.write_u16_le(&mut w16, 0x1234 as UInt16);
  if w16.len() != 2 { return 1; }
  if w16[0] != (0x34 as UInt8) { return 2; }
  if w16[1] != (0x12 as UInt8) { return 3; }

  var w32 = Vec[UInt8].new();
  endian.write_u32_le(&mut w32, 0x12345678 as UInt32);
  if w32.len() != 4 { return 4; }

  var w64 = Vec[UInt8].new();
  endian.write_u64_le(&mut w64, 0x0102030405060708 as UInt64);
  if w64.len() != 8 { return 5; }

  var w16b = Vec[UInt8].new();
  endian.write_u16_be(&mut w16b, 0x1234 as UInt16);
  if w16b.len() != 2 { return 6; }
  if w16b[0] != (0x12 as UInt8) { return 7; }

  var w32b = Vec[UInt8].new();
  endian.write_u32_be(&mut w32b, 0x12345678 as UInt32);
  if w32b.len() != 4 { return 8; }

  var w64b = Vec[UInt8].new();
  endian.write_u64_be(&mut w64b, 0x0102030405060708 as UInt64);
  if w64b.len() != 8 { return 9; }

  var wi = Vec[UInt8].new();
  endian.write_i64_le(&mut wi, 0 - 1);
  if wi.len() != 8 { return 10; }

  var wf = Vec[UInt8].new();
  endian.write_f64_le(&mut wf, 3.5);
  if wf.len() != 8 { return 11; }

  // double-append (append semantics: never overwrite)
  endian.write_u16_le(&mut w16, 0x5678 as UInt16);
  if w16.len() != 4 { return 12; }

  // ---- endian reads: OOB identity + content
  let empty = Vec[UInt8].new();
  let r16e = endian.read_u16_le(&empty, 0);
  if r16e != (0 as UInt16) { return 13; }
  let r32e = endian.read_u32_le(&empty, 0);
  if r32e != (0 as UInt32) { return 14; }
  let r64e = endian.read_u64_le(&empty, 0);
  if r64e != (0 as UInt64) { return 15; }
  let r16be = endian.read_u16_be(&empty, 0);
  if r16be != (0 as UInt16) { return 16; }
  let r32be = endian.read_u32_be(&empty, 0);
  if r32be != (0 as UInt32) { return 17; }
  let r64be = endian.read_u64_be(&empty, 0);
  if r64be != (0 as UInt64) { return 18; }
  let ri64e = endian.read_i64_le(&empty, 0);
  if ri64e != 0 { return 19; }
  let rf64e = endian.read_f64_le(&empty, 0);
  if rf64e != 0.0 { return 20; }
  let rneg = endian.read_u16_le(&w16, 0 - 1);
  if rneg != (0 as UInt16) { return 21; }

  let l16 = endian.read_u16_le(&w16, 0);
  if l16 != (0x1234 as UInt16) { return 22; }
  let l32 = endian.read_u32_le(&w32, 0);
  if l32 != (0x12345678 as UInt32) { return 23; }
  let l64 = endian.read_u64_le(&w64, 0);
  if l64 != (0x0102030405060708 as UInt64) { return 24; }
  let b16 = endian.read_u16_be(&w16b, 0);
  if b16 != (0x1234 as UInt16) { return 25; }
  let b32 = endian.read_u32_be(&w32b, 0);
  if b32 != (0x12345678 as UInt32) { return 26; }
  let b64 = endian.read_u64_be(&w64b, 0);
  if b64 != (0x0102030405060708 as UInt64) { return 27; }
  let i64v = endian.read_i64_le(&wi, 0);
  if i64v != (0 - 1) { return 28; }
  let f64v = endian.read_f64_le(&wf, 0);
  if f64v != 3.5 { return 29; }

  // ---- varint
  let e0 = varint.varint_encode(0);
  if e0.len() != 1 { return 30; }
  let e300 = varint.varint_encode(300);
  if e300.len() != 2 { return 31; }
  let em1 = varint.varint_encode(0 - 1);
  if em1.len() != 1 { return 32; }
  let s0 = varint.varint_size(0);
  if s0 != 1 { return 33; }
  let s300 = varint.varint_size(300);
  if s300 != 2 { return 34; }
  let sm1 = varint.varint_size(0 - 1);
  if sm1 != 1 { return 35; }
  let dempty = varint.varint_decode(&empty);
  if dempty.is_err == false { return 36; }
  let d300 = varint.varint_decode(&e300);
  match d300 {
    Ok(pair) => {
      if pair.0 != 300 { return 37; }
      if pair.1 != 2 { return 38; }
    },
    Err(_) => { return 39; },
  }
  let z0 = varint.zigzag_encode(0);
  if z0 != 0 { return 40; }
  let zm1 = varint.zigzag_encode(0 - 1);
  if zm1 != 1 { return 41; }
  let z1 = varint.zigzag_encode(1);
  if z1 != 2 { return 42; }
  let zd1 = varint.zigzag_decode(1);
  if zd1 != (0 - 1) { return 43; }
  let zd2 = varint.zigzag_decode(2);
  if zd2 != 1 { return 44; }
  let ue0 = varint.uvarint_encode(0 as UInt64);
  if ue0.len() != 1 { return 45; }
  let ue300 = varint.uvarint_encode(300 as UInt64);
  if ue300.len() != 2 { return 46; }
  let udempty = varint.uvarint_decode(&empty);
  if udempty.is_err == false { return 47; }
  let se = varint.varint_encode_slice(&empty);
  if se.len() != 0 { return 48; }
  var vals = Vec[Int].new();
  vals.push(1);
  vals.push(0 - 2);
  let s2 = varint.varint_encode_slice(&vals);
  if s2.len() < 2 { return 49; }
  let ds = varint.varint_decode_slice(&empty);
  if ds.is_ok == false { return 50; }

  // ---- csv
  let p0 = csv.csv_parse("");
  if p0.is_ok == false { return 51; }
  let p1 = csv.csv_parse("a,b");
  if p1.is_ok == false { return 52; }
  let p2 = csv.csv_parse_with("", 59 as UInt8);
  if p2.is_ok == false { return 53; }
  let fe = Vec[Str].new();
  let wrow = csv.csv_write_row(&fe);
  if wrow != "" { return 54; }
  var f1 = Vec[Str].new();
  f1.push("a");
  let wrow1 = csv.csv_write_row(&f1);
  if wrow1 != "a" { return 55; }
  let rows0 = Vec[Vec[Str]].new();
  let w0 = csv.csv_write(&rows0);
  if w0 != "" { return 56; }
  var r1 = Vec[Vec[Str]].new();
  var frow = Vec[Str].new();
  frow.push("a");
  r1.push(frow);
  let w1 = csv.csv_write(&r1);
  if w1 != "a\r\n" { return 57; }

  return 0;
}
