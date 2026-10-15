// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L2 (witness branch only): + addtf3.
module smoke_diag_f128_l2
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  var n64 = n as Float64;
  var a: Float128 = n64 as Float128;
  var s = a + a;
  if s as Float64 != n64 * 2.0 { return 1; }
  return 0;
}
