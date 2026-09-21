// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_test
use xiom.test;

fn main() -> Int {
  var r = test.assert(true, "t");
  return 0;
}
