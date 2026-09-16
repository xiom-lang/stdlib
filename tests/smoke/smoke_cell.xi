// XIOM stdlib smoke test -- xiom.cell
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0
// Returns 0 on success, nonzero on failure (process exit code).

module smoke_cell
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(42);
  if c.get() == 42 {
    c.set(99);
    if c.get() == 99 {
      return 0;
    }
  }
  return 1;
}
