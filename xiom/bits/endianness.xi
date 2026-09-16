// XIOM - Bits: Endianness
// Copyright (c) 2026 Eleftherios Notas and XIOM Foundation
// SPDX-License-Identifier: MIT OR Apache-2.0

module xiom.bits.endianness

// Depends on: none

// ============================================================================
// Host detection, byte-order conversion, and fixed-width byte swaps. The
// supported x86-64 targets are little-endian. All conversions are built from
// byte extraction and arithmetic reassembly (bitwise AND on operands with bit
// 31 set miscompiles -- see xiom.convert.base58 for the probe reference).
// ============================================================================

/// True if the host stores integers big-endian. The supported targets are
/// little-endian, so this returns false. Complexity: O(1).
pub fn is_big_endian() -> Bool {
  false
}

/// True if the host stores integers little-endian. The supported targets are
/// little-endian, so this returns true. Complexity: O(1).
pub fn is_little_endian() -> Bool {
  true
}

/// Reverses the byte order of the low `size` bytes of v, clearing the higher
/// bytes. size <= 1 returns v unchanged; size >= 8 swaps all 8 bytes.
/// Complexity: O(size).
fn _swap_low(v: Int, size: Int) -> Int {
  var result: Int = 0;
  var i: Int = 0;
  while i < size {
    var b = (v >> (i * 8)) & 0xFF;
    result = result + (b << ((size - 1 - i) * 8));
    i = i + 1;
  };
  result
}

/// Converts v to big-endian byte order for a `size`-byte value (the low
/// `size` bytes are reversed; higher bytes are cleared).
/// Complexity: O(size).
pub fn to_be(v: Int, size: Int) -> Int {
  if size <= 1 {
    return v;
  };
  if size >= 8 {
    return _swap_low(v, 8);
  };
  _swap_low(v, size)
}

/// Converts v to little-endian byte order for a `size`-byte value. On the
/// little-endian host this is the identity. Complexity: O(1).
pub fn to_le(v: Int, size: Int) -> Int {
  v
}

/// Decodes a `size`-byte big-endian value held in v into host order (the low
/// `size` bytes are reversed). Complexity: O(size).
pub fn from_be(v: Int, size: Int) -> Int {
  to_be(v, size)
}

/// Decodes a `size`-byte little-endian value held in v into host order (the
/// identity on the little-endian host). Complexity: O(1).
pub fn from_le(v: Int, size: Int) -> Int {
  v
}

/// Converts a native value to big-endian order (all 8 bytes reversed).
/// Complexity: O(8).
pub fn native_to_be(v: Int) -> Int {
  _swap_low(v, 8)
}

/// Converts a native value to little-endian order (the identity on this host).
/// Complexity: O(1).
pub fn native_to_le(v: Int) -> Int {
  v
}

/// Converts a big-endian value to native order (all 8 bytes reversed).
/// Complexity: O(8).
pub fn be_to_native(v: Int) -> Int {
  _swap_low(v, 8)
}

/// Converts a little-endian value to native order (the identity on this host).
/// Complexity: O(1).
pub fn le_to_native(v: Int) -> Int {
  v
}

/// Unconditionally reverses the byte order of v (all 8 bytes).
/// Complexity: O(8).
pub fn swap_endian(v: Int) -> Int {
  _swap_low(v, 8)
}

/// Byte-swaps a 16-bit value stored in the low 16 bits of v.
/// Complexity: O(2).
pub fn bswap_16(v: Int) -> Int {
  _swap_low(v, 2)
}

/// Byte-swaps a 32-bit value stored in the low 32 bits of v.
/// Complexity: O(4).
pub fn bswap_32(v: Int) -> Int {
  _swap_low(v, 4)
}

/// Byte-swaps a 64-bit value. Complexity: O(8).
pub fn bswap_64(v: Int) -> Int {
  _swap_low(v, 8)
}

// TODO(compiler): the platform Int is 64 bits wide, so a true 128-bit or
// 256-bit swap cannot be represented today. These functions behave exactly
// like bswap_64 (a full-width swap) until wider integer types land.

/// Byte-swaps a 128-bit value. FALLBACK (platform Int is 64-bit): identical
/// to bswap_64. Complexity: O(8).
pub fn bswap_128(v: Int) -> Int {
  _swap_low(v, 8)
}

/// Byte-swaps a 256-bit value. FALLBACK (platform Int is 64-bit): identical
/// to bswap_64. Complexity: O(8).
pub fn bswap_256(v: Int) -> Int {
  _swap_low(v, 8)
}
