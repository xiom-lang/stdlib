module smoke_iter_nth_last
use xiom.iter;

fn main() -> Int {
  match iter.range(0, 100).nth(50) {
    Some(v) => { if v != 50 { return 1; } },
    None => { return 2; },
  };
  match iter.range(0, 5).nth(10) {
    Some(_) => { return 3; },
    None => {},
  };

  match iter.range(1, 6).last() {
    Some(v) => { if v != 5 { return 4; } },
    None => { return 5; },
  };
  match iter.range(1, 1).last() {
    Some(_) => { return 6; },
    None => {},
  };

  return 0;
}
