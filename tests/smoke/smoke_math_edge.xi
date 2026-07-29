module smoke_math_edge
use xiom.math;

fn main() -> Int {
  var s0 = math.sqrt(0.0);
  if s0 != 0.0 { return 1; }

  var p1 = math.pow(1.0, 1000.0);
  if p1 < 0.99 || p1 > 1.01 { return 2; }

  var p0 = math.pow(2.0, 0.0);
  if p0 != 1.0 { return 3; }

  if math.min_int(-2147483647, 2147483647) != -2147483647 { return 4; }
  if math.max_int(-2147483647, 2147483647) != 2147483647 { return 5; }

  if math.abs_int(-2147483647) <= 0 { return 6; }

  if math.shl(0, 10) != 0 { return 7; }
  if math.shr(0, 10) != 0 { return 8; }
  if math.shl(1, 100) != 0 { return 9; }

  return 0;
}
