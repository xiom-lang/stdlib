// NOTE: link/run smoke only
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// XIOM stdlib smoke test -- xiom.rand
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_rand
use xiom.rand;

fn main() -> Int {
  var r = rand.random();
  if r >= 0.0 && r < 1.0 {
    return 0;
  }
  return 1;
}
