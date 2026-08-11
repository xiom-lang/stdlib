// XIOM - Bits: Popcount
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: bits.xi + num.xi - this sublib splits the counting/shifting domain.

module xiom.bits.popcount

// Depends on: none

// ============================================================================
// Bit counting, leading/trailing zeros, parity, and rotation split from bits.xi
// and num.xi. TODO(compiler): implement.
// ============================================================================

// fn popcount(n: Int) -> Int - number of set bits in n.
// fn popcount64(n: UInt64) -> Int - number of set bits in a UInt64.
// fn count_leading_zeros(n: Int) -> Int - consecutive zero bits from the MSB; 64 for zero.
// fn count_trailing_zeros(n: Int) -> Int - consecutive zero bits from the LSB; 64 for zero.
// fn count_ones(n: Int) -> Int - number of set bits (alias of popcount).
// fn count_zeros(n: Int) -> Int - number of cleared bits.
// fn parity(n: Int) -> Int - 1 if popcount is odd, else 0.
// fn bit_length(n: Int) -> Int - number of bits needed to represent n (0 for zero).
// fn next_pow2(n: Int) -> Int - smallest power of two >= n.
// fn prev_pow2(n: Int) -> Int - largest power of two <= n.
// fn rotate_left(n: Int, k: Int) -> Int - circular left shift by k.
// fn rotate_right(n: Int, k: Int) -> Int - circular right shift by k.
