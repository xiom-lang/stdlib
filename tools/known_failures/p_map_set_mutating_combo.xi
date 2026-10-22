// Known failure (v0.64.8): multiple mutating generic Map/Set helpers in one
// program AV 0xC0000005. Fixed on compiler main at 9b6b3b59f (m376); verified
// on the 2026-10-22 debug build: rc 0. Expected on v0.64.8: AV / rc != 0.
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module p_map_set_mutating_combo

use xiom.collections;
use xiom.io;

fn main() -> Int {
  var m = Map[Int, Int].new();
  let k = 1;
  let a = map_get_or(&m, &k, 0);
  let b = map_insert_if_absent(&mut m, 2, 2);
  if a != 0 { io.println("a=" + a.to_str()); return 1; }
  if b != true { return 2; }
  if m.len() != 1 { return 3; }

  var s = Set[Int].new();
  let c = set_contains(&s, &1);
  set_insert(&mut s, 2);
  if c != false { return 4; }
  if s.len() != 1 { return 5; }
  io.println("map/set combo ok");
  return 0;
}
