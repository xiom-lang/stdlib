// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
module smoke_cell_refcell_borrow_mut
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(50);

  var rm = rc.borrow_mut();
  if rm.get() != 50 { return 1; }
  rm.set(75);
  if rm.get() != 75 { return 2; }

  return 0;
}
