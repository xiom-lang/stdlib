module smoke_num_saturating
use xiom.num;

fn main() -> Int {
  if num.saturating_add(100, 50) != 150 { return 1; }
  if num.saturating_add(0, 0) != 0 { return 2; }

  if num.saturating_sub(100, 30) != 70 { return 3; }
  if num.saturating_sub(0, 0) != 0 { return 4; }

  if num.saturating_mul(10, 10) != 100 { return 5; }
  if num.saturating_mul(5, 0) != 0 { return 6; }
  if num.saturating_mul(0, 5) != 0 { return 7; }

  return 0;
}
