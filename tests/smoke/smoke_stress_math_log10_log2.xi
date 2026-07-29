// XIOM stdlib stress — math.log10 and math.log2
// Tests log10 and log2 at known values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_log10_log2
use xiom.math;

fn main() -> Int {
  if math.log10(1.0) != 0.0 { return 1; }
  if math.log10(10.0) != 1.0 { return 2; }
  if math.log10(100.0) != 2.0 { return 3; }
  if math.log2(1.0) != 0.0 { return 4; }
  if math.log2(2.0) != 1.0 { return 5; }
  if math.log2(8.0) != 3.0 { return 6; }
  return 0;
}
