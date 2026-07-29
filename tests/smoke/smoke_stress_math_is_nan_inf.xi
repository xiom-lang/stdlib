// XIOM stdlib stress — math.is_nan and math.is_inf
// Tests NaN and infinity detection.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_is_nan_inf
use xiom.math;

fn main() -> Int {
  if math.is_nan(0.0) { return 1; }
  if math.is_nan(1.0) { return 2; }
  if math.is_inf(0.0) { return 3; }
  if math.is_inf(1.0) { return 4; }
  if math.is_nan(0.0 / 0.0) == false { return 5; }
  if math.is_inf(1.0 / 0.0) == false { return 6; }
  return 0;
}
