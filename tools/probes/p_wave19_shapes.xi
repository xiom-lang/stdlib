// p_wave19_shapes.xi -- contract shape validation for wave 19 (bits).
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
//
// Locks the shapes wave 19 applies to xiom.bits:
// 1. disjunction: `result == 0 || result == 1` (single-bit reads, parity)
// 2. bounded count: `result >= 0 && result <= 64`
// 3. nibble bound: `result >= 0 && result <= 15`
// 4. two-field tuple byte range: `result.0 >= 0 && result.0 <= 255 &&
//    result.1 >= 0 && result.1 <= 255`
// 5. four-field tuple byte range (long conjunction)
// 6. implication with a scalar hypothesis: `width >= 1 && width <= 63 =>
//    result >= 0`
// 7. signed lower bound: `result >= -1 && result <= 63`
// 8. tuple carry flag: `result.1 == 0 || result.1 == 1`
// main() drives the real functions and asserts the properties the clauses
// will require. Returns 0 when every shape compiles and holds.

module p_wave19_shapes

use xiom.bits;
use xiom.bits.bitwise;
use xiom.bits.popcount;
use xiom.bits.rotation;
use xiom.bits.bitarray;
use xiom.bits.bitfield;

// Shape 1: single-bit read returns 0 or 1.
fn s_bit(n: Int, pos: Int) -> Int
  ensures: result == 0 || result == 1
{
  return bits.bit_get(n, pos);
}

// Shape 2: count bounded by the 64-bit width.
fn s_count(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
  return bits.bit_count_ones(n);
}

// Shape 3: nibble bound.
fn s_nibble(n: Int) -> Int
  ensures: result >= 0 && result <= 15
{
  return bits.low_nibble(n);
}

// Shape 4: two-field tuple byte range.
fn s_unpack16(value: Int) -> (Int, Int)
  ensures: result.0 >= 0 && result.0 <= 255 && result.1 >= 0 && result.1 <= 255
{
  return bits.unpack_u16_le(value);
}

// Shape 5: four-field tuple byte range.
fn s_unpack32(value: Int) -> (Int, Int, Int, Int)
  ensures: result.0 >= 0 && result.0 <= 255 && result.1 >= 0 && result.1 <= 255 && result.2 >= 0 && result.2 <= 255 && result.3 >= 0 && result.3 <= 255
{
  return bits.unpack_u32_be(value);
}

// Shape 6: implication with scalar hypothesis.
fn s_mask(width: Int) -> Int
  ensures: width >= 1 && width <= 63 => result >= 0
{
  return bitfield.bitfield_mask(width);
}

// Shape 7: signed lower bound.
fn s_scan(n: Int) -> Int
  ensures: result >= -1 && result <= 63
{
  return bitwise.bit_scan_forward(n);
}

// Shape 8: tuple carry flag.
fn s_carry(n: Int, k: Int, carry_in: Int) -> (Int, Int)
  ensures: result.1 == 0 || result.1 == 1
{
  return rotation.rotate_left_carry(n, k, carry_in);
}

fn main() -> Int {
  if bits.bit_get(6, 1) != 1 { return 1; }
  if bits.bit_get(6, 0) != 0 { return 2; }
  let c = bits.bit_count_ones(255);
  if c < 0 || c > 64 { return 3; }
  let n = bits.low_nibble(0x2F);
  if n < 0 || n > 15 { return 4; }
  let u = bits.unpack_u16_le(0x1234);
  if u.0 < 0 || u.0 > 255 || u.1 < 0 || u.1 > 255 { return 5; }
  let q = bits.unpack_u32_be(0x01020304);
  if q.0 < 0 || q.0 > 255 || q.3 < 0 || q.3 > 255 { return 6; }
  let m = bitfield.bitfield_mask(8);
  if m < 0 { return 7; }
  let s = bitwise.bit_scan_reverse(1);
  if s < -1 || s > 63 { return 8; }
  let r = rotation.rotate_right_carry(9, 2, 0);
  if r.1 != 0 && r.1 != 1 { return 9; }
  let ba = bitarray.bit_array_new(8);
  let bc = bitarray.bit_array_count(ba);
  if bc < 0 { return 10; }
  let bl = bitarray.bit_array_len(ba);
  if bl < 0 { return 11; }
  let pc = xiom.bits.popcount.popcount(7);
  if pc < 0 || pc > 64 { return 12; }
  let z = xiom.bits.popcount.count_leading_zeros(0);
  if z < 0 || z > 64 { return 13; }
  return 0;
}
