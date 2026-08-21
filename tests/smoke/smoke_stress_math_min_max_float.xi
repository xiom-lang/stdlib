// XIOM stdlib stress -- math.min_float and math.max_float
// Tests min/max on floating point values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_min_max_float
use xiom.math;

fn main() -> Int {
  if math.min_float(1.5, 2.5) != 1.5 { return 1; }
  if math.min_float(2.5, 1.5) != 1.5 { return 2; }
  if math.min_float(-1.0, 1.0) != -1.0 { return 3; }
  if math.min_float(0.0, 0.0) != 0.0 { return 4; }
  if math.max_float(1.5, 2.5) != 2.5 { return 5; }
  if math.max_float(2.5, 1.5) != 2.5 { return 6; }
  if math.max_float(-1.0, 1.0) != 1.0 { return 7; }
  if math.max_float(0.0, 0.0) != 0.0 { return 8; }
  return 0;
}
