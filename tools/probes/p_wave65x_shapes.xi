// p_wave65x_shapes.xi -- wave 65x shape validation: convert shims
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-65x clauses on xiom.convert.{bytes (6), endian (6),
// checked (9), base64 (4), exact (3), swap (3), tostring (5), wrapping (7)}
// = 43 clauses. bytes.from_bytes is compile-checked only: the module header
// documents that CALLING it produces invalid LLVM IR (compiler builtin name
// collision), so the probe stays away. No network or socket I/O; 60 checks;
// returns 0 when every case holds.

module p_wave65x_shapes

use xiom.convert.bytes;
use xiom.convert.endian;
use xiom.convert.checked;
use xiom.convert.base64;
use xiom.convert.exact;
use xiom.convert.swap;
use xiom.convert.tostring;
use xiom.convert.wrapping;
use xiom.core.INT_MIN;
use xiom.string;

fn _bytes(s: Str) -> Vec[UInt8] {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < s.len() {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn main() -> Int {
  var empty = Vec[UInt8].new();
  var abc = _bytes("abc");
  var ab = _bytes("ab");
  var nine = Vec[UInt8].new();
  var k = 0;
  while k < 9 {
    nine.push(0 as UInt8);
    k = k + 1;
  }

  // ---- bytes
  if bytes.to_bytes(0).len() != 8 { return 1; }
  if bytes.to_bytes(0 - 1).len() != 8 { return 2; }
  if bytes.bytes_to_hex(&empty).len() != 0 { return 3; }
  if !bytes.hex_to_bytes("").is_ok { return 5; }
  if !bytes.hex_to_bytes("ab").is_ok { return 6; }
  if bytes.bytes_concat(&abc, &ab).len() != 5 { return 7; }
  if bytes.bytes_reverse(&abc).len() != 3 { return 8; }

  // ---- endian
  if endian.to_be_bytes(1).len() != 8 { return 9; }
  if endian.to_le_bytes(1).len() != 8 { return 10; }
  if endian.from_be_bytes(&empty) != 0 { return 11; }
  if endian.from_be_bytes(&nine) != 0 { return 12; }
  if endian.from_le_bytes(&empty) != 0 { return 13; }
  if endian.swap_bytes(0) != 0 { return 14; }
  if !endian.is_little_endian() { return 15; }

  // ---- checked
  if checked.checked_add(1, 0).is_none { return 16; }
  if checked.checked_sub(1, 0).is_none { return 17; }
  if checked.checked_mul(5, 0).is_none { return 18; }
  if checked.checked_mul(5, 1).is_none { return 19; }
  if checked.checked_div(1, 0).is_some { return 20; }
  if checked.checked_neg(INT_MIN).is_some { return 21; }
  if checked.checked_neg(5).is_none { return 22; }
  if checked.checked_abs(INT_MIN).is_some { return 23; }
  if checked.checked_abs(0 - 5).is_none { return 24; }
  if checked.checked_pow(2, 0 - 1).is_some { return 25; }
  if checked.checked_pow(5, 0).is_none { return 26; }
  if checked.checked_shl(1, 0 - 1).is_some { return 27; }
  if checked.checked_shl(1, 64).is_some { return 28; }
  if checked.checked_shl(1, 0).is_none { return 29; }
  if checked.checked_shr(1, 64).is_some { return 30; }
  if checked.checked_shr(4, 1).is_none { return 31; }

  // ---- base64
  if base64.base64_encode(&empty).len() != 0 { return 32; }
  if !base64.base64_decode("").is_ok { return 33; }
  if base64.base64_encode_str("").len() != 0 { return 34; }
  if !base64.base64_decode_str("").is_ok { return 35; }
  if base64.base64_encode(&abc).len() != 4 { return 36; }

  // ---- exact
  if !exact.exact_div(1, 0).is_err { return 37; }
  if !exact.exact_div(6, 3).is_ok { return 38; }
  if exact.exact_float(1.0, 0.0).is_some { return 39; }
  if exact.exact_float(6.0, 3.0).is_none { return 40; }
  if exact.exact_ratio(1, 0).is_some { return 41; }
  if exact.exact_ratio(4, 2).is_none { return 42; }

  // ---- swap
  if swap.swap16(0) != 0 { return 43; }
  if swap.swap32(0) != 0 { return 44; }
  if swap.swap64(0) != 0 { return 45; }

  // ---- tostring
  if !(tostring.to_string(0) == "0") { return 46; }
  if tostring.to_string_float(0.0).len() == 0 { return 47; }
  if !(tostring.to_string_bool(true) == "true") { return 48; }
  if !(tostring.to_string_bool(false) == "false") { return 49; }
  if tostring.to_string_char('A').len() < 1 { return 50; }
  if tostring.to_string_radix(10, 2).len() == 0 { return 51; }
  if tostring.to_string_radix(10, 1).len() != 0 { return 52; }
  if tostring.to_string_radix(10, 37).len() != 0 { return 53; }

  // ---- wrapping
  if wrapping.wrapping_add(1, 0) != 1 { return 54; }
  if wrapping.wrapping_sub(1, 0) != 1 { return 55; }
  if wrapping.wrapping_mul(5, 1) != 5 { return 56; }
  if wrapping.wrapping_neg(0) != 0 { return 57; }
  if wrapping.wrapping_abs(0) != 0 { return 58; }
  if wrapping.wrapping_abs(7) != 7 { return 59; }
  if wrapping.wrapping_shl(3, 0) != 3 { return 60; }
  if wrapping.wrapping_shr(8, 0) != 8 { return 61; }

  return 0;
}
