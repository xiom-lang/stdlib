module smoke_bits
use xiom.bits;
fn main() -> Int {
  if xiom.bits.bit_get(5, 0) != 1 { return 1; }
  if xiom.bits.bit_get(5, 1) != 0 { return 1; }
  if xiom.bits.popcount(255) != 8 { return 1; }
  if xiom.bits.byte_swap16(0x1234) != 0x3412 { return 1; }
  if xiom.bits.clz(1) != 63 { return 1; }
  if !xiom.bits.is_pow2(16) { return 1; }
  if xiom.bits.rot_left(1, 2) != 4 { return 1; }
  return 0;
}
