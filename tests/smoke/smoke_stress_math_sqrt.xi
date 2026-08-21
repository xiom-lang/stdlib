// XIOM stdlib stress -- math.sqrt
// Tests sqrt on perfect squares and edge values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_sqrt
use xiom.math;

fn main() -> Int {
  if math.sqrt(4.0) != 2.0 { return 1; }
  if math.sqrt(9.0) != 3.0 { return 2; }
  if math.sqrt(0.0) != 0.0 { return 3; }
  if math.sqrt(1.0) != 1.0 { return 4; }
  if math.sqrt(100.0) != 10.0 { return 5; }
  return 0;
}
