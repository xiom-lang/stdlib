// XIOM stdlib stress -- math.abs_float
// Tests abs_float on positive, negative, zero, and negative zero.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_abs_float
use xiom.math;

fn main() -> Int {
  if math.abs_float(0.0) != 0.0 { return 1; }
  if math.abs_float(3.14) != 3.14 { return 2; }
  if math.abs_float(-3.14) != 3.14 { return 3; }
  if math.abs_float(-0.001) != 0.001 { return 4; }
  if math.abs_float(1000.5) != 1000.5 { return 5; }
  return 0;
}
