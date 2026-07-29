module smoke_iter_range_inclusive
use xiom.iter;

fn main() -> Int {
  var ri = iter.range_inclusive(1, 3);
  match ri.next() {
    Some(v) => { if v != 1 { return 1; } },
    None => { return 2; },
  };
  match ri.next() {
    Some(v) => { if v != 2 { return 3; } },
    None => { return 4; },
  };
  match ri.next() {
    Some(v) => { if v != 3 { return 5; } },
    None => { return 6; },
  };
  match ri.next() {
    Some(_) => { return 7; },
    None => {},
  };

  return 0;
}
