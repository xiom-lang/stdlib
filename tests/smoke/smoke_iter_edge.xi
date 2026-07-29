module smoke_iter_edge
use xiom.iter;

fn main() -> Int {
  if iter.range(5, 5).count() != 0 { return 1; }
  if iter.range(0, 1).count() != 1 { return 2; }
  if iter.range(-10, -5).count() != 5 { return 3; }

  match iter.range(5, 1).last() {
    Some(_) => { return 4; },
    None => {},
  };
  if iter.range(5, 1).sum() != 0 { return 5; }

  return 0;
}
