module smoke_math_bitwise
use xiom.math;

fn main() -> Int {
  if math.bit_and(6, 3) != 2 { return 1; }
  if math.bit_and(0, 5) != 0 { return 2; }
  if math.bit_and(7, 7) != 7 { return 3; }

  if math.bit_or(6, 3) != 7 { return 4; }
  if math.bit_or(0, 5) != 5 { return 5; }

  if math.bit_xor(6, 3) != 5 { return 6; }
  if math.bit_xor(5, 5) != 0 { return 7; }

  if math.bit_not(0) != -1 { return 8; }

  if math.shl(1, 0) != 1 { return 9; }
  if math.shl(1, 3) != 8 { return 10; }
  if math.shl(3, 2) != 12 { return 11; }

  if math.shr(8, 0) != 8 { return 12; }
  if math.shr(8, 3) != 1 { return 13; }
  if math.shr(12, 2) != 3 { return 14; }

  return 0;
}
