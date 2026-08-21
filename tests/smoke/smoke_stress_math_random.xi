// XIOM stdlib stress -- math.random and math.random_range
// Tests random generation and verifies values are in expected range.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_random
use xiom.math;

fn main() -> Int {
  math.seed_rng(42);
  var r1 = math.random();
  if r1 < 0.0 || r1 >= 1.0 { return 1; }
  var r2 = math.random_range(0, 100);
  if r2 < 0 || r2 >= 100 { return 2; }
  var r3 = math.random_range(-50, 50);
  if r3 < -50 || r3 >= 50 { return 3; }
  math.seed_rng(42);
  var r4 = math.random();
  if r4 != r1 { return 4; }
  return 0;
}
