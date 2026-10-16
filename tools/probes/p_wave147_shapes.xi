// p_wave147_shapes.xi -- wave 147 lock: the Float32 bitcast pair
// (REL-20261010-1550-xvector-6; runtime-backed exact memcpy bitcast).
// Rows (0 = all hold):
//  1 -- f32_bits(1.0) == 0x3F800000 (1065353216)
//  2 -- bits_to_f32(0x3F800000) == 1.0
//  3 -- f32_bits(0.0) == 0
//  4 -- the -0.0 pattern roundtrips (0x80000000)
//  5 -- 0.5 pattern roundtrip
//  6 -- -2.5 pattern roundtrip
//  7 -- +inf pattern roundtrip (0x7F800000)
//  8 -- a quiet-NaN pattern roundtrip (0x7FC00000)
// Setup failures use 10+.

module p_wave147_shapes

use xiom.num.float;

fn main() -> Int {
  if float.f32_bits(1.0) != 1065353216 { return 1; }
  if float.bits_to_f32(1065353216) != 1.0 { return 2; }
  if float.f32_bits(0.0) != 0 { return 3; }
  if float.f32_bits(float.bits_to_f32(2147483648)) != 2147483648 { return 4; }
  let h = float.f32_bits(0.5);
  if float.bits_to_f32(h) != 0.5 { return 5; }
  if float.bits_to_f32(float.f32_bits(-2.5)) != -2.5 { return 6; }
  if float.f32_bits(float.bits_to_f32(2139095040)) != 2139095040 { return 7; }
  if float.f32_bits(float.bits_to_f32(2143289344)) != 2143289344 { return 8; }
  return 0;
}
