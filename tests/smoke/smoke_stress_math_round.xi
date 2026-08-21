// XIOM stdlib stress -- math.round
// Tests round to nearest integer.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_round
use xiom.math;

fn main() -> Int {
  if math.round(3.2) != 3 { return 1; }
  if math.round(3.7) != 4 { return 2; }
  if math.round(3.5) != 4 { return 3; }
  if math.round(-3.2) != -3 { return 4; }
  if math.round(-3.7) != -4 { return 5; }
  if math.round(0.0) != 0 { return 6; }
  return 0;
}
