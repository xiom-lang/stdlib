module smoke_cell_refcell_basic
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(42);

  var r = rc.borrow();
  if r.get() != 42 { return 1; }

  var rm = rc.borrow_mut();
  if rm.get() != 42 { return 2; }

  return 0;
}
