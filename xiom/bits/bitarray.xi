// XIOM - Bits: BitArray
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.
// Home: bits.xi - this sublib splits the dynamic bit-array domain.

module xiom.bits.bitarray

// Depends on: none

// ============================================================================
// Dynamic array of bits split from bits.xi: set/clear/test/flip, bitwise ops,
// serialization. TODO(compiler): implement.
// ============================================================================

// type BitArray - dynamic bit array; struct { bits: Vec[UInt8]; len: Int }.
// fn bit_array_new(n: Int) -> BitArray - bit array of length n, all bits cleared.
// fn bit_array_set(ba: BitArray, i: Int) - set bit i to 1.
// fn bit_array_clear(ba: BitArray, i: Int) - set bit i to 0.
// fn bit_array_test(ba: BitArray, i: Int) -> Bool - true iff bit i is set.
// fn bit_array_flip(ba: BitArray, i: Int) - toggle bit i.
// fn bit_array_count(ba: BitArray) -> Int - number of set bits.
// fn bit_array_len(ba: BitArray) -> Int - number of bits.
// fn bit_array_and(a: BitArray, b: BitArray) -> BitArray - bitwise AND.
// fn bit_array_or(a: BitArray, b: BitArray) -> BitArray - bitwise OR.
// fn bit_array_xor(a: BitArray, b: BitArray) -> BitArray - bitwise XOR.
// fn bit_array_not(ba: BitArray) -> BitArray - bitwise complement.
// fn bit_array_to_bytes(ba: BitArray) -> Vec[UInt8] - packed bytes, MSB-first per byte.
