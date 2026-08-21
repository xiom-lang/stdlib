// XIOM stdlib stress -- math.abs_int
// Tests abs_int on positive, negative, and zero.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_abs_int
use xiom.math;

fn main() -> Int {
  if math.abs_int(0) != 0 { return 1; }
  if math.abs_int(42) != 42 { return 2; }
  if math.abs_int(-42) != 42 { return 3; }
  if math.abs_int(-1) != 1 { return 4; }
  if math.abs_int(2147483647) != 2147483647 { return 5; }
  return 0;
}
