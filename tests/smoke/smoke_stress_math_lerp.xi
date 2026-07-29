// XIOM stdlib stress — math.lerp
// Tests linear interpolation at t=0, t=0.5, t=1.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_lerp
use xiom.math;

fn main() -> Int {
  if math.lerp(0.0, 10.0, 0.0) != 0.0 { return 1; }
  if math.lerp(0.0, 10.0, 1.0) != 10.0 { return 2; }
  if math.lerp(0.0, 10.0, 0.5) != 5.0 { return 3; }
  if math.lerp(10.0, 0.0, 0.5) != 5.0 { return 4; }
  if math.lerp(-5.0, 5.0, 0.5) != 0.0 { return 5; }
  return 0;
}
