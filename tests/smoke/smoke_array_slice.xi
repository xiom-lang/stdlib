// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_array_slice
use xiom.array;

fn main() -> Int {
  let arr = [1, 2, 3, 4, 5];
  var s = array.as_slice(&arr);
  if s.len() != 5 { return 1; }

  return 0;
}
