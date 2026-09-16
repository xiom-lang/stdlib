// NOTE: link/run smoke only
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// XIOM stdlib smoke test -- xiom.os
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_os
use xiom.os;

fn main() -> Int {
  var c = os.cpu_count();
  if c > 0 {
    return 0;
  }
  return 1;
}
