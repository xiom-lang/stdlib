// XIOM stdlib stress -- Map keys and values
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Verifies keys() and values() return correct collections.
// Returns 0 on success, nonzero on failure.

module smoke_stress_collections_map_keys_values
use xiom.collections;

fn main() -> Int {
  var m = Map[Int, Str].new();
  m.insert(1, "a");
  m.insert(2, "b");
  m.insert(3, "c");
  var ks = m.keys();
  if ks.len() != 3 { return 1; }
  var vs = m.values();
  if vs.len() != 3 { return 2; }
  return 0;
}
