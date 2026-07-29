module smoke_cmp_edge
use xiom.cmp;

fn main() -> Int {
  if cmp.clamp(0, 10, 20) != 10 { return 1; }
  if cmp.clamp(30, 10, 20) != 20 { return 2; }
  if cmp.clamp(15, 15, 15) != 15 { return 3; }
  if cmp.clamp(-100, -50, 0) != -50 { return 4; }

  if cmp.max_int(-2147483647, 2147483647) != 2147483647 { return 5; }
  if cmp.min_int(-2147483647, 2147483647) != -2147483647 { return 6; }

  return 0;
}
