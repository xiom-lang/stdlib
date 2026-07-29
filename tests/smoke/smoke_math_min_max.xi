module smoke_math_min_max
use xiom.math;

fn main() -> Int {
  if math.min_int(3, 9) != 3 { return 1; }
  if math.min_int(9, 3) != 3 { return 2; }
  if math.min_int(5, 5) != 5 { return 3; }
  if math.min_int(-5, 5) != -5 { return 4; }
  if math.min_int(0, 0) != 0 { return 5; }

  if math.max_int(3, 9) != 9 { return 6; }
  if math.max_int(9, 3) != 9 { return 7; }
  if math.max_int(5, 5) != 5 { return 8; }
  if math.max_int(-5, 5) != 5 { return 9; }
  if math.max_int(-5, -1) != -1 { return 10; }

  return 0;
}
