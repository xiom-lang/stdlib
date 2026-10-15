// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// MD5 RFC 1321 A.5 suite + the canonical fox variants (wave 140,
// REL-20261015-1942-packages): the pre-fix round applied a plain masked
// shift where the algorithm needs a left rotate, so the old len-only
// check passed while every digest was silently wrong.
module smoke_stress_crypto_md5_basic

use xiom.crypto;
use xiom.encoding;
use xiom.string;

fn to_bytes(s: Str) -> Vec[UInt8] {
  var v: Vec[UInt8] = Vec[UInt8].new();
  var i: Int = 0;
  while i < string.str_len(s) {
    v.push(string.byte_at(s, i));
    i = i + 1;
  };
  v
}

fn hex_of(s: Str) -> Str {
  let h = crypto.md5(&to_bytes(s));
  encoding.hex_encode(&h)
}

fn main() -> Int {
  if hex_of("a") != "0cc175b9c0f1b6a831c399e269772661" { return 1; }
  if hex_of("abc") != "900150983cd24fb0d6963f7d28e17f72" { return 2; }
  if hex_of("message digest") != "f96b697d7cb7938d525a2f31aaf161d0" { return 3; }
  if hex_of("abcdefghijklmnopqrstuvwxyz") != "c3fcd3d76192e4007dfb496cca67e13b" { return 4; }
  if hex_of("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") != "d174ab98d277d9f5a5611c2c9f419d9f" { return 5; }
  if hex_of("12345678901234567890123456789012345678901234567890123456789012345678901234567890") != "57edf4a22be3c955ac49da2e2107b67a" { return 6; }
  if hex_of("The quick brown fox jumps over the lazy dog") != "9e107d9d372bb6826bd81d3542a419d6" { return 7; }
  if hex_of("The quick brown fox jumps over the lazy dog.") != "e4d909c290d0fb1ca068ffaddf22cbd0" { return 8; }
  return 0;
}
