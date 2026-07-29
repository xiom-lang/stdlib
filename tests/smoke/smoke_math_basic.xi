module smoke_math_basic
use xiom.math;

fn main() -> Int {
  if math.abs_int(0) != 0 { return 1; }
  if math.abs_int(42) != 42 { return 2; }
  if math.abs_int(-42) != 42 { return 3; }
  if math.abs_int(-1) != 1 { return 4; }
  if math.abs_int(1) != 1 { return 5; }

  return 0;
}
