// p_wave65_shapes.xi -- wave 65 Range-core API lock (no clauses landed)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Wave 65's iter clause sets were reverted: on the v0.62.3 pin, clauses
// in xiom.iter make iter-consuming smokes flip between closure
// use-before-def and the C001 contains-classifier error, and calling
// Range.collect() fails clang ("instruction forward referenced with type
// 'ptr'"). This probe stays as a behavioral lock for the non-closure
// Range core API (constructors, len/contains/sum/product); the
// closure-delegating methods are deliberately not called here. No
// network or socket I/O; 13 checks; returns 0 when every case holds.

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
