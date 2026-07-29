// XIOM stdlib stress — math.pow
// Tests pow with various base/exponent combinations.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_pow
use xiom.math;

fn main() -> Int {
  if math.pow(2.0, 3.0) != 8.0 { return 1; }
  if math.pow(3.0, 2.0) != 9.0 { return 2; }
  if math.pow(10.0, 0.0) != 1.0 { return 3; }
  if math.pow(5.0, 1.0) != 5.0 { return 4; }
  if math.pow(2.0, 10.0) != 1024.0 { return 5; }
  return 0;
}
