module smoke_cell_ref_get
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new("borrow");

  var r = rc.borrow();
  if r.get() != "borrow" { return 1; }

  var rm = rc.borrow_mut();
  if rm.get() != "borrow" { return 2; }

  return 0;
}
