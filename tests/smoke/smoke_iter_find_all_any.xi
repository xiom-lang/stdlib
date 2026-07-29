module smoke_iter_find_all_any
use xiom.iter;

fn main() -> Int {
  match iter.range(1, 10).find(fn(x: &Int) -> Bool { return *x > 5; }) {
    Some(v) => { if v != 6 { return 1; } },
    None => { return 2; },
  };
  match iter.range(1, 10).find(fn(x: &Int) -> Bool { return *x > 100; }) {
    Some(_) => { return 3; },
    None => {},
  };

  if !iter.range(1, 6).all(fn(x: &Int) -> Bool { return *x > 0; }) { return 4; }
  if iter.range(1, 6).all(fn(x: &Int) -> Bool { return *x > 3; }) { return 5; }

  if !iter.range(1, 6).any(fn(x: &Int) -> Bool { return *x > 3; }) { return 6; }
  if iter.range(1, 6).any(fn(x: &Int) -> Bool { return *x > 10; }) { return 7; }

  return 0;
}
