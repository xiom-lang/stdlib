module smoke_iter_range
use xiom.iter;

fn main() -> Int {
  if iter.range(0, 0).sum() != 0 { return 1; }
  if iter.range(1, 5).sum() != 10 { return 2; }
  if iter.range(0, 10).sum() != 45 { return 3; }

  if iter.range(0, 0).product() != 1 { return 4; }
  if iter.range(1, 5).product() != 24 { return 5; }

  if !iter.range(1, 5).contains(3) { return 6; }
  if iter.range(1, 5).contains(0) { return 7; }
  if iter.range(1, 5).contains(5) { return 8; }

  return 0;
}
