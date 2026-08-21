// XIOM stdlib stress -- math.floor and math.ceil
// Tests floor/ceil on positive, negative, and fractional values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_floor_ceil
use xiom.math;

fn main() -> Int {
  if math.floor(3.7) != 3.0 { return 1; }
  if math.floor(3.1) != 3.0 { return 2; }
  if math.floor(-3.7) != -4.0 { return 3; }
  if math.floor(0.0) != 0.0 { return 4; }
  if math.ceil(3.7) != 4.0 { return 5; }
  if math.ceil(3.1) != 4.0 { return 6; }
  if math.ceil(-3.7) != -3.0 { return 7; }
  if math.ceil(0.0) != 0.0 { return 8; }
  return 0;
}
