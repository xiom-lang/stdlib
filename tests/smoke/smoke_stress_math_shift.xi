// XIOM stdlib stress — math.shl and math.shr
// Tests bit shift left and right.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_shift
use xiom.math;

fn main() -> Int {
  if math.shl(1, 0) != 1 { return 1; }
  if math.shl(1, 1) != 2 { return 2; }
  if math.shl(1, 4) != 16 { return 3; }
  if math.shl(3, 2) != 12 { return 4; }
  if math.shr(16, 1) != 8 { return 5; }
  if math.shr(16, 4) != 1 { return 6; }
  if math.shr(100, 0) != 100 { return 7; }
  if math.shr(-16, 1) != -8 { return 8; }
  return 0;
}
