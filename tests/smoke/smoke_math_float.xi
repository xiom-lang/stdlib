module smoke_math_float
use xiom.math;

fn main() -> Int {
  if math.abs_float(0.0) != 0.0 { return 1; }
  if math.abs_float(3.14) != 3.14 { return 2; }
  if math.abs_float(-3.14) != 3.14 { return 3; }

  if math.min_float(1.0, 2.0) != 1.0 { return 4; }
  if math.min_float(2.0, 1.0) != 1.0 { return 5; }

  if math.max_float(1.0, 2.0) != 2.0 { return 6; }
  if math.max_float(2.0, 1.0) != 2.0 { return 7; }

  return 0;
}
