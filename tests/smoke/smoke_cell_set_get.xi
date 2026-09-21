// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_cell_set_get
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new("hello");
  if c.get() != "hello" { return 1; }

  c.set("world");
  if c.get() != "world" { return 2; }

  c.set("world");
  if c.get() != "world" { return 3; }

  return 0;
}
