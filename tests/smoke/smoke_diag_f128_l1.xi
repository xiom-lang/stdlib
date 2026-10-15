// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L1 (witness branch only): extenddftf2 + trunctfdf2.
module smoke_diag_f128_l1
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  var n64 = n as Float64;
  var a: Float128 = n64 as Float128;
  var back = a as Float64;
  if back != n64 { return 1; }
  return 0;
}
