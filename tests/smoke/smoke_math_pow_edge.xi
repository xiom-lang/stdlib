module smoke_math_pow_edge
use xiom.math;

fn main() -> Int {
  var p1 = math.pow(2.0, 10.0);
  if p1 < 1023.99 || p1 > 1024.01 { return 1; }

  var p2 = math.pow(10.0, 0.0);
  if p2 != 1.0 { return 2; }

  var p3 = math.pow(0.0, 5.0);
  if p3 != 0.0 { return 3; }

  var p4 = math.pow(1.0, 100.0);
  if p4 != 1.0 { return 4; }

  var p5 = math.pow(-2.0, 3.0);
  if p5 > -7.99 && p5 < -8.01 { return 5; }

  return 0;
}
