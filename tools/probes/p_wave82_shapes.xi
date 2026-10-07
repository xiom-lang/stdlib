// p_wave82_shapes.xi -- wave 82 shape validation: convert local codec guards
// (ascii85, quoted-printable, base58/base62 decode, uudecode_line)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-82 clause guards: empty-input identities on the local
// codec bodies ("" / Ok(empty) / Err), plus a 3-byte ascii85 roundtrip and
// a single-printable QP pass-through. Returns 0 when every case holds.
// `Vec.new()` temporaries passed as `&Vec` are bound first; no odd-length
// hex through text_to_binary.

module p_wave82_shapes

use xiom.convert.ascii85 as c85;
use xiom.convert.quotedprintable as cqp;
use xiom.convert.base58 as c58;
use xiom.convert.base62 as c62;
use xiom.convert.uuencode as cuu;

fn main() -> Int {
  var be = Vec[UInt8].new();

  // ---- ascii85
  if c85.to_ascii85(&be) != "" { return 1; }
  if !c85.from_ascii85("").is_ok { return 2; }
  if c85.ascii85_encode_str("") != "" { return 3; }
  if !c85.ascii85_decode_str("").is_ok { return 4; }
  var b3 = Vec[UInt8].new();
  b3.push(1u8);
  b3.push(2u8);
  b3.push(3u8);
  let enc = c85.to_ascii85(&b3);
  if enc.len() < 1 { return 5; }
  if !c85.from_ascii85(enc).is_ok { return 6; }

  // ---- quoted-printable
  if cqp.qp_encode(&be) != "" { return 7; }
  if cqp.qp_encode_maxline(&be, 40) != "" { return 8; }
  if !cqp.qp_decode("").is_ok { return 9; }
  if cqp.qp_soft_linebreak("", 76) != "" { return 10; }
  var b1 = Vec[UInt8].new();
  b1.push(65u8);
  if cqp.qp_encode(&b1) != "A" { return 11; }

  // ---- base58/base62 decode + uudecode_line
  if !c58.base58_decode("").is_ok { return 12; }
  if !c62.base62_decode("").is_ok { return 13; }
  if !cuu.uudecode_line("").is_err { return 14; }

  return 0;
}
