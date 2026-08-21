// XIOM stdlib stress -- math nested function calls
// Tests composing multiple math functions in expressions.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_nested
use xiom.math;

fn main() -> Int {
  var r1 = math.floor(math.sqrt(10.0));
  if r1 != 3.0 { return 1; }
  var r2 = math.abs_int(math.round(-3.7));
  if r2 != 4 { return 2; }
  var r3 = math.clamp(math.pow(2.0, 5.0), 0.0, 10.0);
  if r3 != 10.0 { return 3; }
  var r4 = math.min_int(math.max_int(-5, 10), 7);
  if r4 != 7 { return 4; }
  var r5 = math.max_float(math.min_float(3.0, 1.0), 2.0);
  if r5 != 2.0 { return 5; }
  return 0;
}
