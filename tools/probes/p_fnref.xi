// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module p_fnref
use xiom.io;
fn main() -> Int {
  var f = io.read_int;
  var g = io.read_float;
  if f == g { return 1; }
  return 0;
}
