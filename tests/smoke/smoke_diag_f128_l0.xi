// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Diagnostic ladder L0 (witness branch only): platform call, no fp128.
module smoke_diag_f128_l0
use xiom.platform;

fn main() -> Int {
  var n = platform.cpu_count();
  if n < 1 { return 2; }
  return 0;
}
