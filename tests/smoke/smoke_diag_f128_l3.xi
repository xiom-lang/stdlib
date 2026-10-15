// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L3 (witness branch only): + subtf3 (same-sign operands).
module smoke_diag_f128_l3
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  var n64 = n as Float64;
  var a: Float128 = n64 as Float128;
  var h: Float128 = 0.5 as Float128;
  var d = a - h;
  if d as Float64 != n64 - 0.5 { return 1; }
  return 0;
}
