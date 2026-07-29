// XIOM stdlib stress — math.clamp
// Tests clamping values within, above, and below range.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_clamp
use xiom.math;

fn main() -> Int {
  if math.clamp(5.0, 0.0, 10.0) != 5.0 { return 1; }
  if math.clamp(-5.0, 0.0, 10.0) != 0.0 { return 2; }
  if math.clamp(15.0, 0.0, 10.0) != 10.0 { return 3; }
  if math.clamp(0.0, 0.0, 10.0) != 0.0 { return 4; }
  if math.clamp(10.0, 0.0, 10.0) != 10.0 { return 5; }
  return 0;
}
