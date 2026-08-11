// XIOM — Bit-Level Utilities
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.bits

use xiom.bits.bitwise;
use xiom.bits.rotation;
use xiom.bits.endianness;

use xiom.bits.bitarray;
use xiom.bits.bitfield;
use xiom.bits.popcount;

use xiom.math.bit_and;
use xiom.math.bit_or;
use xiom.math.bit_xor;
use xiom.math.bit_not;
use xiom.math.shl;
use xiom.math.shr;
use xiom.core.size_of;

// ---------------------------------------------------------------------------
// bit_get — Returns 1 if the bit at position pos (0 = LSB) is set, 0 otherwise.
// Position must be in [0, 63] for 64-bit Int.
// ---------------------------------------------------------------------------

pub fn bit_get(n: Int, pos: Int) -> Int {
  if pos < 0 || pos >= 64 { return 0; }
  var mask = shl(1, pos);
  if bit_and(n, mask) != 0 { return 1; }
  return 0;
}

// ---------------------------------------------------------------------------
// bit_set — Returns n with the bit at position pos set to 1.
// ---------------------------------------------------------------------------

pub fn bit_set(n: Int, pos: Int) -> Int {
  if pos < 0 || pos >= 64 { return n; }
  var mask = shl(1, pos);
  return bit_or(n, mask);
}

// ---------------------------------------------------------------------------
// bit_clear — Returns n with the bit at position pos cleared (set to 0).
// ---------------------------------------------------------------------------

pub fn bit_clear(n: Int, pos: Int) -> Int {
  if pos < 0 || pos >= 64 { return n; }
  var mask = bit_not(shl(1, pos));
  return bit_and(n, mask);
}

// ---------------------------------------------------------------------------
// bit_toggle — Flips the bit at position pos: 0→1, 1→0.
// ---------------------------------------------------------------------------

pub fn bit_toggle(n: Int, pos: Int) -> Int {
  if pos < 0 || pos >= 64 { return n; }
  var mask = shl(1, pos);
  return bit_xor(n, mask);
}

// ---------------------------------------------------------------------------
// bit_count_ones (popcount) — Counts set bits (1s) in n.
// Delegates to xiom.num.count_ones for the canonical implementation.
// ---------------------------------------------------------------------------

pub fn bit_count_ones(n: Int) -> Int {
  var count = 0;
  var x = n;
  var bits = size_of[Int]() * 8;
  var i = 0;
  while i < bits {
    if bit_and(x, 1) != 0 {
      count = count + 1;
    }
    x = shr(x, 1);
    i = i + 1;
  }
  return count;
}

// ---------------------------------------------------------------------------
// bit_count_zeros — Counts cleared bits (0s) in n.
// ---------------------------------------------------------------------------

pub fn bit_count_zeros(n: Int) -> Int {
  return size_of[Int]() * 8 - bit_count_ones(n);
}

// ---------------------------------------------------------------------------
// popcount — Alias for bit_count_ones. Hamming weight of the value.
// Delegates to the built-in counting function.
// ---------------------------------------------------------------------------

pub fn popcount(n: Int) -> Int {
  return bit_count_ones(n);
}

// ---------------------------------------------------------------------------
// clz — Count Leading Zeros. Returns the number of consecutive zero bits
// starting from the most significant bit.
// ---------------------------------------------------------------------------

pub fn clz(n: Int) -> Int {
  if n == 0 { return size_of[Int]() * 8; }
  var count = 0;
  var bits = size_of[Int]() * 8;
  var mask = shl(1, bits - 1);
  while bit_and(n, mask) == 0 {
    count = count + 1;
    mask = shr(mask, 1);
  }
  return count;
}

// ---------------------------------------------------------------------------
// ctz — Count Trailing Zeros. Returns the number of consecutive zero bits
// starting from the least significant bit.
// ---------------------------------------------------------------------------

pub fn ctz(n: Int) -> Int {
  if n == 0 { return size_of[Int]() * 8; }
  var count = 0;
  var x = n;
  while bit_and(x, 1) == 0 {
    count = count + 1;
    x = shr(x, 1);
  }
  return count;
}

// ---------------------------------------------------------------------------
// rot_left — Circularly shifts bits left by k positions.
// Bits shifted off the MSB reappear at the LSB.
// Equivalent to xiom.num.rotate_left.
// ---------------------------------------------------------------------------

pub fn rot_left(n: Int, k: Int) -> Int {
  var bits = size_of[Int]() * 8;
  var shift = k % bits;
  if shift == 0 { return n; }
  return bit_or(shl(n, shift), shr(n, bits - shift));
}

