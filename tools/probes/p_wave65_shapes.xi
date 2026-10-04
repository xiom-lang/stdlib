// p_wave65_shapes.xi -- wave 65 shape validation: xiom.iter Range core
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Exercises the wave-65 landed clauses: xiom.iter range/range_inclusive
// constructors and Range.len/contains/sum/product (6 runtime-exercised);
// the Range.collect clause is declared but kept out of this probe because
// CALLING Range.collect from a user program trips the same closure codegen
// bug ("instruction forward referenced with type 'ptr'") on this pin. The
// closure-delegating methods (next/count/find/max/min/nth/last/all/any/
// enumerate/take/skip) are clause-free and likewise not called.
// No network or socket I/O; 13 checks; returns 0 when every case holds.

module p_wave65_shapes

use xiom.iter;

fn main() -> Int {
  let r = iter.range(2, 5);
  if r.start != 2 || r.end != 5 { return 1; }
  if r.len() != 3 { return 2; }
  if !r.contains(2) { return 3; }
  if r.contains(5) { return 4; }
  if r.sum() != 9 { return 5; }
  if r.product() != 24 { return 6; }
  let r0 = iter.range(5, 2);
  if r0.len() != 0 { return 7; }
  if r0.sum() != 0 { return 8; }
  if r0.product() != 1 { return 9; }
  let ri = iter.range_inclusive(1, 3);
  if ri.start != 1 || ri.end != 3 || ri.current != 1 || ri.done { return 10; }
  if r.len() != 3 { return 11; }
  if r0.len() != 0 { return 12; }
  if !r.contains(3) { return 13; }

  return 0;
}
