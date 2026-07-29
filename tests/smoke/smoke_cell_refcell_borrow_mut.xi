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