// ---------------------------------------------------------------------------
// rot_right — Circularly shifts bits right by k positions.
// Bits shifted off the LSB reappear at the MSB.
// Equivalent to xiom.num.rotate_right.
// ---------------------------------------------------------------------------

pub fn rot_right(n: Int, k: Int) -> Int {
  var bits = size_of[Int]() * 8;
  var shift = k % bits;
  if shift == 0 { return n; }
  return bit_or(shr(n, shift), shl(n, bits - shift));
}

// ---------------------------------------------------------------------------
// bit_reverse — Reverses the order of bits in n (mirror).
// LSB becomes MSB and vice versa.
// ---------------------------------------------------------------------------

pub fn bit_reverse(n: Int) -> Int {
  var result = 0;
  var x = n;
  var bits = size_of[Int]() * 8;
  var i = 0;
  while i < bits {
    result = bit_or(shl(result, 1), bit_and(x, 1));
    x = shr(x, 1);
    i = i + 1;
  }
  return result;
}

// ---------------------------------------------------------------------------
// byte_swap16 — Swaps the two bytes of a 16-bit value (stored in lower 16
// bits of an Int). Returns the byte-swapped result.
// ---------------------------------------------------------------------------

pub fn byte_swap16(v: Int) -> Int {
  var lower = bit_and(v, 255);
  var upper = bit_and(shr(v, 8), 255);
  return bit_or(shl(lower, 8), upper);
}

// ---------------------------------------------------------------------------
// byte_swap32 — Swaps all four bytes of a 32-bit value (stored in lower 32
// bits of an Int). Returns the byte-swapped result.
// ---------------------------------------------------------------------------

pub fn byte_swap32(v: Int) -> Int {
  var b0 = bit_and(v, 255);
  var b1 = bit_and(shr(v, 8), 255);
  var b2 = bit_and(shr(v, 16), 255);
  var b3 = bit_and(shr(v, 24), 255);
  return bit_or(bit_or(shl(b0, 24), shl(b1, 16)), bit_or(shl(b2, 8), b3));
}

// ---------------------------------------------------------------------------
// byte_swap64 — Swaps all eight bytes of a 64-bit value.
// Returns the fully byte-reversed Int.
// ---------------------------------------------------------------------------

pub fn byte_swap64(v: Int) -> Int {
  var result = 0;
  var i = 0;
  while i < 8 {
    var byte_val = bit_and(shr(v, i * 8), 255);
    result = bit_or(result, shl(byte_val, (7 - i) * 8));
    i = i + 1;
  }
  return result;
}

// ---------------------------------------------------------------------------
// get_bit_range — Extracts a contiguous range of bits from n as an unsigned
// value. start is the LSB position of the range, len is the number of bits.
// Returns the extracted value right-justified.
// Example: get_bit_range(0b110101, 0, 3) → 0b101 (bits 0-2)
// ---------------------------------------------------------------------------

pub fn get_bit_range(n: Int, start: Int, len: Int) -> Int {
  if len <= 0 { return 0; }
  var mask = 0;
  var i = 0;
  while i < len {
    mask = bit_or(mask, shl(1, i));
    i = i + 1;
  }
  return bit_and(shr(n, start), mask);
}

// ---------------------------------------------------------------------------
// set_bit_range — Sets a contiguous range of bits in n to the given value.
// start is the LSB position, len is the bit width.
// value is right-justified (lower bits only).
// Returns the modified Int.
// ---------------------------------------------------------------------------

pub fn set_bit_range(n: Int, start: Int, len: Int, value: Int) -> Int {
  if len <= 0 { return n; }
  var mask = 0;
  var i = 0;
  while i < len {
    mask = bit_or(mask, shl(1, i));
    i = i + 1;
  }
  var cleared = bit_and(n, bit_not(shl(mask, start)));
  var shifted_val = shl(bit_and(value, mask), start);
  return bit_or(cleared, shifted_val);
}

// ---------------------------------------------------------------------------
// is_pow2 — Returns true if n > 0 and n is a power of two.
// Uses the classic bit trick: powers of two have exactly one set bit,
// so n & (n-1) == 0.
// NOTE: xiom.num also provides is_power_of_two with identical behavior.
// ---------------------------------------------------------------------------

pub fn is_pow2(n: Int) -> Bool {
  if n <= 0 { return false; }
  return bit_and(n, n - 1) == 0;
}

