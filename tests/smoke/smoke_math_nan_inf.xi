module smoke_math_nan_inf
use xiom.math;

fn main() -> Int {
  if !math.is_nan(0.0 / 0.0) { return 1; }
  if math.is_nan(1.0) { return 2; }
  if math.is_nan(0.0) { return 3; }

  if !math.is_inf(1.0 / 0.0) { return 4; }
  if math.is_inf(1.0) { return 5; }

  return 0;
}
