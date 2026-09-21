// XIOM stdlib stress -- Vec sort with duplicates
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Pushes values with duplicates, sorts, verifies stability.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_vec_sort_dups
use xiom.collections;

fn main() -> Int {
  var v = Vec[Int].new();
  v.push(3);
  v.push(1);
  v.push(3);
  v.push(2);
  v.push(1);
  v.sort();
  if v[0] != 1 { return 1; }
  if v[1] != 1 { return 2; }
  if v[2] != 2 { return 3; }
  if v[3] != 3 { return 4; }
  if v[4] != 3 { return 5; }
  return 0;
}
