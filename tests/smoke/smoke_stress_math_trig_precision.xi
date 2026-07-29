// XIOM stdlib stress — math trig precision
// Tests sin/cos/tan at multiple known angles.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_trig_precision
use xiom.math;

fn main() -> Int {
  var sin_pi4 = math.sin(0.7853981633974483);
  if sin_pi4 < 0.707 || sin_pi4 > 0.708 { return 1; }
  var cos_pi4 = math.cos(0.7853981633974483);
  if cos_pi4 < 0.707 || cos_pi4 > 0.708 { return 2; }
  var sin_pi = math.sin(3.141592653589793);
  if sin_pi < -0.001 || sin_pi > 0.001 { return 3; }
  var cos_pi = math.cos(3.141592653589793);
  if cos_pi < -1.001 || cos_pi > -0.999 { return 4; }
  var tan_pi4 = math.tan(0.7853981633974483);
  if tan_pi4 < 0.999 || tan_pi4 > 1.001 { return 5; }
  return 0;
}
