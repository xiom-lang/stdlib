module smoke_cmp_int
use xiom.cmp;

fn main() -> Int {
  if cmp.max_int(3, 9) != 9 { return 1; }
  if cmp.max_int(9, 3) != 9 { return 2; }
  if cmp.max_int(-5, 5) != 5 { return 3; }

  if cmp.min_int(3, 9) != 3 { return 4; }
  if cmp.min_int(9, 3) != 3 { return 5; }
  if cmp.min_int(-5, 5) != -5 { return 6; }

  if cmp.clamp_int(5, 1, 10) != 5 { return 7; }
  if cmp.clamp_int(0, 1, 10) != 1 { return 8; }
  if cmp.clamp_int(20, 1, 10) != 10 { return 9; }

  return 0;
}
