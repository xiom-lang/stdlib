// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module q1_vec
use xiom.collections;
fn main() -> Int {
  var v = Vec[Int].new();
  v.push(1);
  v.push(2);
  if v.len() != 2 { return 1; }
  return 0;
}
