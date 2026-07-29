module smoke_math_pure
use xiom.math;

fn main() -> Int {
  var s = math.sqrt_pure(16.0);
  if s < 3.99 || s > 4.01 { return 1; }

  var a = math.abs_float_pure(-7.0);
  if a != 7.0 { return 2; }

  var f = math.floor_pure(3.9);
  if f != 3.0 { return 3; }

  var c = math.ceil_pure(3.1);
  if c != 4.0 { return 4; }

  var s0 = math.sin_pure(0.0);
  if s0 < -0.1 || s0 > 0.1 { return 5; }

  var c0 = math.cos_pure(0.0);
  if c0 < 0.9 || c0 > 1.1 { return 6; }

  var e0 = math.exp_pure(0.0);
  if e0 < 0.9 || e0 > 1.1 { return 7; }

  var l1 = math.ln_pure(1.0);
  if l1 < -0.1 || l1 > 0.1 { return 8; }

  return 0;
}
