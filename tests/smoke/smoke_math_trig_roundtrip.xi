module smoke_math_trig_roundtrip
use xiom.math;

fn main() -> Int {
  var x: Float64 = 0.5;
  var s = math.sin(x);
  var asin_v = math.asin(s);
  if asin_v < x - 0.01 || asin_v > x + 0.01 { return 1; }

  var c = math.cos(0.5);
  var ac = math.acos(c);
  if ac < 0.49 || ac > 0.51 { return 2; }

  var t = math.tan(0.3);
  var at = math.atan(t);
  if at < 0.29 || at > 0.31 { return 3; }

  return 0;
}
