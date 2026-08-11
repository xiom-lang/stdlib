// XIOM - Bits: Endianness
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.bits.endianness

// Depends on: none

// ============================================================================
// Host detection, byte-order conversion, and fixed-width byte swaps. NOTE:
// current implementation lives in num.xi to_be/to_le/from_be/from_le +
// bits.xi byte_swap - move the functions here during the implementation phase.
// TODO(compiler): implement.
// ============================================================================

// fn is_big_endian() -> Bool - true if the host stores integers big-endian. TODO(compiler): implement.
// fn is_little_endian() -> Bool - true if the host stores integers little-endian. TODO(compiler): implement.
// fn to_be(v: Int, size: Int) -> Int - convert to big-endian byte order. TODO(compiler): implement.
// fn to_le(v: Int, size: Int) -> Int - convert to little-endian byte order. TODO(compiler): implement.
// fn from_be(v: Int, size: Int) -> Int - decode a big-endian value. TODO(compiler): implement.
// fn from_le(v: Int, size: Int) -> Int - decode a little-endian value. TODO(compiler): implement.
// fn native_to_be(v: Int) -> Int - convert a native value to big-endian order. TODO(compiler): implement.
// fn native_to_le(v: Int) -> Int - convert a native value to little-endian order. TODO(compiler): implement.
// fn be_to_native(v: Int) -> Int - convert a big-endian value to native order. TODO(compiler): implement.
// fn le_to_native(v: Int) -> Int - convert a little-endian value to native order. TODO(compiler): implement.
// fn swap_endian(v: Int) -> Int - unconditionally reverse the byte order. TODO(compiler): implement.
// fn bswap_16(v: Int) -> Int - byte-swap a 16-bit value. TODO(compiler): implement.
// fn bswap_32(v: Int) -> Int - byte-swap a 32-bit value. TODO(compiler): implement.
// fn bswap_64(v: Int) -> Int - byte-swap a 64-bit value. TODO(compiler): implement.
// fn bswap_128(v: Int) -> Int - byte-swap a 128-bit value. TODO(compiler): implement.
// fn bswap_256(v: Int) -> Int - byte-swap a 256-bit value. TODO(compiler): implement.
