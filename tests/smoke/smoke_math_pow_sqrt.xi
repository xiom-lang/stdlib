module smoke_math_pow_sqrt
use xiom.math;

fn main() -> Int {
  var s = math.sqrt(4.0);
  if s < 1.99 || s > 2.01 { return 1; }

  var s9 = math.sqrt(9.0);
  if s9 < 2.99 || s9 > 3.01 { return 2; }

  var s0 = math.sqrt(0.0);
  if s0 != 0.0 { return 3; }

  var s1 = math.sqrt(1.0);
  if s1 < 0.99 || s1 > 1.01 { return 4; }

  var p = math.pow(2.0, 3.0);
  if p < 7.99 || p > 8.01 { return 5; }

  var p0 = math.pow(5.0, 0.0);
  if p0 != 1.0 { return 6; }

  var p1 = math.pow(3.0, 1.0);
  if p1 < 2.99 || p1 > 3.01 { return 7; }

  return 0;
}
