// XIOM - Bits: Bitwise
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.bits.bitwise

// Depends on: none

// ============================================================================
// Bit counting, scanning, reversal, and power-of-two tests. All operations
// are built from byte-at-a-time reads and arithmetic shifts/masks (the
// compiler miscompiles bitwise AND on operands with bit 31 set -- see
// xiom.convert.base58 for the probe reference).
// ============================================================================

/// Population count: number of set bits in n. Complexity: O(64).
pub fn popcnt(n: Int) -> Int {
  var count: Int = 0;
  var x = n;
  var i: Int = 0;
  while i < 64 {
    if x & 1 != 0 {
      count = count + 1;
    };
    x = x >> 1;
    i = i + 1;
  };
  count
}

/// Count of consecutive zero bits starting from the most significant bit;
/// 64 for zero. Complexity: O(64).
pub fn clz(n: Int) -> Int {
  if n == 0 {
    return 64;
  };
  var hi = 63;
  while hi >= 0 {
    if (n >> hi) & 1 == 1 {
      break;
    };
    hi = hi - 1;
  };
  63 - hi
}

/// Count of consecutive zero bits starting from the least significant bit;
/// 64 for zero. Complexity: O(64).
pub fn ctz(n: Int) -> Int {
  if n == 0 {
    return 64;
  };
  var lo: Int = 0;
  while lo < 64 {
    if (n >> lo) & 1 == 1 {
      break;
    };
    lo = lo + 1;
  };
  lo
}

/// Reverses the bit order of n (bit 0 <-> bit 63).
/// Complexity: O(64).
pub fn bit_reverse(n: Int) -> Int {
  var result: Int = 0;
  var x = n;
  var i: Int = 0;
  while i < 64 {
    var bit = x & 1;
    result = result + (bit << (63 - i));
    x = x >> 1;
    i = i + 1;
  };
  result
}

/// Reverses the bit order of a single byte (low 8 bits of the input).
/// Complexity: O(8).
pub fn bit_reverse_byte(b_in: Int) -> Int {
  var b = b_in & 0xFF;
  var result: Int = 0;
  var i: Int = 0;
  while i < 8 {
    var bit = b & 1;
    result = result + (bit << (7 - i));
    b = b >> 1;
    i = i + 1;
  };
  result
}

/// Reverses the byte order of v (byte 0 <-> byte 7).
/// Complexity: O(8).
pub fn byte_swap(v: Int) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  while i < 8 {
    var b = (v >> (i * 8)) & 0xFF;
    result = result + (b << ((7 - i) * 8));
    i = i + 1;
  };
  result
}

/// Circular left shift by k bits (the shift amount is reduced mod 64).
/// Complexity: O(1).
pub fn rotate_left(n: Int, k: Int) -> Int {
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  if shift == 0 {
    return n;
  };
  (n << shift) | (n >> (64 - shift))
}

/// Circular right shift by k bits (the shift amount is reduced mod 64).
/// Complexity: O(1).
pub fn rotate_right(n: Int, k: Int) -> Int {
  var shift = k % 64;
  if shift < 0 {
    shift = shift + 64;
  };
  if shift == 0 {
    return n;
  };
  (n >> shift) | (n << (64 - shift))
}

/// Number of bits needed to represent n: 0 for zero, 64 for negative values
/// (the sign bit is counted), otherwise floor(log2 n) + 1.
/// Complexity: O(64).
pub fn bit_width(n: Int) -> Int {
  if n == 0 {
    return 0;
  };
  var hi = 63;
  while hi >= 0 {
    if (n >> hi) & 1 == 1 {
      break;
    };
    hi = hi - 1;
  };
  hi + 1
}

/// Alias of bit_width. Complexity: O(64).
pub fn bit_length(n: Int) -> Int {
  bit_width(n)
}

/// Count of consecutive 1 bits starting from the most significant bit.
/// Complexity: O(64).
pub fn leading_ones(n: Int) -> Int {
  if n == -1 {
    return 64;
  };
  var count: Int = 0;
  var hi = 63;
  while hi >= 0 {
    if (n >> hi) & 1 == 1 {
      count = count + 1;
    } else {
      break;
    };
    hi = hi - 1;
  };
  count
}

/// Count of consecutive 1 bits starting from the least significant bit.
/// Complexity: O(64).
pub fn trailing_ones(n: Int) -> Int {
  if n == -1 {
    return 64;
  };
  var count: Int = 0;
  while count < 64 {
    if (n >> count) & 1 == 1 {
      count = count + 1;
    } else {
      break;
    };
  };
  count
}

/// 1 if the population count is odd, else 0. Complexity: O(64).
pub fn bit_parity(n: Int) -> Int {
  popcnt(n) & 1
}

/// Index of the lowest set bit; -1 when n == 0. Complexity: O(64).
pub fn bit_scan_forward(n: Int) -> Int {
  if n == 0 {
    return -1;
  };
  var lo: Int = 0;
  while lo < 64 {
    if (n >> lo) & 1 == 1 {
      return lo;
    };
    lo = lo + 1;
  };
  -1
}

/// Index of the highest set bit; -1 when n == 0. Complexity: O(64).
pub fn bit_scan_reverse(n: Int) -> Int {
  if n == 0 {
    return -1;
  };
  var hi = 63;
  while hi >= 0 {
    if (n >> hi) & 1 == 1 {
      return hi;
    };
    hi = hi - 1;
  };
  -1
}

/// True iff n > 0 and n is a power of two (exactly one set bit).
/// Complexity: O(64).
pub fn is_power_of_two_bit(n: Int) -> Bool {
  if n <= 0 {
    return false;
  };
  popcnt(n) == 1
}
