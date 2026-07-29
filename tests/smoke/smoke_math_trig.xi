module smoke_math_trig
use xiom.math;

fn main() -> Int {
  var s0 = math.sin(0.0);
  if s0 < -0.01 || s0 > 0.01 { return 1; }

  var c0 = math.cos(0.0);
  if c0 < 0.99 || c0 > 1.01 { return 2; }

  var t0 = math.tan(0.0);
  if t0 < -0.01 || t0 > 0.01 { return 3; }

  var as0 = math.asin(0.0);
  if as0 < -0.01 || as0 > 0.01 { return 4; }

  var ac1 = math.acos(1.0);
  if ac1 < -0.01 || ac1 > 0.01 { return 5; }

  var at0 = math.atan(0.0);
  if at0 < -0.01 || at0 > 0.01 { return 6; }

  var a2 = math.atan2(1.0, 1.0);
  if a2 < 0.78 || a2 > 0.79 { return 7; }

  return 0;
}
