// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_rand_stress
use xiom.rand;

fn main() -> Int {
  var i: Int = 0;
  while i < 100 {
    var r = rand.random();
    if r < 0.0 || r >= 1.0 { return 1; }
    i = i + 1;
  }
  return 0;
}
