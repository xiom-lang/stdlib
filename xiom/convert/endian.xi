// XIOM - Conversion: Endian
// Copyright (c) 2026 Eleftherios Notas
// Licensed under the MIT or Apache-2.0 license, at your option.

module xiom.convert.endian

// Depends on: none

// ============================================================================
// Big/little-endian byte conversions and host endianness detection. The
// byte-swap primitive delegates to the canonical xiom.bits.byte_swap64
// (different function name, so delegation is safe from the same-name
// miscompile). The host is always little-endian on the supported x86-64
// targets.
// ============================================================================

use xiom.bits;

/// Big-endian byte representation of an integer (exactly 8 bytes, MSB first).
/// Negative values render as their two's-complement pattern.
/// Complexity: O(1).
pub fn to_be_bytes(n: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 7;
  while i >= 0 {
    var b = (n >> (i * 8)) & 0xFF;
    result.push(b as UInt8);
    i = i - 1;
  };
  result
}

/// Little-endian byte representation of an integer (exactly 8 bytes, LSB
/// first). Complexity: O(1).
pub fn to_le_bytes(n: Int) -> Vec[UInt8] {
  var result = Vec[UInt8].new();
  var i = 0;
  while i < 8 {
    var b = (n >> (i * 8)) & 0xFF;
    result.push(b as UInt8);
    i = i + 1;
  };
  result
}

/// Integer read from big-endian bytes. Reads at most 8 bytes; returns 0 for
/// an empty vector or more than 8 bytes. Complexity: O(n).
pub fn from_be_bytes(bytes: &Vec[UInt8]) -> Int {
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  var result: Int = 0;
  var i: Int = 0;
  while i < len {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i + 1;
  };
  result
}

/// Integer read from little-endian bytes. Reads at most 8 bytes; returns 0
/// for an empty vector or more than 8 bytes. Complexity: O(n).
pub fn from_le_bytes(bytes: &Vec[UInt8]) -> Int {
  var len = bytes.len();
  if len == 0 || len > 8 {
    return 0;
  };
  var result: Int = 0;
  var i = len - 1;
  while i >= 0 {
    var b = bytes[i] as Int;
    b = b & 0xFF;
    result = result * 256 + b;
    i = i - 1;
  };
  result
}

/// Reverses the byte order of an integer (all 8 bytes). Delegates to the
/// canonical xiom.bits.byte_swap64. Complexity: O(1).
pub fn swap_bytes(n: Int) -> Int {
  bits.byte_swap64(n)
}

/// Reports the host byte order. The supported x86-64 targets are
/// little-endian, so this returns true. Complexity: O(1).
pub fn is_little_endian() -> Bool {
  true
}
