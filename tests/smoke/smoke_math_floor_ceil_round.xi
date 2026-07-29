module smoke_math_floor_ceil_round
use xiom.math;

fn main() -> Int {
  if math.floor(3.14) != 3.0 { return 1; }
  if math.floor(3.99) != 3.0 { return 2; }
  if math.floor(0.0) != 0.0 { return 3; }
  if math.floor(-0.5) != -1.0 { return 4; }

  if math.ceil(3.14) != 4.0 { return 5; }
  if math.ceil(3.99) != 4.0 { return 6; }
  if math.ceil(0.0) != 0.0 { return 7; }
  if math.ceil(-0.5) != 0.0 { return 8; }

  if math.round(3.14) != 3 { return 9; }
  if math.round(3.5) != 4 { return 10; }
  if math.round(3.99) != 4 { return 11; }
  if math.round(-3.5) != -3 { return 12; }
  if math.round(0.0) != 0 { return 13; }

  return 0;
}
