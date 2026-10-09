// p_wave97_bitwise_shapes.xi -- wave 97 bitwise shape validation (split probe)
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Companion to p_wave97_shapes.xi: xiom.bits.bitwise is probed in its own
// module because importing it together with xiom.bits.rotation and
// xiom.bits.popcount (all three export rotate_left/rotate_right) breaks
// alias-qualified resolution on v0.64.1 -- see
// tools/known_failures/p_sibling_dup_fn_alias.xi.
//
// Exercises the wave-97 bitwise clause guards:
//   the zero pins on bit_reverse/byte_swap, bit_reverse_byte(1) -> 128,
//   byte_swap(256) -> 1, the k==0 rotation identities and the
//   is_power_of_two_bit boundaries.
// Values returned from the module surface are bound before comparing.
// Returns 0 when every case holds.

module p_wave97_bitwise_shapes

use xiom.bits.bitwise as bw;

fn main() -> Int {
  let wr0 = bw.bit_reverse(0);
  if wr0 != 0 { return 1; }
  let wb0 = bw.bit_reverse_byte(0);
  if wb0 != 0 { return 2; }
  let wb1 = bw.bit_reverse_byte(1);
  if wb1 != 128 { return 3; }
  let ws0 = bw.byte_swap(0);
  if ws0 != 0 { return 4; }
  let ws1 = bw.byte_swap(256);
  if ws1 != 281474976710656 { return 5; }
  let wl0 = bw.rotate_left(7, 0);
  if wl0 != 7 { return 6; }
  let wrr0 = bw.rotate_right(7, 0);
  if wrr0 != 7 { return 7; }
  let wp0 = bw.is_power_of_two_bit(0);
  if wp0 { return 8; }
  let wp1 = bw.is_power_of_two_bit(1);
  if wp1 == false { return 9; }
  let wp2 = bw.is_power_of_two_bit(3);
  if wp2 { return 10; }
  return 0;
}
