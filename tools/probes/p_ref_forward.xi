// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_ref_forward
use xiom.serialize.endian as sendian;
use xiom.io;

fn rd(v: &Vec[UInt8]) -> Int {
  return sendian.read_u64_be(v, 0) as Int;
}

fn main() -> Int {
  var v = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    v.push((i + 1) as UInt8);
    i = i + 1;
  }
  let r = rd(&v);
  io.println("rd=" + r);
  if r != 0x0102030405060708 { return 1; }

  var out = Vec[UInt8].new();
  sendian.write_u64_le(&mut out, r as UInt64);
  if out.len() != 8 { return 2; }
  if (out[0] as Int) != 8 { return 3; }
  io.println("REF FORWARD OK");
  return 0;
}
