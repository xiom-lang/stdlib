// XIOM stdlib stress — math.min_int and math.max_int
// Tests min/max on various integer pairs.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_min_max_int
use xiom.math;

fn main() -> Int {
  if math.min_int(3, 9) != 3 { return 1; }
  if math.min_int(9, 3) != 3 { return 2; }
  if math.min_int(-5, 5) != -5 { return 3; }
  if math.min_int(7, 7) != 7 { return 4; }
  if math.max_int(3, 9) != 9 { return 5; }
  if math.max_int(9, 3) != 9 { return 6; }
  if math.max_int(-5, 5) != 5 { return 7; }
  if math.max_int(7, 7) != 7 { return 8; }
  return 0;
}
