module smoke_iter_count
use xiom.iter;

fn main() -> Int {
  if iter.range(1, 11).count() != 10 { return 1; }
  if iter.range(0, 0).count() != 0 { return 2; }
  if iter.range(-5, 5).count() != 10 { return 3; }

  return 0;
}
