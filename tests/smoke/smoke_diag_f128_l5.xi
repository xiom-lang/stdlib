// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L5 (witness branch only): + divtf3 and the 0.0-a fast path.
module smoke_diag_f128_l5
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  var n64 = n as Float64;
  var a: Float128 = n64 as Float128;
  var q = a / 2.0 as Float128;
  if q as Float64 != n64 / 2.0 { return 1; }
  var zero: Float128 = 0.0 as Float128;
  if zero - a + a != zero { return 2; }
  return 0;
}
