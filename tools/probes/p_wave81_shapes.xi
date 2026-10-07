// p_wave81_shapes.xi -- wave 81 shape validation: convert unicode family
// (utf8, utf16, utf32, utf)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-81 clause guards: empty-input identities, BOM-only
// byte lengths (2 for UTF-16, 4 for UTF-32), odd-length Err guards, decode
// roundtrips, surrogate-pair arithmetic and the validity predicates.
// Returns 0 when every case holds. `Vec.new()` temporaries passed as `&Vec`
// are bound first; char values arrive via `as Char` casts (no
// char.to_int_from_char).

module p_wave81_shapes

use xiom.convert.utf8 as c8;
use xiom.convert.utf16 as c16;
use xiom.convert.utf32 as c32;
use xiom.convert.utf as cu;

fn main() -> Int {
  // ---- utf8
  let one = c8.utf8_encode((65 as Char));
  if one.len() != 1 { return 1; }
  var b1 = Vec[UInt8].new();
  b1.push(65u8);
  if !c8.utf8_decode(&b1).is_some { return 2; }
  var be = Vec[UInt8].new();
  if !c8.utf8_decode(&be).is_none { return 3; }
  if !c8.utf8_validate("hello") { return 4; }
  if !c8.utf8_validate("") { return 5; }
  if c8.utf8_valid_sequences("") != 0 { return 6; }
  if c8.utf8_valid_sequences("abc") != 3 { return 7; }

  // ---- utf16 module
  if c16.utf16_encode("").len() != 0 { return 8; }
  var ue = Vec[UInt16].new();
  if !c16.utf16_decode(&ue).is_ok { return 9; }
  if c16.utf16le_to_bytes("").len() != 2 { return 10; }
  if c16.utf16be_to_bytes("").len() != 2 { return 11; }
  var bere = Vec[UInt8].new();
  if !cu.utf16_decode_le(&bere).is_ok { return 12; }
  var bodd = Vec[UInt8].new();
  bodd.push(1u8);
  if !cu.utf16_decode_le(&bodd).is_err { return 13; }
  if !cu.utf16_decode_be(&bodd).is_err { return 14; }

  // ---- utf32 module
  if c32.utf32_encode("").len() != 0 { return 15; }
  var ce = Vec[UInt32].new();
  if !c32.utf32_decode(&ce).is_ok { return 16; }
  if c32.utf32le_to_bytes("").len() != 4 { return 17; }
  if c32.utf32be_to_bytes("").len() != 4 { return 18; }
  if c32.utf32le_to_bytes("A").len() % 4 != 0 { return 19; }

  // ---- utf module (roundtrips)
  let u1 = cu.utf16_encode("A");
  if u1.len() != 1 { return 20; }
  if !cu.utf16_decode(&u1).is_ok { return 21; }
  let lb = cu.utf16le_to_bytes("A");
  if lb.len() != 4 { return 22; }
  if lb.len() % 2 != 0 { return 23; }
  if !cu.utf16_decode_le(&lb).is_ok { return 24; }
  let bb = cu.utf16be_to_bytes("A");
  if !cu.utf16_decode_be(&bb).is_ok { return 25; }
  let p1 = cu.utf32_encode("A");
  if p1.len() != 1 { return 26; }
  if !cu.utf32_decode(&p1).is_ok { return 27; }
  if cu.utf32le_to_bytes("A").len() != 8 { return 28; }
  if cu.utf32be_to_bytes("A").len() % 4 != 0 { return 29; }
  if !cu.utf16_is_valid("") { return 30; }
  if !cu.utf32_is_valid("") { return 31; }
  let p0 = cu.code_point_to_utf16(65);
  if (p0.0 as Int) != 0 || (p0.1 as Int) != 0 { return 32; }
  let p2 = cu.code_point_to_utf16(65600);
  if (p2.0 as Int) != 0xD800 { return 33; }
  if (p2.1 as Int) != 0xDC40 { return 34; }
  if cu.surrogate_pair_to_code_point((0 as UInt16), (0 as UInt16)) != -1 { return 35; }
  if cu.surrogate_pair_to_code_point((0xD800 as UInt16), (0xDC00 as UInt16)) != 0x10000 { return 36; }

  return 0;
}
