// XIOM stdlib smoke test -- xiom.core
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_core
use xiom.core;

fn main() -> Int {
  var a = [1, 2, 3, 4, 5];
  var b = [1, 2, 3, 4, 5];
  if core.is_sorted(a) && core.contains(b, 3) {
    return 0;
  }
  return 1;
}
