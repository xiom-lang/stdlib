// XIOM stdlib smoke test -- xiom.contracts
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Exercises real coverage/statistics accessors without crashing.
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_contracts
use xiom.contracts;

fn main() -> Int {
  var n = xiom.contracts.total_contracts();
  var pct = xiom.contracts.coverage_percentage();
  if n >= 0 && pct >= 0.0 {
    return 0;
  }
  return 1;
}
