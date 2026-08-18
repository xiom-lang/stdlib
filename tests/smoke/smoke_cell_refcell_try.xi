module smoke_cell_refcell_try
use xiom.cell;

fn main() -> Int {
  var rc = cell.RefCell.new(0);

  match rc.try_borrow() {
    Some(r) => {
      if r.get() != 0 { return 1; }
      r.release();
    },
    None => { return 2; },
  };

  match rc.try_borrow_mut() {
    Some(rm) => {
      if rm.get() != 0 { return 3; }
      rm.release();
    },
    None => { return 4; },
  };

  match rc.try_borrow() {
    Some(r) => {
      if r.get() != 0 { return 5; }
      r.release();
    },
    None => { return 6; },
  };

  // double borrow must fail while a guard is live
  match rc.try_borrow() {
    Some(r) => {
      match rc.try_borrow_mut() {
        Some(_) => { return 7; },
        None => {},
      };
      r.release();
    },
    None => { return 8; },
  };

  return 0;
}
