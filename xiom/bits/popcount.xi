// XIOM - Bits: Popcount
// Copyright (c) 2026 Eleftherios Notas and The XIOM Authors
// SPDX-License-Identifier: MIT OR Apache-2.0
// Home: bits.xi + num.xi - this sublib splits the counting/shifting domain.

module xiom.bits.popcount

// Depends on: none

// ============================================================================
// Bit counting, leading/trailing zeros, parity, power-of-two rounding, and
// rotation. All operations are built from byte-at-a-time reads and arithmetic
// shifts/masks (the compiler miscompiles bitwise AND on operands with bit 31
// set -- see xiom.convert.base58 for the probe reference).
// ============================================================================

/// Number of set bits in n. Complexity: O(64).
pub fn popcount(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
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

/// Number of set bits in a UInt64 value. The low bit of an arithmetic shift
/// is identical to a logical shift, so `(n >> i) & 1` is exact.
/// Complexity: O(64).
pub fn popcount64(n: UInt64) -> Int
  ensures: result >= 0 && result <= 64
{
  var count: Int = 0;
  var i: Int = 0;
  while i < 64 {
    var bit = (n >> i) & 1;
    if bit != 0 {
      count = count + 1;
    };
    i = i + 1;
  };
  count
}

/// Consecutive zero bits from the most significant bit; 64 for zero.
/// Complexity: O(64).
pub fn count_leading_zeros(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
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

/// Consecutive zero bits from the least significant bit; 64 for zero.
/// Complexity: O(64).
pub fn count_trailing_zeros(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
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

/// Number of set bits (alias of popcount). Complexity: O(64).
pub fn count_ones(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
  popcount(n)
}

/// Number of cleared bits (64 - popcount). Complexity: O(64).
pub fn count_zeros(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
  64 - popcount(n)
}

/// 1 if the population count is odd, else 0. Complexity: O(64).
pub fn parity(n: Int) -> Int
  ensures: result == 0 || result == 1
{
  popcount(n) & 1
}

/// Number of bits needed to represent n: 0 for zero, 64 for negative values,
/// otherwise floor(log2 n) + 1. Complexity: O(64).
pub fn bit_length(n: Int) -> Int
  ensures: result >= 0 && result <= 64
{
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

/// Smallest power of two >= n. n <= 0 yields 1; values above 2^62 yield 0
/// (the next power of two would not fit an Int). Complexity: O(63).
pub fn next_pow2(n: Int) -> Int {
  if n <= 0 {
    return 1;
  };
  if n > 4611686018427387904 {
    return 0;
  };
  var p: Int = 1;
  while p < n {
    p = p * 2;
  };
  p
}

/// Largest power of two <= n. n <= 0 yields 0. Complexity: O(64).
pub fn prev_pow2(n: Int) -> Int {
  if n <= 0 {
    return 0;
  };
  if n == 1 {
    return 1;
  };
  var hi = 63;
  while hi >= 0 {
    if (n >> hi) & 1 == 1 {
      break;
    };
    hi = hi - 1;
  };
  var one: Int = 1;
  one << hi
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
