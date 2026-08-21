// XIOM stdlib stress -- math extreme values
// Tests math functions at boundary and extreme values.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_extreme
use xiom.math;

fn main() -> Int {
  var r1 = math.abs_int(0);
  if r1 != 0 { return 1; }
  var r2 = math.abs_float(-0.0);
  if r2 != 0.0 { return 2; }
  var r3 = math.floor(0.999999);
  if r3 != 0.0 { return 3; }
  var r4 = math.ceil(0.000001);
  if r4 != 1.0 { return 4; }
  var r5 = math.clamp(0.0, 0.0, 0.0);
  if r5 != 0.0 { return 5; }
  var r6 = math.min_float(1e10, 1e9);
  if r6 != 1e9 { return 6; }
  var r7 = math.max_float(-1e10, -1e9);
  if r7 != -1e9 { return 7; }
  return 0;
}
