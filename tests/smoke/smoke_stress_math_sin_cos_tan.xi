// XIOM stdlib stress -- math.sin, math.cos, math.tan
// Tests trig functions at known angles.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_sin_cos_tan
use xiom.math;

fn main() -> Int {
  var sin0 = math.sin(0.0);
  var cos0 = math.cos(0.0);
  if sin0 != 0.0 { return 1; }
  if cos0 != 1.0 { return 2; }
  var tan0 = math.tan(0.0);
  if tan0 != 0.0 { return 3; }
  var sin_pi2 = math.sin(1.5707963267948966);
  if sin_pi2 < 0.99 || sin_pi2 > 1.01 { return 4; }
  var cos_pi2 = math.cos(1.5707963267948966);
  if cos_pi2 < -0.01 || cos_pi2 > 0.01 { return 5; }
  return 0;
}
