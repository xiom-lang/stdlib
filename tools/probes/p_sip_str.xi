// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_sip_str
use xiom.hash.siphash;
use xiom.io;
fn main() -> Int {
  var d1 = Vec[UInt8].new();
  d1.push(97u8);
  var k0: UInt64 = 0x0706050403020100;
  var k1: UInt64 = 0x0f0e0d0c0b0a0908;
  var via_vec = siphash.siphash24(&d1, k0, k1);
  var via_str = siphash.siphash24_str("a", k0, k1);
  io.println("vec=" + via_vec);
  io.println("str=" + via_str);
  if via_vec != via_str { io.println("MISMATCH"); return 1; }
  var sd1 = siphash.siphash24_str_seeded("same-key");
  var sd2 = siphash.siphash24_str_seeded("same-key");
  io.println("seeded-run=" + sd1);
  if sd1 != sd2 { io.println("SEEDED-NONDET-INPROC"); return 2; }
  var other = siphash.siphash24_str_seeded("other-key");
  if other == sd1 { io.println("COLLISION"); return 3; }
  io.println("OK");
  return 0;
}
