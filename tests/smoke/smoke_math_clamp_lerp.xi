module smoke_math_clamp_lerp
use xiom.math;

fn main() -> Int {
  if math.clamp(5.0, 0.0, 10.0) != 5.0 { return 1; }
  if math.clamp(-1.0, 0.0, 10.0) != 0.0 { return 2; }
  if math.clamp(15.0, 0.0, 10.0) != 10.0 { return 3; }
  if math.clamp(0.0, 0.0, 0.0) != 0.0 { return 4; }

  if math.lerp(0.0, 10.0, 0.0) != 0.0 { return 5; }
  if math.lerp(0.0, 10.0, 1.0) != 10.0 { return 6; }
  if math.lerp(0.0, 10.0, 0.5) != 5.0 { return 7; }

  return 0;
}
