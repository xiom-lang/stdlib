module smoke_iter_max_min
use xiom.iter;

fn main() -> Int {
  match iter.range(1, 6).max() {
    Some(v) => { if v != 5 { return 1; } },
    None => { return 2; },
  };
  match iter.range(1, 6).min() {
    Some(v) => { if v != 1 { return 3; } },
    None => { return 4; },
  };

  match iter.range(0, 0).max() {
    Some(_) => { return 5; },
    None => {},
  };
  match iter.range(0, 0).min() {
    Some(_) => { return 6; },
    None => {},
  };

  return 0;
}
