module smoke_cell_refcell_try
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(0);

  match rc.try_borrow() {
    Some(r) => { if r.get() != 0 { return 1; } },
    None => { return 2; },
  };

  match rc.try_borrow_mut() {
    Some(rm) => { if rm.get() != 0 { return 3; } },
    None => { return 4; },
  };

  match rc.try_borrow() {
    Some(r) => { if r.get() != 0 { return 5; } },
    None => { return 6; },
  };

  return 0;
}
