// Known failure (v0.64.8 and main before d04cd3265): tuple-returning fn
// through EnumerateIter.map yields pointer-like tuple payloads
// (REL-20261020-1550 / REL-20261022-1152).
//
// With the stdlib EnumerateIter[Int].map specialization applied and compiler
// d04cd3265, the expected result is em = [(0,10),(1,12),(2,14)], rc 0.
// On v0.64.8: em[1].0 reads 0 and the second values are pointer-like, rc 3.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_iter_enumerate_tuple

use xiom.iter;
use xiom.io;

fn idx_plus(p: (Int, Int)) -> (Int, Int) {
  return (p.0, p.1 + p.0);
}

fn main() -> Int {
  var em = iter.range(10, 13).enumerate().map(idx_plus).collect();
  if em.len() != 3 { io.println("len=" + em.len().to_str()); return 1; }
  if em[0].0 != 0 { io.println("i0=" + em[0].0.to_str()); return 2; }
  if em[1].0 != 1 { io.println("i1=" + em[1].0.to_str()); return 3; }
  if em[2].0 != 2 { io.println("i2=" + em[2].0.to_str()); return 4; }
  if em[0].1 != 10 { io.println("v0=" + em[0].1.to_str()); return 5; }
  if em[1].1 != 12 { io.println("v1=" + em[1].1.to_str()); return 6; }
  if em[2].1 != 14 { io.println("v2=" + em[2].1.to_str()); return 7; }
  io.println("enumerate tuple ok");
  return 0;
}
