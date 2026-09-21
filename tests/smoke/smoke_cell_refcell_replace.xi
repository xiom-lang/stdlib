// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_cell_refcell_replace
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(10);
  var old = rc.replace(20);
  if old != 10 { return 1; }

  var r = rc.borrow();
  if r.get() != 20 { return 2; }

  return 0;
}
