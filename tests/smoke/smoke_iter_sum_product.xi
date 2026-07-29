module smoke_iter_sum_product
use xiom.iter;

fn main() -> Int {
  if iter.range(1, 4).sum() != 6 { return 1; }
  if iter.range(1, 1).sum() != 0 { return 2; }

  if iter.range(1, 5).product() != 24 { return 3; }
  if iter.range(1, 1).product() != 1 { return 4; }

  return 0;
}
