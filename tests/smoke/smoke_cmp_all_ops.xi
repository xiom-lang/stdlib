module smoke_cmp_all_ops
use xiom.cmp;

fn main() -> Int {
  if cmp.min(cmp.max(1, 5), 3) != 3 { return 1; }
  if cmp.max(cmp.min(1, 5), 3) != 3 { return 2; }
  if cmp.clamp(15, cmp.min(10, 20), cmp.max(10, 20)) != 15 { return 3; }
  if cmp.clamp(5, 10, 20) != 10 { return 4; }
  if cmp.clamp(25, 10, 20) != 20 { return 5; }

  return 0;
}
