module smoke_math_constants
use xiom.math;

fn main() -> Int {
  if math.PI < 3.14 || math.PI > 3.15 { return 1; }
  if math.E < 2.71 || math.E > 2.72 { return 2; }
  if math.TAU < 6.28 || math.TAU > 6.29 { return 3; }

  return 0;
}