// ---------------------------------------------------------------------------
// low_nibble — Extracts the lower 4 bits (nibble) of n. Returns 0–15.
// ---------------------------------------------------------------------------

pub fn low_nibble(n: Int) -> Int {
  return bit_and(n, 15);
}

// ---------------------------------------------------------------------------
// high_nibble — Extracts bits 4–7 (the high nibble of the low byte).
// Returns 0–15.
// ---------------------------------------------------------------------------

pub fn high_nibble(n: Int) -> Int {
  return bit_and(shr(n, 4), 15);
}

// ---------------------------------------------------------------------------
// pack_u16_le — Packs two byte values (0-255) into a 16-bit integer in
// little-endian order: low_byte at bits 0-7, high_byte at bits 8-15.
// ---------------------------------------------------------------------------

pub fn pack_u16_le(low_byte: Int, high_byte: Int) -> Int {
  var lo = bit_and(low_byte, 255);
  var hi = bit_and(high_byte, 255);
  return bit_or(lo, shl(hi, 8));
}

// ---------------------------------------------------------------------------
// pack_u16_be — Packs two byte values into a 16-bit integer in big-endian
// order: high_byte at bits 0-7, low_byte at bits 8-15.
// ---------------------------------------------------------------------------

pub fn pack_u16_be(high_byte: Int, low_byte: Int) -> Int {
  var lo = bit_and(low_byte, 255);
  var hi = bit_and(high_byte, 255);
  return bit_or(hi, shl(lo, 8));
}

// ---------------------------------------------------------------------------
// pack_u32_le — Packs four byte values (0-255) into a 32-bit integer in
// little-endian order: b0 at bits 0-7, b1 at 8-15, b2 at 16-23, b3 at 24-31.
// ---------------------------------------------------------------------------

pub fn pack_u32_le(b0: Int, b1: Int, b2: Int, b3: Int) -> Int {
  return bit_or(bit_or(bit_and(b0, 255), shl(bit_and(b1, 255), 8)),
                bit_or(shl(bit_and(b2, 255), 16), shl(bit_and(b3, 255), 24)));
}

// ---------------------------------------------------------------------------
// pack_u32_be — Packs four byte values into a 32-bit integer in big-endian
// order: b0 at bits 24-31, ... , b3 at bits 0-7.
// ---------------------------------------------------------------------------

pub fn pack_u32_be(b0: Int, b1: Int, b2: Int, b3: Int) -> Int {
  return bit_or(bit_or(shl(bit_and(b0, 255), 24), shl(bit_and(b1, 255), 16)),
                bit_or(shl(bit_and(b2, 255), 8), bit_and(b3, 255)));
}

// ---------------------------------------------------------------------------
// unpack_u16_le — Unpacks a little-endian 16-bit value into (low_byte, high_byte).
// ---------------------------------------------------------------------------

pub fn unpack_u16_le(value: Int) -> (Int, Int) {
  var lo = bit_and(value, 255);
  var hi = bit_and(shr(value, 8), 255);
  return (lo, hi);
}

// ---------------------------------------------------------------------------
// unpack_u16_be — Unpacks a big-endian 16-bit value into (high_byte, low_byte).
// ---------------------------------------------------------------------------

pub fn unpack_u16_be(value: Int) -> (Int, Int) {
  var hi = bit_and(value, 255);
  var lo = bit_and(shr(value, 8), 255);
  return (hi, lo);
}

// ---------------------------------------------------------------------------
// unpack_u32_le — Unpacks a little-endian 32-bit value into a 4-tuple of
// bytes (b0=LSB .. b3=MSB).
// ---------------------------------------------------------------------------

pub fn unpack_u32_le(value: Int) -> (Int, Int, Int, Int) {
  var b0 = bit_and(value, 255);
  var b1 = bit_and(shr(value, 8), 255);
  var b2 = bit_and(shr(value, 16), 255);
  var b3 = bit_and(shr(value, 24), 255);
  return (b0, b1, b2, b3);
}

// ---------------------------------------------------------------------------
// unpack_u32_be — Unpacks a big-endian 32-bit value into a 4-tuple of bytes
// (b0=MSB .. b3=LSB).
// ---------------------------------------------------------------------------

pub fn unpack_u32_be(value: Int) -> (Int, Int, Int, Int) {
  var b0 = bit_and(shr(value, 24), 255);
  var b1 = bit_and(shr(value, 16), 255);
  var b2 = bit_and(shr(value, 8), 255);
  var b3 = bit_and(value, 255);
  return (b0, b1, b2, b3);
}
