// XIOM stdlib stress — math.exp and math.ln
// Tests exp and natural log with known values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_exp_ln
use xiom.math;

fn main() -> Int {
  if math.exp(0.0) != 1.0 { return 1; }
  if math.ln(1.0) != 0.0 { return 2; }
  var e1 = math.exp(1.0);
  if e1 < 2.71 || e1 > 2.72 { return 3; }
  if math.ln(math.exp(2.0)) < 1.99 || math.ln(math.exp(2.0)) > 2.01 { return 4; }
  return 0;
}
