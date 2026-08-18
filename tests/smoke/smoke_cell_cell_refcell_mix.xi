module smoke_cell_cell_refcell_mix
use xiom.cell;

fn main() -> Int {
  var c = cell.Cell.new(1);
  var old = c.replace(2);
  if old != 1 { return 1; }
  if c.get() != 2 { return 2; }

  var rc = cell.RefCell.new(10);
  match rc.try_borrow() {
    Some(r) => {
      if r.get() != 10 { return 3; }
      r.release();
    },
    None => { return 4; },
  };
  match rc.try_borrow_mut() {
    Some(rm) => {
      rm.set(20);
      rm.release();
    },
    None => { return 5; },
  };
  var old2 = rc.replace(30);
  if old2 != 20 { return 6; }

  return 0;
}
