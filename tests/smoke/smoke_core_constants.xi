module smoke_core_constants
use xiom.core;

fn main() -> Int {
  if core.INT_MAX <= 0 { return 1; }
  if core.INT_MIN >= 0 { return 2; }
  if core.FLOAT64_MAX <= 0.0 { return 3; }
  if core.FLOAT64_MIN <= 0.0 { return 4; }
  if core.FLOAT64_EPSILON <= 0.0 { return 5; }

  var s = core.size_of[Int]();
  if s <= 0 { return 6; }

  var a = core.align_of[Int]();
  if a <= 0 { return 7; }

  return 0;
}
