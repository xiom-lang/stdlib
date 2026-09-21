// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_cell_basic
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(42);
  if c.get() != 42 { return 1; }

  c.set(99);
  if c.get() != 99 { return 2; }

  return 0;
}
