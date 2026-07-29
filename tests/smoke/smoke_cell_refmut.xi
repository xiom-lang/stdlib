module smoke_cell_refmut
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(0);

  var rm = rc.borrow_mut();
  if rm.get() != 0 { return 1; };
  rm.set(100);
  if rm.get() != 100 { return 2; };

  return 0;
}
