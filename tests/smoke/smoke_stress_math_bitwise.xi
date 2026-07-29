// XIOM stdlib stress — math bitwise operations
// Tests bit_and, bit_or, bit_xor, bit_not.
// Returns 0 on success, nonzero on failure.

module smoke_stress_math_bitwise
use xiom.math;

fn main() -> Int {
  if math.bit_and(0xFF, 0x0F) != 0x0F { return 1; }
  if math.bit_and(0, 0xFF) != 0 { return 2; }
  if math.bit_or(0xF0, 0x0F) != 0xFF { return 3; }
  if math.bit_or(0, 0xFF) != 0xFF { return 4; }
  if math.bit_xor(0xFF, 0xFF) != 0 { return 5; }
  if math.bit_xor(0xF0, 0x0F) != 0xFF { return 6; }
  if math.bit_not(0) != -1 { return 7; }
  return 0;
}
