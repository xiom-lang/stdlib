module smoke_cell_refcell_borrow
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(100);

  var r1 = rc.borrow();
  if r1.get() != 100 { return 1; }

  var r2 = rc.borrow();
  if r2.get() != 100 { return 2; }

  return 0;
}
