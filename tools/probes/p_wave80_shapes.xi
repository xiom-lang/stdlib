// p_wave80_shapes.xi -- wave 80 shape validation: convert base-codec shims
// (base16, base32, base64url, percent, base58/base62 legs, uuencode length,
// quoted-printable helpers)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-80 clause guards: canonical length identities through
// the shims, empty-string Ok/""/Err paths, odd/invalid hex guards, the
// base64url modulo-3 length trio, percent bands, the base58 zero/INT_MIN
// pins, base62 zero, uu_encoded_length block math and the QP helpers.
// Returns 0 when every case holds. `Vec.new()` temporaries passed as `&Vec`
// are bound first; no char casts, no odd-length hex through text_to_binary.

module p_wave80_shapes

use xiom.convert.base16 as c16;
use xiom.convert.base32 as c32;
use xiom.convert.base64url as c64u;
use xiom.convert.percent as cpct;
use xiom.convert.base58 as c58;
use xiom.convert.base62 as c62;
use xiom.convert.uuencode as cuu;
use xiom.convert.quotedprintable as cqp;
use xiom.core.INT_MIN;

fn main() -> Int {
  var b3 = Vec[UInt8].new();
  b3.push(1u8);
  b3.push(2u8);
  b3.push(3u8);
  var b1 = Vec[UInt8].new();
  b1.push(65u8);
  var bempty = Vec[UInt8].new();

  // ---- base16
  if c16.hex_encode(&b3).len() != 6 { return 1; }
  if c16.hex_encode(&bempty).len() != 0 { return 2; }
  if !c16.hex_decode("abcd").is_ok { return 3; }
  if !c16.hex_decode("abc").is_err { return 4; }
  if c16.hex_encode_str("").len() != 0 { return 5; }
  if c16.hex_encode_str("ab").len() != 4 { return 6; }
  if !c16.hex_decode_str("6162").is_ok { return 7; }
  if !c16.hex_decode_str("abc").is_err { return 8; }

  // ---- base32
  if c32.base32_encode(&b3).len() != 8 { return 9; }
  if c32.base32_encode(&bempty).len() != 0 { return 10; }
  let enc32 = c32.base32_encode(&b3);
  match c32.base32_decode(enc32) {
    Ok(d) => { if d.len() != 3 { return 11; } }
    Err(_) => { return 12; }
  }
  if !c32.base32_decode("").is_ok { return 13; }
  if c32.base32hex_encode(&b3).len() != 8 { return 14; }
  if !c32.base32hex_decode("").is_ok { return 15; }

  // ---- base64url
  if c64u.base64url_encode(&bempty).len() != 0 { return 16; }
  if c64u.base64url_encode(&b3).len() != 4 { return 17; }
  if c64u.base64url_encode(&b1).len() != 2 { return 18; }
  if !c64u.base64url_decode("").is_ok { return 19; }
  let enc64 = c64u.base64url_encode(&b3);
  match c64u.base64url_decode(enc64) {
    Ok(d2) => { if d2.len() != 3 { return 20; } }
    Err(_) => { return 21; }
  }
  if c64u.base64url_encode_str("").len() != 0 { return 22; }
  if !c64u.base64url_decode_str("").is_ok { return 23; }

  // ---- percent
  let pe = cpct.percent_encode("ab");
  if pe.len() < 2 || pe.len() > 6 { return 24; }
  let pec = cpct.percent_encode_component("a b");
  if pec.len() < 3 || pec.len() > 9 { return 25; }
  if !cpct.percent_decode("").is_ok { return 26; }
  if !cpct.percent_decode("%41").is_ok { return 27; }
  if !cpct.percent_decode_component("a%20b").is_ok { return 28; }

  // ---- base58
  if c58.to_base58(0) != "1" { return 29; }
  if c58.to_base58(INT_MIN) != "-NQm6nKp8qFD" { return 30; }
  if !c58.from_base58("").is_err { return 31; }
  if c58.base58_encode(&bempty) != "" { return 32; }

  // ---- base62
  if c62.to_base62(0) != "0" { return 33; }
  if !c62.from_base62("").is_err { return 34; }
  if c62.base62_encode(&bempty) != "" { return 35; }

  // ---- uuencode length
  if cuu.uu_encoded_length(0) != 0 { return 36; }
  if cuu.uu_encoded_length(-5) != 0 { return 37; }
  if cuu.uu_encoded_length(1) != 61 { return 38; }
  if cuu.uu_encoded_length(45) != 61 { return 39; }
  if cuu.uu_encoded_length(46) != 122 { return 40; }
  if cuu.uu_encoded_length(46) % 61 != 0 { return 41; }

  // ---- quoted-printable helpers
  if cqp.qp_is_binary("") { return 42; }
  if cqp.qp_escape_byte(0u8) != "=00" { return 43; }
  if cqp.qp_escape_byte(255u8) != "=FF" { return 44; }
  if cqp.qp_escape_byte(65u8).len() != 3 { return 45; }

  return 0;
}
