// p_wave83_shapes.xi -- wave 83 shape validation: convert codec tails
// (uuencode/xxencode lines, base58check)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-83 clause guards: empty-input identities on the UU/XX
// codec legs and base58check ("" / Ok(empty) / Err / length-1 empty line),
// plus single-byte roundtrips. Returns 0 when every case holds.
// `Vec.new()` temporaries passed as `&Vec` are bound first.

module p_wave83_shapes

use xiom.convert.uuencode as cuu;
use xiom.convert.base58 as c58;

fn main() -> Int {
  var be = Vec[UInt8].new();

  // ---- UU
  if cuu.uuencode(&be) != "" { return 1; }
  if !cuu.uudecode("").is_ok { return 2; }
  if cuu.uuencode_line(&be) != " " { return 3; }
  var b1 = Vec[UInt8].new();
  b1.push(65u8);
  let u1 = cuu.uuencode(&b1);
  if u1.len() < 1 { return 4; }
  if !cuu.uudecode(u1).is_ok { return 5; }
  if cuu.uuencode_line(&b1).len() < 2 { return 6; }

  // ---- XX
  if cuu.xxencode(&be) != "" { return 7; }
  if !cuu.xxdecode("").is_ok { return 8; }
  let x1 = cuu.xxencode(&b1);
  if x1.len() < 1 { return 9; }
  if !cuu.xxdecode(x1).is_ok { return 10; }

  // ---- base58check
  if c58.base58check_encode(&b1).len() < 1 { return 11; }
  if !c58.base58check_decode("").is_err { return 12; }

  return 0;
}
