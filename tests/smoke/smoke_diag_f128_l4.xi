// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L4 (witness branch only): + eqtf2 comparison.
module smoke_diag_f128_l4
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  var n64 = n as Float64;
  var a: Float128 = n64 as Float128;
  if a != a { return 1; }
  return 0;
}
