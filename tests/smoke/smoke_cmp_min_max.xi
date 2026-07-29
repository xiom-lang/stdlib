module smoke_cmp_min_max
use xiom.cmp;

fn main() -> Int {
  if cmp.min(10, 20) != 10 { return 1; }
  if cmp.min(20, 10) != 10 { return 2; }
  if cmp.min(5, 5) != 5 { return 3; }

  if cmp.max(10, 20) != 20 { return 4; }
  if cmp.max(20, 10) != 20 { return 5; }
  if cmp.max(5, 5) != 5 { return 6; }

  return 0;
}
